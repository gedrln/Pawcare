import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import 'accessibility_page.dart';

class SettingsPage extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onProfileTap;

  const SettingsPage({
    super.key,
    required this.profile,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        110,
      ),
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppConstants.darkText,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Manage your profile and app preferences.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.black45,
          ),
        ),
        const SizedBox(height: 22),
        const _SectionLabel(
          title: 'ACCOUNT',
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(
              14,
            ),
            leading: _Avatar(
              name: profile.name,
            ),
            title: Text(
              profile.name,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              profile.email.isEmpty ? 'Pet Owner' : profile.email,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
            ),
            onTap: onProfileTap,
          ),
        ),
        const SizedBox(height: 20),
        const _SectionLabel(
          title: 'PREFERENCES',
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.notifications_none_rounded,
                ),
                title: const Text(
                  'Notifications',
                ),
                subtitle: const Text(
                  'Manage reminders and alerts.',
                  style: TextStyle(
                    fontSize: 11,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Notification settings will be connected later.',
                      ),
                    ),
                  );
                },
              ),
              const Divider(
                height: 1,
                indent: 64,
              ),
              ListTile(
                leading: const Icon(
                  Icons.accessibility_new_rounded,
                ),
                title: const Text(
                  'Accessibility',
                ),
                subtitle: const Text(
                  'Text, contrast, and motion preferences.',
                  style: TextStyle(
                    fontSize: 11,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AccessibilityPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _SectionLabel(
          title: 'ACCOUNT ACTIONS',
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
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
            onTap: () => _showLogoutDialog(
              context,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showLogoutDialog(
    BuildContext context,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text(
            'Are you sure you want to log out of Pawcare?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
              ),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(
                  dialogContext,
                );

                try {
                  await AuthService.signOut();
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Could not log out: $error',
                        ),
                      ),
                    );
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text(
                'Log Out',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({
    required this.title,
  });

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

class _Avatar extends StatelessWidget {
  final String name;

  const _Avatar({
    required this.name,
  });

  String _initials() {
    final value = name.trim();

    if (value.isEmpty) {
      return 'P';
    }

    final words = value.split(
      RegExp(r'\s+'),
    );

    if (words.length == 1) {
      return words.first[0].toUpperCase();
    }

    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 27,
      backgroundColor: AppConstants.lightPrimary,
      child: Text(
        _initials(),
        style: const TextStyle(
          color: AppConstants.darkText,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
