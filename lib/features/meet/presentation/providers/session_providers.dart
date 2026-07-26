import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/session_repository.dart';
import '../../domain/session_entities.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) => SessionRepositoryImpl());

final sessionsStreamProvider = StreamProvider.autoDispose<List<LiveSession>>((ref) {
  return ref.watch(sessionRepositoryProvider).watchUpcomingAndLive();
});
