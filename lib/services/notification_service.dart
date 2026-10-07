import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/pet_schedule.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  static const String _enabledPreferenceKey =
      'pet_schedule_notifications_enabled';

  bool get supportsScheduledNotifications => !kIsWeb;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    // Initialize timezone database.
    tz.initializeTimeZones();

    // University of Mindanao / Philippines timezone.
    tz.setLocalLocation(
      tz.getLocation('Asia/Manila'),
    );

    // Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS / macOS
    final DarwinInitializationSettings darwinSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const WebInitializationSettings webSettings = WebInitializationSettings();

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      web: webSettings,
    );

    await _plugin.initialize(
      settings: settings,
    );

    _initialized = true;
  }

  // ============================================================
  // REQUEST PERMISSION
  // ============================================================

  Future<bool> requestPermission() async {
    await initialize();

    if (kIsWeb) {
      final web = _plugin.resolvePlatformSpecificImplementation<
          WebFlutterLocalNotificationsPlugin>();
      return await web?.requestNotificationsPermission() ?? false;
    }

    bool granted = false;

    // ------------------------------------------------------------
    // Android
    // ------------------------------------------------------------

    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final bool? result = await android.requestNotificationsPermission();

      if (result == true) {
        granted = true;
      }
    }

    // ------------------------------------------------------------
    // iOS
    // ------------------------------------------------------------

    final IOSFlutterLocalNotificationsPlugin? ios =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (ios != null) {
      final bool? result = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (result == true) {
        granted = true;
      }
    }

    // ------------------------------------------------------------
    // macOS
    // ------------------------------------------------------------

    final MacOSFlutterLocalNotificationsPlugin? macos =
        _plugin.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();

    if (macos != null) {
      final bool? result = await macos.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (result == true) {
        granted = true;
      }
    }

    return granted;
  }

  Future<bool> hasPermission() async {
    await initialize();

    if (kIsWeb) {
      final web = _plugin.resolvePlatformSpecificImplementation<
          WebFlutterLocalNotificationsPlugin>();
      return web?.permissionStatus == WebNotificationPermission.granted;
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return (await ios.checkPermissions())?.isEnabled ?? false;
    }

    final macos = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    if (macos != null) {
      return (await macos.checkPermissions())?.isEnabled ?? false;
    }

    return false;
  }

  Future<bool> remindersEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_enabledPreferenceKey) ?? false;
  }

  Future<void> setRemindersEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledPreferenceKey, enabled);
    if (!enabled) {
      await cancelAll();
    }
  }

  Future<void> openNotificationSettings() async {
    await initialize();
    await _plugin.openAppNotificationSettings();
  }

  // ============================================================
  // SHOW IMMEDIATE NOTIFICATION
  // ============================================================

  Future<void> showNow(PetSchedule schedule) async {
    await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'pet_schedule_channel',
      'Pet Schedule Reminders',
      channelDescription: 'Notifications for pet care schedules.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      web: WebNotificationDetails(),
    );

    try {
      await _plugin.show(
        id: _notificationId(schedule.id),
        title: '${schedule.petName}: ${schedule.title}',
        body: '${schedule.type} is scheduled for ${schedule.time}.',
        notificationDetails: notificationDetails,
        payload: schedule.id,
      );
    } catch (_) {
      // Some platforms may not support the same notification
      // implementation. The in-app schedule reminder remains
      // available as the fallback.
    }
  }

  // ============================================================
  // SCHEDULE FUTURE NOTIFICATION
  // ============================================================

  Future<void> scheduleReminder(
    PetSchedule schedule,
  ) async {
    if (kIsWeb || !await remindersEnabled() || !await hasPermission()) {
      return;
    }

    await initialize();

    final DateTime scheduledDateTime = schedule.scheduledDateTime;

    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      scheduledDateTime.year,
      scheduledDateTime.month,
      scheduledDateTime.day,
      scheduledDateTime.hour,
      scheduledDateTime.minute,
    );

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    final DateTimeComponents? repeatComponents = switch (schedule.repeat) {
      'Everyday' => DateTimeComponents.time,
      'Every week' => DateTimeComponents.dayOfWeekAndTime,
      'Every month' => DateTimeComponents.dayOfMonthAndTime,
      _ => null,
    };

    if (!scheduledDate.isAfter(now)) {
      if (repeatComponents == null) return;

      // Start the repeating alert at its next valid occurrence. Monthly
      // reminders on dates such as the 31st simply skip shorter months.
      for (var offset = 0; offset <= 370; offset++) {
        final candidateDate = DateTime(
          now.year,
          now.month,
          now.day + offset,
          scheduledDateTime.hour,
          scheduledDateTime.minute,
        );
        final matches = switch (schedule.repeat) {
          'Everyday' => true,
          'Every week' => candidateDate.weekday == scheduledDateTime.weekday,
          'Every month' => candidateDate.day == scheduledDateTime.day,
          _ => false,
        };
        if (matches) {
          final candidateScheduledDate = tz.TZDateTime(
            tz.local,
            candidateDate.year,
            candidateDate.month,
            candidateDate.day,
            candidateDate.hour,
            candidateDate.minute,
          );
          if (candidateScheduledDate.isAfter(now)) {
            scheduledDate = candidateScheduledDate;
            break;
          }
        }
      }
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'pet_schedule_channel',
      'Pet Schedule Reminders',
      channelDescription: 'Notifications for pet care schedules.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      web: WebNotificationDetails(),
    );

    try {
      await _plugin.zonedSchedule(
        id: _notificationId(schedule.id),
        title: '${schedule.petName}: ${schedule.title}',
        body: '${schedule.type} is scheduled for ${schedule.time}.',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: repeatComponents,
        payload: schedule.id,
      );
    } catch (_) {
      // Browsers do not support future scheduled notifications.
      //
      // The Schedule page and Home dashboard will still show
      // today's schedules inside the app.
    }
  }

  // ============================================================
  // SCHEDULE MULTIPLE REMINDERS
  // ============================================================

  Future<void> scheduleAll(
    List<PetSchedule> schedules,
  ) async {
    if (kIsWeb || !await remindersEnabled() || !await hasPermission()) {
      return;
    }

    await initialize();

    for (final PetSchedule schedule in schedules) {
      await scheduleReminder(schedule);
    }
  }

  Future<void> showTestNotification() async {
    await initialize();
    if (!await hasPermission()) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'pet_schedule_channel',
        'Pet Schedule Reminders',
        channelDescription: 'Notifications for pet care schedules.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      web: WebNotificationDetails(),
    );

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(0x7fffffff),
      title: 'Pawcare notifications are on',
      body: 'You’ll receive reminders for your pet schedules.',
      notificationDetails: details,
    );
  }

  // ============================================================
  // CANCEL
  // ============================================================

  Future<void> cancel(
    PetSchedule schedule,
  ) async {
    await initialize();

    await _plugin.cancel(
      id: _notificationId(schedule.id),
    );
  }

  // ============================================================
  // CANCEL ALL
  // ============================================================

  Future<void> cancelAll() async {
    await initialize();

    await _plugin.cancelAll();
  }

  // ============================================================
  // CREATE A STABLE INTEGER NOTIFICATION ID
  // ============================================================

  int _notificationId(String value) {
    var hash = 0;

    for (final int unit in value.codeUnits) {
      hash = ((hash << 5) - hash) + unit;
      hash &= 0x7fffffff;
    }

    // Never return zero.
    if (hash == 0) {
      return 1;
    }

    return hash;
  }
}
