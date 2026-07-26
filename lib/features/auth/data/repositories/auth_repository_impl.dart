import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/google_auth/google_auth_service.dart';
import '../../../../core/services/supabase/supabase_service.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_profile_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final GoogleAuthService googleAuthService;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({required this.googleAuthService, required this.networkInfo});

  @override
  Future<Either<Failure, UserProfile>> signInWithGoogle() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final response = await googleAuthService.signIn();
      final user = response.user;
      if (user == null) {
        return const Left(AuthFailure('Sign-in did not return a user.'));
      }

      // Ensure a profile row exists (idempotent). Actual invite gating happens
      // separately via InviteRepository before this profile becomes "active".
      final existing = await SupabaseService.client
          .from(AppConstants.tableProfiles)
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        final inserted = await SupabaseService.client
            .from(AppConstants.tableProfiles)
            .insert({
              'id': user.id,
              'email': user.email,
              'display_name': user.userMetadata?['full_name'] ?? user.email?.split('@').first,
              'avatar_url': user.userMetadata?['avatar_url'],
              'role': AppConstants.roleMember,
              'is_active': false, // becomes true only after invite redemption
            })
            .select()
            .single();
        return Right(UserProfileModel.fromJson(inserted));
      }

      return Right(UserProfileModel.fromJson(existing));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await googleAuthService.signOut();
      await SupabaseService.client.auth.signOut();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfile?>> getCurrentProfile() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return const Right(null);
    try {
      final row = await SupabaseService.client
          .from(AppConstants.tableProfiles)
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (row == null) return const Right(null);
      return Right(UserProfileModel.fromJson(row));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<UserProfile?> profileStream() {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return Stream.value(null);
    return SupabaseService.client
        .from(AppConstants.tableProfiles)
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) => rows.isEmpty ? null : UserProfileModel.fromJson(rows.first));
  }

  @override
  Future<Either<Failure, UserProfile>> completeProfileSetup({
    required String displayName,
    String? avatarPath,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return const Left(AuthFailure('Not signed in.'));
    try {
      String? avatarUrl;
      if (avatarPath != null) {
        final file = File(avatarPath);
        final storagePath = '$userId/avatar.jpg';
        await SupabaseService.client.storage
            .from(AppConstants.bucketAvatars)
            .upload(storagePath, file, fileOptions: const FileOptions(upsert: true));
        avatarUrl = SupabaseService.client.storage
            .from(AppConstants.bucketAvatars)
            .getPublicUrl(storagePath);
      }

      final updated = await SupabaseService.client
          .from(AppConstants.tableProfiles)
          .update({
            'display_name': displayName,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
          })
          .eq('id', userId)
          .select()
          .single();

      return Right(UserProfileModel.fromJson(updated));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> acceptLegalDocuments({
    required int privacyVersion,
    required int termsVersion,
    required int riskVersion,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return const Left(AuthFailure('Not signed in.'));
    try {
      await SupabaseService.client.from(AppConstants.tableProfiles).update({
        'privacy_policy_accepted_version': privacyVersion,
        'terms_accepted_version': termsVersion,
        'risk_disclosure_accepted_version': riskVersion,
      }).eq('id', userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      // Actual row + auth deletion is performed server-side via an Edge
      // Function using the service role key (never exposed client-side).
      await SupabaseService.client.functions.invoke('delete-account');
      await SupabaseService.client.auth.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
