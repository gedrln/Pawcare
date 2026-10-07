import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isLoading = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode({bool validateEmail = true}) async {
    if (validateEmail && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.sendPasswordReset(
        _emailController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _codeSent = true);
      _showMessage(
        'If an account exists for this email, a recovery code has been sent.',
      );
    } on AuthException catch (error) {
      if (!mounted) return;

      _showMessage(error.message);
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

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await AuthService.verifyPasswordResetCode(
        email: _emailController.text,
        code: _codeController.text,
      );

      if (!mounted) return;
      if (response.session == null) {
        _showMessage('The code could not be verified. Please try again.');
        return;
      }

      // AuthGate handles the passwordRecovery event and shows the new-password
      // screen underneath this route.
      Navigator.of(context).pop();
    } on AuthException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not verify the code. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            30,
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
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppConstants.lightPrimary,
                        borderRadius: BorderRadius.circular(
                          24,
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        size: 40,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Reset Your Password',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _codeSent
                          ? 'If an account exists, enter the recovery code sent to ${_emailController.text.trim()}.'
                          : 'Enter your email and we will send you a verification code to reset your password.',
                      style: TextStyle(
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      enabled: !_codeSent && !_isLoading,
                      keyboardType: TextInputType.emailAddress,
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

                        if (!email.contains('@')) {
                          return 'Enter a valid email.';
                        }

                        return null;
                      },
                    ),
                    if (_codeSent) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _codeController,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.number,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Verification code',
                          prefixIcon: Icon(Icons.password_rounded),
                          counterText: '',
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().length != 6) {
                            return 'Enter the 6-digit code from your email.';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed: _isLoading
                            ? null
                            : _codeSent
                                ? _verifyCode
                                : _sendResetCode,
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
                            : Text(
                                _codeSent
                                    ? 'Verify Code'
                                    : 'Send Verification Code',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    if (_codeSent) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => _sendResetCode(validateEmail: false),
                            child: const Text('Resend code'),
                          ),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _codeSent = false;
                                      _codeController.clear();
                                    });
                                  },
                            child: const Text('Change email'),
                          ),
                        ],
                      ),
                    ],
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
