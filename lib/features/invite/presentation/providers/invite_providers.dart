import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/invite_repository.dart';
import '../../domain/invite_entities.dart';

final inviteRepositoryProvider = Provider<InviteRepository>((ref) => InviteRepositoryImpl());

class InviteRedemptionController extends StateNotifier<AsyncValue<void>> {
  final InviteRepository _repository;
  InviteRedemptionController(this._repository) : super(const AsyncData(null));

  Future<bool> redeem(String code) async {
    state = const AsyncLoading();
    final result = await _repository.redeemInvite(code);
    var success = false;
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) {
        success = true;
        return const AsyncData(null);
      },
    );
    return success;
  }
}

final inviteRedemptionControllerProvider =
    StateNotifierProvider<InviteRedemptionController, AsyncValue<void>>((ref) {
  return InviteRedemptionController(ref.watch(inviteRepositoryProvider));
});

final adminInvitesListProvider = FutureProvider.autoDispose<List<Invite>>((ref) async {
  final repo = ref.watch(inviteRepositoryProvider);
  final result = await repo.listInvites();
  return result.fold((f) => throw f, (invites) => invites);
});
