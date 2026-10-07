import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';
import 'login_page.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;
  final Uint8List? profilePhotoBytes;
  final String? profilePhotoExtension;

  const VerifyEmailPage({
    super.key,
    required this.email,
    this.profilePhotoBytes,
    this.profilePhotoExtension,
  });

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _codeController = TextEditingController();

  final _codeFocusNode = FocusNode();

  Timer? _resendTimer;

  int _secondsRemaining = 60;

  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();

    _startResendTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _codeFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeController.dispose();
    _codeFocusNode.dispose();

    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();

    setState(() {
      _secondsRemaining = 60;
    });

    _resendTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_secondsRemaining <= 1) {
          timer.cancel();

          setState(() {
            _secondsRemaining = 0;
          });
        } else {
          setState(() {
            _secondsRemaining--;
          });
        }
      },
    );
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();

    if (code.length != 6) {
      _showMessage(
        'Please enter the 6-digit verification code.',
      );

      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      await AuthService.verifySignupCode(
        email: widget.email,
        code: code,
      );

      var profilePhotoFailed = false;
      if (widget.profilePhotoBytes != null) {
        try {
          await AuthService.updateProfilePhoto(
            photoBytes: widget.profilePhotoBytes!,
            photoExtension: widget.profilePhotoExtension ?? 'jpg',
          );
        } catch (_) {
          profilePhotoFailed = true;
        }
      }

      if (!mounted) return;

      // Verification creates a session.
      // We sign out immediately because Pawcare
      // will ask the user to log in normally after
      // their email has been verified.
      await AuthService.signOut();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: Row(
              children: const [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppConstants.primaryColor,
                  size: 30,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Email Verified!',
                  ),
                ),
              ],
            ),
            content: Text(
              profilePhotoFailed
                  ? 'Your Pawcare account has been verified. The photo could not be saved, but you can add it later in your profile.'
                  : 'Your Pawcare account has been verified successfully. You can now log in.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                ),
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
        (route) => false,
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
        'We could not verify your email. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    if (_secondsRemaining > 0 || _isResending) {
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      await AuthService.resendSignupCode(
        widget.email,
      );

      if (!mounted) return;

      _startResendTimer();

      _showMessage(
        'A new verification code has been sent.',
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
        'Could not resend the code. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  String _friendlyAuthError(
    String message,
  ) {
    final lower = message.toLowerCase();

    if (lower.contains('expired')) {
      return 'This verification code has expired. Please request a new one.';
    }

    if (lower.contains('invalid')) {
      return 'That verification code is incorrect. Please check the email and try again.';
    }

    if (lower.contains('rate')) {
      return 'Please wait a moment before requesting another code.';
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

  String _maskedEmail() {
    final email = widget.email.trim();

    final parts = email.split('@');

    if (parts.length != 2) {
      return email;
    }

    final username = parts[0];

    if (username.length <= 2) {
      return '${username[0]}***@${parts[1]}';
    }

    return '${username.substring(0, 2)}***@${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          onPressed: _isVerifying
              ? null
              : () {
                  Navigator.pop(
                    context,
                  );
                },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            18,
            24,
            32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // PAW ICON
                  Container(
                    width: 86,
                    height: 86,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.lightPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_rounded,
                      size: 43,
                      color: AppConstants.primaryColor,
                    ),
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  const Text(
                    'Verify Your Email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                      color: AppConstants.darkText,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  const Text(
                    'We sent a 6-digit verification code to',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    _maskedEmail(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppConstants.darkText,
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  // CODE INPUT
                  TextField(
                    controller: _codeController,
                    focusNode: _codeFocusNode,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    autofocus: true,
                    enabled: !_isVerifying,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: const TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 8,
                      color: AppConstants.darkText,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '000000',
                      hintStyle: TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 8,
                        color: Colors.black.withOpacity(
                          .16,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 18,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          17,
                        ),
                        borderSide: BorderSide(
                          color: AppConstants.primaryColor.withOpacity(
                            .35,
                          ),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          17,
                        ),
                        borderSide: const BorderSide(
                          color: AppConstants.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.length == 6) {
                        _verifyCode();
                      }
                    },
                    onSubmitted: (_) => _verifyCode(),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  const Text(
                    'Enter the code from the email to verify your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: _isVerifying ? null : _verifyCode,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            16,
                          ),
                        ),
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Verify Email',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  TextButton(
                    onPressed: _secondsRemaining == 0 && !_isResending
                        ? _resendCode
                        : null,
                    child: _isResending
                        ? const Text(
                            'Sending new code...',
                          )
                        : _secondsRemaining > 0
                            ? Text(
                                'Resend code in ${_secondsRemaining}s',
                              )
                            : const Text(
                                'Resend Code',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  TextButton(
                    onPressed: _isVerifying
                        ? null
                        : () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                              (route) => false,
                            );
                          },
                    child: const Text(
                      'Back to Login',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
