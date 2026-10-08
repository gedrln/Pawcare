import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabasePublishableKey,
  );

  runApp(const PawcareApp());
}

class PawcareApp extends StatelessWidget {
  const PawcareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.light,
      home: const AuthGate(),
      onGenerateRoute: (settings) {
        final routeUri = Uri.tryParse(settings.name ?? '');
        final isAuthCallback = routeUri != null &&
            (routeUri.queryParameters.containsKey('code') ||
                routeUri.queryParameters.containsKey('access_token') ||
                routeUri.queryParameters.containsKey('token_hash') ||
                routeUri.queryParameters.containsKey('error'));

        if (isAuthCallback) {
          // Supabase handles the callback and updates the auth session. Map
          // its incoming URL to the existing auth gate instead of letting
          // Navigator treat `/?code=...` as an undefined app route.
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const AuthGate(),
          );
        }

        return null;
      },
    );
  }
}
