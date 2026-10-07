import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/pet_schedule_service.dart';

class SettingsPage extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onProfileTap;

  const SettingsPage({
    super.key,
    required this.profile,
    required this.onProfileTap,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final NotificationService _notifications = NotificationService.instance;

  bool _notificationsEnabled = false;
  bool _notificationPermissionGranted = false;
  bool _notificationsLoading = true;
  bool _notificationsUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final results = await Future.wait([
        _notifications.hasPermission(),
        _notifications.remindersEnabled(),
      ]);
      if (!mounted) return;
      setState(() {
        _notificationPermissionGranted = results[0] as bool;
        _notificationsEnabled =
            (results[1] as bool) && _notificationPermissionGranted;
        _notificationsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _notificationsLoading = false);
    }
  }

  Future<void> _setNotificationsEnabled(bool enabled) async {
    if (_notificationsUpdating) return;
    setState(() => _notificationsUpdating = true);
    try {
      if (!enabled) {
        await _notifications.setRemindersEnabled(false);
        if (mounted) {
          setState(() {
            _notificationsEnabled = false;
            _notificationsUpdating = false;
          });
        }
        return;
      }

      final granted = await _notifications.requestPermission();
      if (!granted) {
        await _notifications.setRemindersEnabled(false);
        if (mounted) {
          setState(() {
            _notificationPermissionGranted = false;
            _notificationsEnabled = false;
            _notificationsUpdating = false;
          });
          _showNotificationMessage(
            'Allow notifications in your device or browser settings.',
          );
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
          _notificationPermissionGranted = true;
          _notificationsEnabled = true;
          _notificationsUpdating = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _notificationsUpdating = false);
        _showNotificationMessage('Could not update notifications: $error');
      }
    }
  }

  void _showNotificationMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 220),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppConstants.darkText,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Edit profile',
              onPressed: widget.onProfileTap,
              icon: const Icon(Icons.edit_rounded),
              color: AppConstants.darkText,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Center(
          child: Column(
            children: [
              _ProfileAvatar(
                name: widget.profile.name,
                imageUrl: widget.profile.avatarUrl,
              ),
              const SizedBox(height: 12),
              Text(
                widget.profile.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppConstants.darkText,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        const _SectionLabel('ACCOUNT INFORMATION'),
        const SizedBox(height: 10),
        _ProfileInfoCard(
          children: [
            _InfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Full name',
              value: widget.profile.name,
            ),
            const Divider(height: 1, indent: 58),
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: widget.profile.email.isEmpty
                  ? 'Not provided'
                  : widget.profile.email,
            ),
          ],
        ),
        const SizedBox(height: 26),
        const _SectionLabel('PREFERENCES'),
        const SizedBox(height: 10),
        _ProfileInfoCard(
          children: [
            Material(
              color: Colors.transparent,
              child: SwitchListTile.adaptive(
                value: _notificationsEnabled,
                onChanged: _notificationsLoading || _notificationsUpdating
                    ? null
                    : _setNotificationsEnabled,
                secondary: const Icon(
                  Icons.notifications_none_rounded,
                  size: 27,
                  color: Color(0xFF62564B),
                ),
                title: const Text(
                  'Notifications',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _notificationsLoading
                      ? 'Loading notification settings…'
                      : _notificationsEnabled
                          ? 'Alerts are enabled for your saved pet schedules.'
                          : 'Get notified when it is time for your pets’ care.',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        const _SectionLabel('ACCOUNT ACTIONS'),
        const SizedBox(height: 10),
        _ProfileInfoCard(
          children: [
            Material(
              color: Colors.transparent,
              child: ListTile(
                minTileHeight: 74,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 6,
                ),
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => _showLogoutDialog(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of Pawcare?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await AuthService.signOut();
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not log out: $error')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;

  const _ProfileAvatar({required this.name, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final trimmedName = name.trim();
    final initial = trimmedName.isEmpty ? 'P' : trimmedName[0].toUpperCase();

    return CircleAvatar(
      radius: 62,
      backgroundColor: AppConstants.lightPrimary,
      backgroundImage: imageUrl == null || imageUrl!.isEmpty
          ? null
          : NetworkImage(imageUrl!),
      child: imageUrl == null || imageUrl!.isEmpty
          ? Text(
              initial,
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w700,
                color: AppConstants.darkText,
              ),
            )
          : null,
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final List<Widget> children;

  const _ProfileInfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        minTileHeight: 76,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 5,
        ),
        leading: Icon(
          icon,
          color: const Color(0xFF62564B),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            color: AppConstants.darkText,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: Colors.black45,
      ),
    );
  }
}
