import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/services/supabase/supabase_service.dart';
import '../domain/session_entities.dart';

abstract class SessionRepository {
  Stream<List<LiveSession>> watchUpcomingAndLive();
  Future<Either<Failure, void>> scheduleSession(LiveSession session);
  Future<Either<Failure, void>> updateStatus(String sessionId, SessionStatus status);
  Future<Either<Failure, void>> attachRecording(String sessionId, String recordingUrl);
}

class SessionRepositoryImpl implements SessionRepository {
  @override
  Stream<List<LiveSession>> watchUpcomingAndLive() {
    return SupabaseService.client
        .from('live_sessions')
        .stream(primaryKey: ['id'])
        .order('scheduled_start')
        .map((rows) => rows
            .map((r) => LiveSession.fromJson(r))
            .where((s) => s.status != SessionStatus.cancelled)
            .toList());
  }

  @override
  Future<Either<Failure, void>> scheduleSession(LiveSession session) async {
    try {
      final userId = SupabaseService.currentUser!.id;
      await SupabaseService.client.from('live_sessions').insert({
        ...session.toInsertJson(),
        'host_id': userId,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Could not schedule session: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateStatus(String sessionId, SessionStatus status) async {
    try {
      final patch = <String, dynamic>{'status': status.name};
      if (status == SessionStatus.live) patch['actual_start'] = DateTime.now().toIso8601String();
      if (status == SessionStatus.ended) patch['actual_end'] = DateTime.now().toIso8601String();
      await SupabaseService.client.from('live_sessions').update(patch).eq('id', sessionId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> attachRecording(String sessionId, String recordingUrl) async {
    try {
      await SupabaseService.client
          .from('live_sessions')
          .update({'recording_url': recordingUrl}).eq('id', sessionId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
