import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../supabase/supabase_service.dart';

/// Must be a top-level function — Android invokes this in a separate
/// background isolate when a push arrives while the app is killed/backgrounded.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No UI work here; just make sure Flutter engine/services required are ready
  // if we ever need to persist something locally. FCM shows the OS notification
  // automatically because our payload includes a `notification` block.
  Logger().i('Background bell received: ${message.messageId}');
}

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger();

  static const _bellChannel = AndroidNotificationChannel(
    'tickbell_bells',
    'Bell Alerts',
    description: 'Live trade bells and session alerts',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static const _generalChannel = AndroidNotificationChannel(
    'tickbell_general',
    'General',
    description: 'Announcements and app updates',
    importance: Importance.high,
  );

  Function(Map<String, dynamic> data)? onBellTapped;

  Future<void> initialize({required Function(Map<String, dynamic> data) onNotificationTap}) async {
    onBellTapped = onNotificationTap;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );
    _logger.i('Notification permission: ${settings.authorizationStatus}');

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          final data = jsonDecode(details.payload!) as Map<String, dynamic>;
          onBellTapped?.call(data);
        }
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_bellChannel);
    await androidPlugin?.createNotificationChannel(_generalChannel);

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onBellTapped?.call(message.data);
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      onBellTapped?.call(initialMessage.data);
    }

    await _registerDeviceToken();
    _messaging.onTokenRefresh.listen(_upsertToken);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final isBell = message.data['type'] == 'bell';
    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          isBell ? _bellChannel.id : _generalChannel.id,
          isBell ? _bellChannel.name : _generalChannel.name,
          channelDescription: isBell ? _bellChannel.description : _generalChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> _registerDeviceToken() async {
    final token = await _messaging.getToken();
    if (token != null) await _upsertToken(token);
  }

  Future<void> _upsertToken(String token) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;
    try {
      await SupabaseService.client.from('device_tokens').upsert({
        'user_id': userId,
        'fcm_token': token,
        'platform': 'android',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'fcm_token');
    } catch (e) {
      _logger.e('Failed to upsert FCM token: $e');
    }
  }

  Future<void> subscribeToTopic(String topic) => _messaging.subscribeToTopic(topic);
  Future<void> unsubscribeFromTopic(String topic) => _messaging.unsubscribeFromTopic(topic);

  Future<void> clearTokenOnSignOut() async {
    final token = await _messaging.getToken();
    if (token == null) return;
    try {
      await SupabaseService.client.from('device_tokens').delete().eq('fcm_token', token);
    } catch (_) {}
    await _messaging.deleteToken();
  }
}
