import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../services/photo_crop_service.dart';
import 'verify_email_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  final _confirmPasswordController = TextEditingController();
  final _imagePicker = ImagePicker();

  Uint8List? _profilePhotoBytes;
  String? _profilePhotoExtension;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _isLoading = false;

  Future<void> _chooseProfilePhoto() async {
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
      if (croppedImage == null || !mounted) return;

      final bytes = await croppedImage.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty || bytes.length > 8 * 1024 * 1024) {
        _showMessage('Choose a profile photo smaller than 8 MB.');
        return;
      }

      setState(() {
        _profilePhotoBytes = bytes;
        _profilePhotoExtension = 'jpg';
      });
    } catch (_) {
      if (mounted) _showMessage('Could not select that profile photo.');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();

    try {
      final response = await AuthService.signUp(
        fullName: _nameController.text.trim(),
        email: email,
        password: _passwordController.text,
      );

      if (!mounted) return;

      // With Supabase "Confirm Email" enabled,
      // the normal response has a user but no session.
      //
      // The user now needs to enter the OTP
      // that Supabase sent to their email.
      if (response.user != null && response.session == null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyEmailPage(
              email: email,
              profilePhotoBytes: _profilePhotoBytes,
              profilePhotoExtension: _profilePhotoExtension,
            ),
          ),
        );

        return;
      }

      // This is only reached if email confirmation
      // has been disabled in Supabase.
      if (response.session != null) {
        var photoUploadFailed = false;
        if (_profilePhotoBytes != null) {
          try {
            await AuthService.updateProfilePhoto(
              photoBytes: _profilePhotoBytes!,
              photoExtension: _profilePhotoExtension ?? 'jpg',
            );
          } catch (_) {
            photoUploadFailed = true;
          }
        }
        _showMessage(
          photoUploadFailed
              ? 'Account created. You can add the profile photo later in your profile.'
              : 'Account created successfully.',
        );

        Navigator.pop(context);

        return;
      }

      _showMessage(
        'Account created. Please check your email.',
      );
    } on AuthException catch (error) {
      if (!mounted) return;

      _showMessage(
        _friendlyAuthError(
          error.message,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _friendlyAuthError(
    String message,
  ) {
    final lower = message.toLowerCase();

    if (lower.contains(
          'already registered',
        ) ||
        lower.contains(
          'already been registered',
        )) {
      return 'An account with this email already exists. Try logging in instead.';
    }

    if (lower.contains(
      'password',
    )) {
      return message;
    }

    return message;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            10,
            24,
            30,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Join Pawcare',
                      style: TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.darkText,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    const Text(
                      'Create an account to manage your pets and their care.',
                      style: TextStyle(
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(
                      height: 26,
                    ),

                    Center(
                      child: Column(
                        children: [
                          InkWell(
                            onTap: _isLoading ? null : _chooseProfilePhoto,
                            customBorder: const CircleBorder(),
                            child: CircleAvatar(
                              radius: 42,
                              backgroundColor: AppConstants.lightPrimary,
                              backgroundImage: _profilePhotoBytes == null
                                  ? null
                                  : MemoryImage(_profilePhotoBytes!),
                              child: _profilePhotoBytes == null
                                  ? const Icon(
                                      Icons.add_a_photo_outlined,
                                      color: AppConstants.darkText,
                                      size: 28,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _isLoading ? null : _chooseProfilePhoto,
                            child: Text(
                              _profilePhotoBytes == null
                                  ? 'Add profile photo (optional)'
                                  : 'Change profile photo',
                            ),
                          ),
                        ],
                      ),
                    ),

                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                        ),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Enter your full name.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                        ),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';

                        if (email.isEmpty) {
                          return 'Enter your email.';
                        }

                        if (!email.contains(
                          '@',
                        )) {
                          return 'Enter a valid email.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if ((value ?? '').length < 6) {
                          return 'Password must be at least 6 characters.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(
                          Icons.lock_reset_rounded,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _signup,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              16,
                            ),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pop(
                                context,
                              );
                            },
                      child: const Text(
                        'Already have an account? Log In',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
