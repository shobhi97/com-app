import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/bell_repository.dart';
import '../../domain/bell_entities.dart';

final bellRepositoryProvider = Provider<BellRepository>((ref) => BellRepositoryImpl());

final bellFeedProvider = StreamProvider.autoDispose<List<Bell>>((ref) {
  return ref.watch(bellRepositoryProvider).watchBells();
});

class SendBellController extends StateNotifier<AsyncValue<void>> {
  final BellRepository _repository;
  SendBellController(this._repository) : super(const AsyncData(null));

  Future<bool> send(Bell bell) async {
    state = const AsyncLoading();
    final result = await _repository.sendBell(bell);
    var ok = false;
    state = result.fold((f) => AsyncError(f, StackTrace.current), (_) {
      ok = true;
      return const AsyncData(null);
    });
    return ok;
  }
}

final sendBellControllerProvider = StateNotifierProvider<SendBellController, AsyncValue<void>>((ref) {
  return SendBellController(ref.watch(bellRepositoryProvider));
});
