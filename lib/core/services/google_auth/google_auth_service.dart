import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../errors/failures.dart';
import '../supabase/supabase_service.dart';

/// Bridges native Google Sign-In with Supabase's `signInWithIdToken`, so
/// Supabase remains the single source of truth for sessions/roles/RLS while
/// Google handles the actual OAuth consent screen.
///
/// Requires:
///  - A Web OAuth client ID (serverClientId) registered in Google Cloud Console,
///    added under Supabase Auth > Providers > Google as the Client ID.
///  - The Android OAuth client's SHA-1 fingerprint registered in the same
///    Google Cloud project (release + debug keystores).
class GoogleAuthService {
  final GoogleSignIn _googleSignIn;

  GoogleAuthService({required String serverClientId})
      : _googleSignIn = GoogleSignIn(
          scopes: const ['email', 'profile'],
          serverClientId: serverClientId,
        );

  Future<AuthResponse> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw AuthException('Sign-in cancelled.', code: 'cancelled');
      }

      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw AuthException('Google did not return an identity token.', code: 'no_id_token');
      }

      final response = await SupabaseService.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return response;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Google sign-in failed: $e', code: 'google_sign_in_error');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<void> disconnect() async {
    await _googleSignIn.disconnect();
  }
}
