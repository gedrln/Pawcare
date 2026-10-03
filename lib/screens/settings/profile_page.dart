import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  final UserProfile profile;

  const ProfilePage({
    super.key,
    required this.profile,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _nameController;

  late final TextEditingController _emailController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.profile.name,
    );

    _emailController = TextEditingController(
      text: widget.profile.email,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();

    super.dispose();
  }

  String _initials(String value) {
    final name = value.trim();

    if (name.isEmpty) {
      return 'P';
    }

    final words = name.split(RegExp(r'\s+'));

    if (words.length == 1) {
      return words.first[0].toUpperCase();
    }

    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name.'),
        ),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await AuthService.updateFullName(name);

      final updatedUser = response.user ?? AuthService.currentUser;

      if (!mounted) return;

      final updatedProfile = updatedUser == null
          ? widget.profile.copyWith(
              name: name,
            )
          : UserProfile.fromUser(
              updatedUser,
            );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile updated successfully.',
          ),
        ),
      );

      Navigator.pop(
        context,
        updatedProfile,
      );
    } on AuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not update your profile.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          30,
        ),
        children: [
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppConstants.lightPrimary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppConstants.primaryColor.withOpacity(.25),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  _initials(
                    _nameController.text,
                  ),
                  style: const TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.darkText,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Pet Owner',
              style: TextStyle(
                color: Colors.black45,
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppConstants.darkText,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) {
              setState(() {});
            },
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(
                Icons.person_outline_rounded,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(
                Icons.email_outlined,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Email is managed by Supabase authentication.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.save_rounded,
                    ),
              label: Text(
                _isSaving ? 'Saving...' : 'Save Changes',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
