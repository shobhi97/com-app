import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_profile.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserProfile>> signInWithGoogle();
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, UserProfile?>> getCurrentProfile();
  Stream<UserProfile?> profileStream();
  Future<Either<Failure, UserProfile>> completeProfileSetup({
    required String displayName,
    String? avatarPath,
  });
  Future<Either<Failure, void>> acceptLegalDocuments({
    required int privacyVersion,
    required int termsVersion,
    required int riskVersion,
  });
  Future<Either<Failure, void>> deleteAccount();
}
