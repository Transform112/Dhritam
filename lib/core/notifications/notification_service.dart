import 'dart:developer';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    // 1. Android Setup
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // 2. iOS Setup
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // FIXED: Passed as a named parameter 'settings:'
    await _notificationsPlugin.initialize(
      settings: initSettings,
    );

    // Request Android 13+ permissions
    _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

    _isInitialized = true;
    log("Notification Service Initialized");
  }

  // 3. The Stress Alert Trigger
  static Future<void> showStressAlert({required String title, required String body}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'dhritam_stress_alerts', // Channel ID
      'Stress & Recovery Alerts', // Channel Name
      channelDescription: 'High priority notifications when sustained stress is detected.',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    // FIXED: Passed as named parameters 'id:', 'title:', 'body:', and 'notificationDetails:'
    await _notificationsPlugin.show(
      id: 0, 
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }
}