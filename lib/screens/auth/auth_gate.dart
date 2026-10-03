import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../home/home_shell.dart';
import 'login_page.dart';
import 'update_password_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _authSubscription;

  Session? _session;

  bool _isLoading = true;
  bool _isPasswordRecovery = false;

  @override
  void initState() {
    super.initState();

    _session = AuthService.client.auth.currentSession;

    _listenToAuthChanges();

    _isLoading = false;
  }

  void _listenToAuthChanges() {
    _authSubscription = AuthService.client.auth.onAuthStateChange.listen(
      (AuthState data) {
        if (!mounted) return;

        final event = data.event;
        final session = data.session;

        debugPrint(
          'Pawcare Auth Event: $event',
        );

        debugPrint(
          'Pawcare Session: ${session != null}',
        );

        setState(() {
          _session = session;

          if (event == AuthChangeEvent.passwordRecovery) {
            _isPasswordRecovery = true;
          }

          if (event == AuthChangeEvent.signedOut) {
            _isPasswordRecovery = false;
          }

          _isLoading = false;
        });
      },
      onError: (
        Object error,
        StackTrace stackTrace,
      ) {
        debugPrint(
          'Pawcare Auth Error: $error',
        );

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _finishPasswordRecovery() {
    if (!mounted) return;

    setState(() {
      _isPasswordRecovery = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // -----------------------------------------
    // LOADING
    // -----------------------------------------

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: AppConstants.primaryColor,
          ),
        ),
      );
    }

    // -----------------------------------------
    // PASSWORD RECOVERY
    // -----------------------------------------

    if (_isPasswordRecovery && _session != null) {
      return UpdatePasswordPage(
        onPasswordUpdated: _finishPasswordRecovery,
      );
    }

    // -----------------------------------------
    // NOT LOGGED IN
    // -----------------------------------------

    if (_session == null) {
      return const LoginPage();
    }

    // -----------------------------------------
    // LOGGED IN
    // -----------------------------------------

    return const HomeShell();
  }
}
