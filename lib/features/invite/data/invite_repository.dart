import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/services/supabase/supabase_service.dart';
import '../domain/invite_entities.dart';

abstract class InviteRepository {
  Future<Either<Failure, void>> redeemInvite(String code);
  Future<Either<Failure, Invite>> createInvite({String? note, Duration? validity});
  Future<Either<Failure, List<Invite>>> listInvites();
  Future<Either<Failure, void>> revokeInvite(String inviteId);
}

class InviteRepositoryImpl implements InviteRepository {
  @override
  Future<Either<Failure, void>> redeemInvite(String code) async {
    try {
      // `redeem_invite` is a SECURITY DEFINER Postgres function: it validates
      // the code atomically (status/expiry/one-time-use) and flips the
      // caller's profile.is_active to true — preventing race conditions where
      // two users could redeem the same code, which plain client-side
      // update() calls cannot guarantee.
      await SupabaseService.client.rpc('redeem_invite', params: {'invite_code': code.trim().toUpperCase()});
      return const Right(null);
    } on Object catch (e) {
      final message = e.toString();
      if (message.contains('invite_not_found')) {
        return const Left(InviteFailure('That invite code was not found.'));
      } else if (message.contains('invite_expired')) {
        return const Left(InviteFailure('This invite code has expired.'));
      } else if (message.contains('invite_already_used')) {
        return const Left(InviteFailure('This invite code has already been used.'));
      }
      return Left(InviteFailure('Could not redeem invite: $message'));
    }
  }

  @override
  Future<Either<Failure, Invite>> createInvite({String? note, Duration? validity}) async {
    try {
      final expiresAt = DateTime.now().add(validity ?? const Duration(days: 7));
      final row = await SupabaseService.client.rpc('create_invite', params: {
        'p_note': note,
        'p_expires_at': expiresAt.toIso8601String(),
      });
      return Right(Invite.fromJson(row as Map<String, dynamic>));
    } catch (e) {
      return Left(PermissionFailure('Could not create invite: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Invite>>> listInvites() async {
    try {
      final rows = await SupabaseService.client
          .from('invites')
          .select()
          .order('created_at', ascending: false);
      return Right((rows as List).map((r) => Invite.fromJson(r)).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> revokeInvite(String inviteId) async {
    try {
      await SupabaseService.client.from('invites').update({'status': 'revoked'}).eq('id', inviteId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
