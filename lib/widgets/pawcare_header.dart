import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
import '../models/user_profile.dart';

class PawcareHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  final bool showProfile;

  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;

  final UserProfile? profile;

  const PawcareHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showProfile = true,
    this.onProfileTap,
    this.onNotificationTap,
    this.profile,
  });

  // ============================================================
  // GET THE CURRENT USER'S NAME
  // ============================================================

  String _currentUserName() {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      return '';
    }

    final metadata = user.userMetadata;

    if (metadata != null) {
      final fullName = metadata['full_name']?.toString().trim();

      if (fullName != null && fullName.isNotEmpty) {
        return fullName;
      }

      final name = metadata['name']?.toString().trim();

      if (name != null && name.isNotEmpty) {
        return name;
      }

      final displayName = metadata['display_name']?.toString().trim();

      if (displayName != null && displayName.isNotEmpty) {
        return displayName;
      }
    }

    // If the account doesn't have a name in metadata,
    // use the email as a fallback.
    final email = user.email?.trim();

    if (email != null && email.isNotEmpty) {
      final emailName = email.split('@').first;

      if (emailName.isNotEmpty) {
        return emailName;
      }
    }

    return '';
  }

  // ============================================================
  // GET NAME USED FOR INITIALS
  // ============================================================

  String _nameForInitials() {
    final currentUserName = _currentUserName();

    if (currentUserName.isNotEmpty) {
      return currentUserName;
    }

    if (profile != null) {
      final profileName = profile!.name.trim();

      if (profileName.isNotEmpty) {
        return profileName;
      }
    }

    return 'Pawcare User';
  }

  // ============================================================
  // CREATE USER INITIALS
  // ============================================================

  String _initials() {
    final name = _nameForInitials().trim();

    if (name.isEmpty) {
      return 'P';
    }

    final words = name.split(RegExp(r'\s+'));

    if (words.length == 1) {
      final word = words.first;

      if (word.length == 1) {
        return word.toUpperCase();
      }

      return word.substring(0, 1).toUpperCase();
    }

    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showProfile)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onProfileTap,
              borderRadius: BorderRadius.circular(17),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppConstants.lightPrimary,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Center(
                  child: Text(
                    _initials(),
                    style: const TextStyle(
                      color: AppConstants.darkText,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (showProfile) const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: AppConstants.darkText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              onPressed: onNotificationTap,
              icon: const Icon(
                Icons.notifications_none_rounded,
              ),
              color: AppConstants.darkText,
            ),
          ),
        ),
      ],
    );
  }
}
