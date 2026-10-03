import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/pet_schedule.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

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

    // Web
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

    // ------------------------------------------------------------
    // Web
    // ------------------------------------------------------------

    final WebFlutterLocalNotificationsPlugin? web =
        _plugin.resolvePlatformSpecificImplementation<
            WebFlutterLocalNotificationsPlugin>();

    if (web != null) {
      final bool? result = await web.requestNotificationsPermission();

      if (result == true) {
        granted = true;
      }
    }

    return granted;
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
    await initialize();

    final DateTime scheduledDateTime = schedule.scheduledDateTime;

    final tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      scheduledDateTime.year,
      scheduledDateTime.month,
      scheduledDateTime.day,
      scheduledDateTime.hour,
      scheduledDateTime.minute,
    );

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // Don't schedule something that has already passed.
    if (!scheduledDate.isAfter(now)) {
      return;
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
    );

    try {
      await _plugin.zonedSchedule(
        id: _notificationId(schedule.id),
        title: '${schedule.petName}: ${schedule.title}',
        body: '${schedule.type} is scheduled for ${schedule.time}.',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
    await initialize();

    for (final PetSchedule schedule in schedules) {
      await scheduleReminder(schedule);
    }
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
