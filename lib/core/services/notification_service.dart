import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();

  factory NotificationService() => instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<String> _selectNotificationStream =
      StreamController<String>.broadcast();
  Stream<String> get selectNotificationStream =>
      _selectNotificationStream.stream;

  String? _initialPayload;
  String? get initialPayload => _initialPayload;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      final launchDetails = await _notificationsPlugin
          .getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        final payload = launchDetails?.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          _initialPayload = payload;
        }
      }

      _isInitialized = true;
      await requestPermissions();
    } catch (_) {
      // In headless unit test environments, native channels are uninitialized
    }
  }

  Future<void> requestPermissions() async {
    try {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    } catch (_) {}
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      _selectNotificationStream.add(payload);
    }
  }

  Future<void> showProgressNotification({
    required int id,
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
    String payload = '/transfers',
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'file_transfers_channel',
        'Ongoing File Transfers',
        channelDescription:
            'Notifications for ongoing background file uploads and downloads',
        importance: Importance.low,
        priority: Priority.low,
        onlyAlertOnce: true,
        showProgress: true,
        maxProgress: maxProgress,
        progress: progress,
        ongoing: true,
        autoCancel: false,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (_) {}
  }

  Future<void> showCompletedNotification({
    required int id,
    required String title,
    required String body,
    String payload = '/transfers',
  }) async {
    try {
      await _notificationsPlugin.cancel(id);

      final androidDetails = AndroidNotificationDetails(
        'file_transfers_completed_channel',
        'Completed Transfers',
        channelDescription:
            'Persistent notifications for completed background file transfers',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: false,
        autoCancel: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      );

      await _notificationsPlugin.show(
        id + 10000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (_) {}
  }

  Future<void> showFailedNotification({
    required int id,
    required String title,
    required String body,
    String payload = '/transfers',
  }) async {
    try {
      await _notificationsPlugin.cancel(id);

      final androidDetails = AndroidNotificationDetails(
        'file_transfers_failed_channel',
        'Failed Transfers',
        channelDescription:
            'Notifications for failed background file transfers',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: false,
        autoCancel: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      );

      await _notificationsPlugin.show(
        id + 20000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (_) {}
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
    } catch (_) {}
  }
}
