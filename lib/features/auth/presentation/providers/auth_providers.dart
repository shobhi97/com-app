import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/google_auth/google_auth_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

/// Replace with your Web OAuth client ID from Google Cloud Console.
/// Injected via --dart-define at build time so it never lives in source control.
const _googleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue: '',
);

final networkInfoProvider = Provider<NetworkInfo>((ref) => NetworkInfoImpl(Connectivity()));

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService(serverClientId: _googleServerClientId);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    googleAuthService: ref.watch(googleAuthServiceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

/// Live-streamed current profile — reflects role changes, activation status,
/// and legal-acceptance state in real time (e.g. an admin approving an invite).
final currentProfileStreamProvider = StreamProvider<UserProfile?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.profileStream();
});

enum AuthStatus { unknown, signedOut, needsInvite, needsProfileSetup, needsLegalAcceptance, ready }

final authStatusProvider = Provider<AuthStatus>((ref) {
  final profileAsync = ref.watch(currentProfileStreamProvider);
  return profileAsync.when(
    data: (profile) {
      if (profile == null) return AuthStatus.signedOut;
      if (!profile.isActive) return AuthStatus.needsInvite;
      if (profile.displayName.isEmpty) return AuthStatus.needsProfileSetup;
      if (!profile.hasAcceptedAllLegal(privacyVersion: 1, termsVersion: 1, riskVersion: 1)) {
        return AuthStatus.needsLegalAcceptance;
      }
      return AuthStatus.ready;
    },
    loading: () => AuthStatus.unknown,
    error: (_, __) => AuthStatus.signedOut,
  );
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;
  AuthController(this._repository) : super(const AsyncData(null));

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    final result = await _repository.signInWithGoogle();
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    final result = await _repository.signOut();
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
