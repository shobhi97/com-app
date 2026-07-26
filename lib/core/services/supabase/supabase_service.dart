import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

/// Thin, single-responsibility wrapper around Supabase initialization.
/// Never hardcode keys — always sourced from .env (gitignored) and, for
/// release builds, injected as --dart-define / Codemagic environment vars.
class SupabaseService {
  SupabaseService._();
  static final Logger _logger = Logger();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    final url = dotenv.env['SUPABASE_URL'] ?? const String.fromEnvironment('SUPABASE_URL');
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? const String.fromEnvironment('SUPABASE_ANON_KEY');

    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Missing SUPABASE_URL / SUPABASE_ANON_KEY. Provide them via .env locally '
        'or --dart-define / Codemagic secure environment variables in CI.',
      );
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authFlowType: AuthFlowType.pkce,
      debug: false,
    );
    _logger.i('Supabase initialized');
  }

  static User? get currentUser => client.auth.currentUser;
  static Session? get currentSession => client.auth.currentSession;
  static bool get isAuthenticated => currentSession != null;

  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}
