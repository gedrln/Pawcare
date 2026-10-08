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
  static const List<int> _reminderLeadTimes = [20, 5];
  static const String _enabledPreferenceKey =
      'pet_schedule_notifications_enabled';
  static const String _todaySummaryDateKeyPrefix =
      'pet_schedule_today_summary_date_';

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
      for (final key in preferences.getKeys().where(
        (key) => key.startsWith(_todaySummaryDateKeyPrefix),
      )) {
        await preferences.remove(key);
      }
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

  /// Shows a generic auth notification after Supabase sends an email code.
  /// Never include the code itself: notifications can be visible on a lock
  /// screen or to anyone with access to the device.
  Future<void> showVerificationCodeSent({required bool passwordReset}) async {
    try {
      await initialize();
      if (!await hasPermission() && !await requestPermission()) return;

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'pawcare_auth_channel',
          'Account Security',
          channelDescription: 'Account verification and recovery alerts.',
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
        id: passwordReset ? 710002 : 710001,
        title: passwordReset ? 'Password reset code sent' : 'Verify your email',
        body: passwordReset
            ? 'Check your email for the password reset code.'
            : 'Check your email for the account verification code.',
        notificationDetails: details,
      );
    } catch (_) {
      // Notification delivery must not interrupt authentication.
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
    final DateTimeComponents? repeatComponents = switch (schedule.repeat) {
      'Everyday' => DateTimeComponents.time,
      'Every week' => DateTimeComponents.dayOfWeekAndTime,
      'Every month' => DateTimeComponents.dayOfMonthAndTime,
      _ => null,
    };

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

    // Clear reminders created by the previous single-reminder implementation.
    await _plugin.cancel(id: _notificationId(schedule.id));

    final now = tz.TZDateTime.now(tz.local);
    for (final leadMinutes in _reminderLeadTimes) {
      final reminderDate = _nextReminderDate(
        schedule,
        leadMinutes: leadMinutes,
        now: now,
        repeatComponents: repeatComponents,
      );
      final notificationId = _notificationId('${schedule.id}:$leadMinutes');
      await _plugin.cancel(id: notificationId);
      if (reminderDate == null) continue;

      try {
        await _plugin.zonedSchedule(
          id: notificationId,
          title: '${schedule.petName}: ${schedule.title} in $leadMinutes minutes',
          body: '${schedule.type} is scheduled for ${schedule.time}.',
          scheduledDate: reminderDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: repeatComponents,
          payload: schedule.id,
        );
      } catch (_) {
        // Browsers do not support future scheduled notifications.
        // The Schedule page and Home dashboard still show the schedule.
      }
    }
  }

  tz.TZDateTime? _nextReminderDate(
    PetSchedule schedule, {
    required int leadMinutes,
    required tz.TZDateTime now,
    required DateTimeComponents? repeatComponents,
  }) {
    final eventDateTime = schedule.scheduledDateTime;
    final reminderDateTime =
        eventDateTime.subtract(Duration(minutes: leadMinutes));
    final initialReminder = tz.TZDateTime(
      tz.local,
      reminderDateTime.year,
      reminderDateTime.month,
      reminderDateTime.day,
      reminderDateTime.hour,
      reminderDateTime.minute,
    );

    if (initialReminder.isAfter(now)) return initialReminder;
    if (repeatComponents == null) return null;

    // Find the next repeating event whose reminder time has not passed.
    for (var offset = 0; offset <= 370; offset++) {
      final candidateEvent = DateTime(
        now.year,
        now.month,
        now.day + offset,
        eventDateTime.hour,
        eventDateTime.minute,
      );
      final matches = switch (schedule.repeat) {
        'Everyday' => true,
        'Every week' => candidateEvent.weekday == eventDateTime.weekday,
        'Every month' => candidateEvent.day == eventDateTime.day,
        _ => false,
      };
      if (!matches) continue;

      final candidateReminder =
          candidateEvent.subtract(Duration(minutes: leadMinutes));
      final reminder = tz.TZDateTime(
        tz.local,
        candidateReminder.year,
        candidateReminder.month,
        candidateReminder.day,
        candidateReminder.hour,
        candidateReminder.minute,
      );
      if (reminder.isAfter(now)) return reminder;
    }

    return null;
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

    await scheduleTodaySummary(schedules);
  }

  /// Sends one daily summary for today's unfinished pet care schedules.
  /// The reminder is set for 8:00 AM, or shortly after now if the owner
  /// opens the app later in the day.
  Future<void> scheduleTodaySummary(List<PetSchedule> schedules) async {
    if (kIsWeb || !await remindersEnabled() || !await hasPermission()) {
      return;
    }

    await initialize();

    if (schedules.isEmpty) return;

    final now = tz.TZDateTime.now(tz.local);
    final today = DateTime(now.year, now.month, now.day);
    final dateKey = _dateKey(today);
    final preferences = await SharedPreferences.getInstance();
    final preferenceKey =
        '$_todaySummaryDateKeyPrefix${schedules.first.ownerId}';

    // Avoid issuing another summary every time the Schedule page is opened.
    if (preferences.getString(preferenceKey) == dateKey) return;

    final todaysSchedules = schedules.where((schedule) {
      return !schedule.isDone && _occursOn(schedule, today);
    }).toList()
      ..sort((a, b) {
        final aMinutes = a.hour * 60 + a.minute;
        final bMinutes = b.hour * 60 + b.minute;
        return aMinutes.compareTo(bMinutes);
      });

    if (todaysSchedules.isEmpty) return;

    final scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      8,
    );
    final notificationDate = scheduledDate.isAfter(now)
        ? scheduledDate
        : now.add(const Duration(minutes: 1));

    final lines = todaysSchedules
        .take(3)
        .map(
          (schedule) =>
              '${schedule.petName}: ${schedule.title} at ${schedule.time}',
        )
        .join(' · ');
    final moreCount = todaysSchedules.length - 3;
    final body = moreCount > 0 ? '$lines · and $moreCount more' : lines;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'pet_schedule_channel',
        'Pet Schedule Reminders',
        channelDescription: 'Notifications for pet care schedules.',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
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
    );

    try {
      await _plugin.zonedSchedule(
        id: _todaySummaryNotificationId(today),
        title: 'You have ${todaysSchedules.length} pet schedule'
            '${todaysSchedules.length == 1 ? '' : 's'} today',
        body: body,
        scheduledDate: notificationDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      await preferences.setString(preferenceKey, dateKey);
    } catch (_) {
      // Individual schedule reminders and the in-app schedule list remain
      // available if this platform cannot schedule the summary.
    }
  }

  bool _occursOn(PetSchedule schedule, DateTime day) {
    final start = DateTime(
      schedule.date.year,
      schedule.date.month,
      schedule.date.day,
    );
    if (day.isBefore(start)) return false;
    if (day.year == start.year &&
        day.month == start.month &&
        day.day == start.day) {
      return true;
    }
    return switch (schedule.repeat) {
      'Everyday' => true,
      'Every week' => day.weekday == start.weekday,
      'Every month' => day.day == start.day,
      _ => false,
    };
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  int _todaySummaryNotificationId(DateTime date) {
    // Use a date-derived ID so rescheduling replaces the same day's summary.
    final daysSinceEpoch = DateTime.utc(date.year, date.month, date.day)
            .millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    return 0x60000000 + daysSinceEpoch;
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
    for (final leadMinutes in _reminderLeadTimes) {
      await _plugin.cancel(
        id: _notificationId('${schedule.id}:$leadMinutes'),
      );
    }
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
