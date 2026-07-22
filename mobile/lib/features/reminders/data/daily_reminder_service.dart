import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

class DailyReminderSettings {
  const DailyReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  const DailyReminderSettings.defaults()
    : enabled = false,
      hour = 19,
      minute = 0;

  final bool enabled;
  final int hour;
  final int minute;
}

class DailyReminderService {
  DailyReminderService({FlutterLocalNotificationsPlugin? notifications})
    : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  static const _notificationId = 2401;
  static const _enabledKey = 'daily_reminder_enabled';
  static const _hourKey = 'daily_reminder_hour';
  static const _minuteKey = 'daily_reminder_minute';

  final FlutterLocalNotificationsPlugin _notifications;
  bool _initialized = false;

  Future<DailyReminderSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    return DailyReminderSettings(
      enabled: preferences.getBool(_enabledKey) ?? false,
      hour: preferences.getInt(_hourKey) ?? 19,
      minute: preferences.getInt(_minuteKey) ?? 0,
    );
  }

  Future<bool> enable({required int hour, required int minute}) async {
    await _initialize();
    if (!await _requestPermission()) return false;

    await _notifications.cancel(_notificationId);
    final now = timezone.TZDateTime.now(timezone.local);
    var scheduled = timezone.TZDateTime(
      timezone.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _notifications.zonedSchedule(
      _notificationId,
      'How is your pet today?',
      'Capture one small moment for their lifetime story.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_memory',
          'Daily memory',
          channelDescription: 'A gentle daily reminder to photograph your pet.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(threadIdentifier: 'daily-memory'),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/camera',
    );
    await _save(enabled: true, hour: hour, minute: minute);
    return true;
  }

  Future<void> disable({required int hour, required int minute}) async {
    await _initialize();
    await _notifications.cancel(_notificationId);
    await _save(enabled: false, hour: hour, minute: minute);
  }

  Future<void> _initialize() async {
    if (_initialized || kIsWeb) return;
    timezone_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    timezone.setLocalLocation(timezone.getLocation(localTimezone.identifier));
    await _notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  Future<bool> _requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _notifications
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    return false;
  }

  Future<void> _save({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setBool(_enabledKey, enabled),
      preferences.setInt(_hourKey, hour),
      preferences.setInt(_minuteKey, minute),
    ]);
  }
}
