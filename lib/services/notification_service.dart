import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Call NotificationService.init() once at app startup.
/// Use NotificationService.showNow(...) to show a banner immediately.
/// Use NotificationService.schedule(...) to schedule when app isn't open.
/// Use NotificationService.showUrgentFullScreen(...) for Android full-screen alerts.
class NotificationService {
  static const MethodChannel _platform =
      MethodChannel('com.mycompany.redivo/utils');

  static Future<void> wakeUpScreen() async {
    try {
      if (Platform.isAndroid) {
        await _platform.invokeMethod('wakeUpScreen');
        debugPrint('✅ Native wakeUpScreen called');
      }
    } catch (e) {
      debugPrint('❌ Error calling wakeUpScreen: $e');
    }
  }

  static const String _channelIdHigh = 'high_alerts';
  static const String _channelNameHigh = 'High Alerts';
  static const String _channelDescHigh =
      'Heads-up alerts and urgent notifications';

  static const String _channelIdDispatch = 'dispatch_status_active_v2';
  static const String _channelNameDispatch = 'Dispatch Status Updates (Urgent)';
  static const String _channelDescDispatch =
      'Notifications when dispatch status changes to active';

  // Lightweight init for background isolates
  static Future<void> initBackground() async {
    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    final iosInit = const DarwinInitializationSettings(
      requestAlertPermission: false,
      requestSoundPermission: false,
      requestBadgePermission: false,
    );
    final initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  static Future<void> init() async {
    // Timezone init for scheduling
    tzdata.initializeTimeZones();
    // You can set a specific timezone if needed:
    // tz.setLocalLocation(tz.getLocation('Europe/Brussels'));

    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');

    final iosInit = const DarwinInitializationSettings(
      requestAlertPermission: false,
      requestSoundPermission: false,
      requestBadgePermission: false,
    );

    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle taps on notification
        // response.payload can be used for routing
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    await _requestPermissions();

    // Android channel creation
    if (Platform.isAndroid) {
      // High alerts channel
      const AndroidNotificationChannel channelHigh = AndroidNotificationChannel(
        _channelIdHigh,
        _channelNameHigh,
        description: _channelDescHigh,
        importance: Importance.high,
        enableVibration: true,
      );

      // Dispatch status channel - MAX importance for full-screen intent
      const AndroidNotificationChannel channelDispatch =
          AndroidNotificationChannel(
        _channelIdDispatch,
        _channelNameDispatch,
        description: _channelDescDispatch,
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
      );

      final androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(channelHigh);
      await androidPlugin?.createNotificationChannel(channelDispatch);
    }
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      final iosPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    if (Platform.isAndroid) {
      // Android 13+ runtime permission
      final androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }
  }

  /// Show a normal heads-up notification NOW (banner + notification shade).
  static Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelIdHigh,
        _channelNameHigh,
        channelDescription: _channelDescHigh,
        importance: Importance.high, // heads-up
        priority: Priority.high, // heads-up
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public, // show on lockscreen
        icon: '@mipmap/launcher_icon',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Schedule a notification for a future time (works when app is closed).
  /// NOTE: For Android 12+ exact timing can be restricted unless user allows exact alarms.
  static Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  }) async {
    final scheduled = tz.TZDateTime.from(when, tz.local);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelIdHigh,
        _channelNameHigh,
        channelDescription: _channelDescHigh,
        importance: Importance.high,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        icon: '@mipmap/launcher_icon',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  /// Show dispatch status active notification - URGENT FULL-SCREEN
  /// Shows even when phone is locked or app is closed.
  static Future<void> showDispatchStatusActive({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint(
        '🔔 NotificationService: Showing dispatch status active notification');

    // Force screen wake via native channel
    await wakeUpScreen();

    final androidDetails = AndroidNotificationDetails(
      _channelIdDispatch,
      _channelNameDispatch,
      channelDescription: _channelDescDispatch,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true, // KEY: Shows full-screen intent on Android
      enableVibration: true,
      playSound: true,
      showWhen: true,
      autoCancel: true,
      icon: '@mipmap/launcher_icon',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload ?? 'dispatch_status_active',
    );

    debugPrint('✅ Dispatch status notification shown');
  }

  /// ANDROID ONLY:
  /// Urgent full-screen notification (tries to pop a full-screen UI and wake screen).
  /// Use sparingly (alarm/call-like urgent alerts).
  static Future<void> showUrgentFullScreen({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!Platform.isAndroid) {
      // iOS cannot do reliable full-screen wake behavior like Android.
      return showNow(id: id, title: title, body: body, payload: payload);
    }

    final androidDetails = AndroidNotificationDetails(
      _channelIdDispatch,
      _channelNameDispatch,
      channelDescription: _channelDescDispatch,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/launcher_icon',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload ?? 'urgent',
    );
  }

  static Future<void> cancel(int id) =>
      flutterLocalNotificationsPlugin.cancel(id);

  static Future<void> cancelAll() =>
      flutterLocalNotificationsPlugin.cancelAll();
}
