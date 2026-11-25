import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'api_client.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.notification?.title}');
}

class FirebaseNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static Future<void> initialize() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await _setupFCM();
      await _setupLocalNotifications();
    }
  }

  static Future<void> _setupFCM() async {
    String? token = await _fcm.getToken();
    if (token != null) {
      await _sendTokenToBackend(token);
    }

    _fcm.onTokenRefresh.listen(_sendTokenToBackend);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(settings);

    const channel = AndroidNotificationChannel(
      'pms_notifications',
      'PMS Notifications',
      description: 'Property Management System notifications',
      importance: Importance.high,
    );

    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> _sendTokenToBackend(String token) async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String? deviceId;
      String platform;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        platform = 'android';
      } else {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor;
        platform = 'ios';
      }

      await ApiClient.put('/user/fcm-token', {
        'fcm_token': token,
        'device_id': deviceId,
        'device_platform': platform,
      });
    } catch (e) {
      print('Error sending FCM token: $e');
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'pms_notifications',
          'PMS Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
