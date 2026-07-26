import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'core/services/supabase/supabase_service.dart';
import 'core/services/fcm/fcm_service.dart';

final Logger _logger = Logger();
final FcmService fcmService = FcmService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env is optional in CI (Codemagic) where secrets are injected via
  // --dart-define instead; don't crash the app if the file is absent.
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    _logger.w('.env not found, relying on --dart-define values: $e');
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SupabaseService.initialize();

  await fcmService.initialize(
    onNotificationTap: (data) {
      // Deep-link handling: bells route into the Bells tab, session
      // notifications could push to the Sessions tab. Kept intentionally
      // simple — extend with a proper deep-link router as the app grows.
      _logger.i('Notification tapped with payload: $data');
    },
  );

  runApp(const ProviderScope(child: TickBellApp));
}
