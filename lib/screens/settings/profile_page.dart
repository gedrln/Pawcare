import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/photo_crop_service.dart';

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

  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _selectedPhotoBytes;
  String? _selectedPhotoExtension;

  bool _isSaving = false;
  bool _isPickingPhoto = false;

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

  Future<void> _chooseProfilePhoto() async {
    setState(() => _isPickingPhoto = true);
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (image == null) return;
      if (!mounted) return;

      final croppedImage = await PhotoCropService.cropSquare(
        context: context,
        sourcePath: image.path,
        title: 'Crop profile photo',
        circular: true,
      );
      if (croppedImage == null) return;

      final bytes = await croppedImage.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty || bytes.length > 8 * 1024 * 1024) {
        _showMessage('Choose a profile photo smaller than 8 MB.');
        return;
      }

      setState(() {
        _selectedPhotoBytes = bytes;
        _selectedPhotoExtension = 'jpg';
      });
    } catch (_) {
      if (mounted) _showMessage('Could not select that profile photo.');
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
      final response = await AuthService.updateProfile(
        fullName: name,
        photoBytes: _selectedPhotoBytes,
        photoExtension: _selectedPhotoExtension,
      );

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

  Widget _profileImage() {
    final selectedPhoto = _selectedPhotoBytes;
    if (selectedPhoto != null) {
      return Image.memory(
        selectedPhoto,
        width: 104,
        height: 104,
        fit: BoxFit.cover,
      );
    }

    final avatarUrl = widget.profile.avatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return Image.network(
        avatarUrl,
        width: 104,
        height: 104,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initialsAvatar(),
      );
    }

    return _initialsAvatar();
  }

  Widget _initialsAvatar() {
    return Center(
      child: Text(
        _initials(_nameController.text),
        style: const TextStyle(
          fontSize: 29,
          fontWeight: FontWeight.w800,
          color: AppConstants.darkText,
        ),
      ),
    );
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
            child: Column(
              children: [
                InkWell(
                  onTap:
                      _isSaving || _isPickingPhoto ? null : _chooseProfilePhoto,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 112,
                    height: 112,
                    child: Stack(
                      children: [
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            color: AppConstants.lightPrimary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppConstants.primaryColor.withOpacity(.25),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(child: _profileImage()),
                        ),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: CircleAvatar(
                            radius: 17,
                            backgroundColor: AppConstants.primaryColor,
                            child: Icon(
                              _isPickingPhoto
                                  ? Icons.hourglass_top_rounded
                                  : Icons.camera_alt_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed:
                      _isSaving || _isPickingPhoto ? null : _chooseProfilePhoto,
                  child: Text(
                    widget.profile.avatarUrl == null &&
                            _selectedPhotoBytes == null
                        ? 'Add profile photo'
                        : 'Change profile photo',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
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
