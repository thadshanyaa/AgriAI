import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localization/app_language.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

abstract final class NotificationService {
  static const preferenceKey = 'notifications_enabled';
  static const topic = 'agriai_all';
  static const channelId = 'agriai_farm_alerts';
  static const channelName = 'AgriAI Farm Alerts';
  static const channelDescription =
      'Weather, crop disease, market and farm reminders';

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
    );
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_launcher'),
    );
    await _localNotifications.initialize(settings: initializationSettings);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen(_showForegroundMessage);
    FirebaseMessaging.instance.onTokenRefresh.listen(_saveToken);
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) unawaited(_registerCurrentToken());
    });

    final preferences = await SharedPreferences.getInstance();
    final enabled = preferences.getBool(preferenceKey) ?? false;
    if (enabled) await setEnabled(true);
    _initialized = true;
  }

  static Future<bool> setEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    if (!enabled) {
      await preferences.setBool(preferenceKey, false);
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      return false;
    }

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final allowed =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    await preferences.setBool(preferenceKey, allowed);
    if (!allowed) return false;

    await FirebaseMessaging.instance.subscribeToTopic(topic);
    await _registerCurrentToken();
    return true;
  }

  static Future<void> showTestNotification() async {
    await initialize();
    final enabled = await setEnabled(true);
    if (!enabled) {
      throw StateError('Notification permission is not enabled.');
    }
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_launcher',
      ),
    );
    await _localNotifications.show(
      id: 160013,
      title: 'AgriAI',
      body: tr('Free push notification setup is working.'),
      notificationDetails: details,
    );
  }

  static Future<void> _registerCurrentToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _saveToken(token);
  }

  static Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'notificationsUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Push reception still works even if token storage is temporarily denied.
    }
  }

  static Future<void> _showForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();
    if (title == null && body == null) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_launcher',
      ),
    );
    await _localNotifications.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: title ?? 'AgriAI',
      body: body ?? '',
      notificationDetails: details,
      payload: message.data['route']?.toString(),
    );
  }
}
