import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../services/notification_service.dart';
import '../../services/pet_schedule_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final NotificationService _notifications = NotificationService.instance;
  bool _enabled = false;
  bool _permissionGranted = false;
  bool _loading = true;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final results = await Future.wait([
        _notifications.hasPermission(),
        _notifications.remindersEnabled(),
      ]);
      if (!mounted) return;
      setState(() {
        _permissionGranted = results[0] as bool;
        _enabled = (results[1] as bool) && (results[0] as bool);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setEnabled(bool value) async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      if (!value) {
        await _notifications.setRemindersEnabled(false);
        if (mounted) {
          setState(() {
            _enabled = false;
            _updating = false;
          });
        }
        return;
      }

      // Must be invoked directly from the switch interaction on browsers.
      final granted = await _notifications.requestPermission();
      if (!granted) {
        await _notifications.setRemindersEnabled(false);
        if (mounted) {
          setState(() {
            _permissionGranted = false;
            _enabled = false;
            _updating = false;
          });
          _message('Allow notifications in your device or browser settings.');
        }
        return;
      }

      await _notifications.setRemindersEnabled(true);
      if (!kIsWeb) {
        final schedules = await PetScheduleService().getMySchedules();
        await _notifications.scheduleAll(schedules);
      }
      if (mounted) {
        setState(() {
          _permissionGranted = true;
          _enabled = true;
          _updating = false;
        });
        _message(kIsWeb
            ? 'Notifications are enabled in this browser.'
            : 'Reminders are enabled for your saved schedules.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _updating = false);
        _message('Could not update notifications: $error');
      }
    }
  }

  Future<void> _sendTest() async {
    try {
      await _notifications.showTestNotification();
      if (mounted) _message('A test notification was sent.');
    } catch (error) {
      if (mounted) _message('Could not send a test notification: $error');
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppConstants.backgroundColor,
        foregroundColor: AppConstants.darkText,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: SwitchListTile.adaptive(
                    value: _enabled,
                    onChanged: _updating ? null : _setEnabled,
                    secondary: const Icon(Icons.notifications_active_outlined),
                    title: const Text(
                      'Schedule reminders',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(_enabled
                        ? 'Alerts are enabled for your saved pet schedules.'
                        : 'Get notified when it is time for your pets’ care.'),
                  ),
                ),
                if (_updating) ...[
                  const SizedBox(height: 12),
                  const Center(child: CircularProgressIndicator()),
                ],
                const SizedBox(height: 16),
                if (_enabled && _permissionGranted)
                  OutlinedButton.icon(
                    onPressed: _sendTest,
                    icon: const Icon(Icons.notifications_outlined),
                    label: const Text('Send test notification'),
                  ),
                if (kIsWeb) ...[
                  const SizedBox(height: 16),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'This browser preview can show a test notification. '
                        'Automatic future schedule reminders are available in '
                        'the iOS and Android app.',
                      ),
                    ),
                  ),
                ] else if (!_permissionGranted) ...[
                  const SizedBox(height: 16),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Notifications are currently blocked. Turn them on '
                        'for Pawcare in your device settings, then return here '
                        'to enable schedule reminders.',
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
