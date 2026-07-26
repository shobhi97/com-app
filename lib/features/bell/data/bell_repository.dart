import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/services/supabase/supabase_service.dart';
import '../domain/bell_entities.dart';

abstract class BellRepository {
  Stream<List<Bell>> watchBells({int limit = 100});
  Future<Either<Failure, void>> sendBell(Bell bell);
  Future<Either<Failure, void>> markRead(String bellId);
  Future<Either<Failure, int>> unreadCount();
}

class BellRepositoryImpl implements BellRepository {
  @override
  Stream<List<Bell>> watchBells({int limit = 100}) {
    return SupabaseService.client
        .from('bells')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(limit)
        .map((rows) => rows.map((r) => Bell.fromJson(r)).toList());
  }

  @override
  Future<Either<Failure, void>> sendBell(Bell bell) async {
    try {
      final userId = SupabaseService.currentUser!.id;
      // Insert triggers a Postgres trigger (`notify_bell_subscribers`) that
      // calls a Supabase Edge Function to fan the push notification out to
      // every device_token via FCM HTTP v1 — keeps the client thin and the
      // server key off-device.
      await SupabaseService.client.from('bells').insert({
        ...bell.toInsertJson(),
        'created_by': userId,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to send bell: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markRead(String bellId) async {
    try {
      final userId = SupabaseService.currentUser!.id;
      await SupabaseService.client.from('bell_reads').upsert({
        'bell_id': bellId,
        'user_id': userId,
        'read_at': DateTime.now().toIso8601String(),
      }, onConflict: 'bell_id,user_id');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> unreadCount() async {
    try {
      final userId = SupabaseService.currentUser!.id;
      final result = await SupabaseService.client.rpc('unread_bell_count', params: {'p_user_id': userId});
      return Right(result as int? ?? 0);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
