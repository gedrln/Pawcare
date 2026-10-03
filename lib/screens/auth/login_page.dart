import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';
import 'forgot_password_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // EMAIL / PASSWORD LOGIN
  // --------------------------------------------------

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (response.session != null) {
        debugPrint(
          'Pawcare login successful.',
        );

        debugPrint(
          'Session exists: ${response.session != null}',
        );

        // Do NOT Navigator.push().
        //
        // AuthGate is listening to Supabase.
        // When the signedIn event arrives,
        // AuthGate automatically changes
        // LoginPage -> HomeShell.
        return;
      }

      _showMessage(
        'Login was not completed. Please try again.',
      );
    } on AuthException catch (error) {
      if (!mounted) return;

      _showMessage(
        error.message,
      );
    } catch (error) {
      if (!mounted) return;

      debugPrint(
        'Pawcare login error: $error',
      );

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

  // --------------------------------------------------
  // GOOGLE LOGIN
  // --------------------------------------------------

  Future<void> _loginWithGoogle() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.signInWithGoogle();

      // signInWithOAuth opens the browser/authentication flow.
      //
      // After Google authentication is completed,
      // Supabase redirects back to:
      //
      // io.pawcare.app://login-callback/
      //
      // AuthGate listens for the Supabase signedIn event
      // and automatically changes:
      //
      // LoginPage -> HomeShell
    } on AuthException catch (error) {
      if (!mounted) return;

      _showMessage(
        error.message,
      );
    } catch (error) {
      if (!mounted) return;

      debugPrint(
        'Pawcare Google login error: $error',
      );

      _showMessage(
        'Unable to sign in with Google. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --------------------------------------------------
  // SHOW MESSAGE
  // --------------------------------------------------

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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              24,
              28,
              24,
              32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --------------------------------------------------
                    // LOGO
                    // --------------------------------------------------

                    Image.asset(
                      'assets/images/pawcare_logo.png',
                      height: 90,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.pets_rounded,
                          size: 80,
                          color: AppConstants.primaryColor,
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // --------------------------------------------------
                    // TITLE
                    // --------------------------------------------------

                    const Text(
                      'Welcome Back!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.darkText,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Log in to continue caring for your pets.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --------------------------------------------------
                    // EMAIL
                    // --------------------------------------------------

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

                        if (!email.contains('@')) {
                          return 'Enter a valid email.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    // --------------------------------------------------
                    // PASSWORD
                    // --------------------------------------------------

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
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
                        if ((value ?? '').isEmpty) {
                          return 'Enter your password.';
                        }

                        return null;
                      },
                    ),

                    // --------------------------------------------------
                    // FORGOT PASSWORD
                    // --------------------------------------------------

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ForgotPasswordPage(),
                                  ),
                                );
                              },
                        child: const Text(
                          'Forgot Password?',
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // --------------------------------------------------
                    // EMAIL LOGIN BUTTON
                    // --------------------------------------------------

                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _login,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
                                'Log In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --------------------------------------------------
                    // GOOGLE LOGIN BUTTON
                    // --------------------------------------------------

                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _loginWithGoogle,
                      icon: const Icon(
                        Icons.g_mobiledata_rounded,
                        size: 30,
                      ),
                      label: const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppConstants.darkText,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: AppConstants.darkText.withValues(alpha: 0.18),
                        ),
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // --------------------------------------------------
                    // SIGN UP
                    // --------------------------------------------------

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SignupPage(),
                                    ),
                                  );
                                },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
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
