import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Pawcare';

  static const Color primaryColor = Color(0xFFD88B2A);
  static const Color lightPrimary = Color(0xFFFFE7BB);
  static const Color backgroundColor = Color(0xFFFFF8ED);
  static const Color darkText = Color(0xFF6B3F14);

  // Supabase project
  static const String supabaseUrl = 'https://ptmtmtlcyzvmealginvf.supabase.co';

  // Supabase Publishable Key
  static const String supabasePublishableKey =
      'sb_publishable_vAmI78KdRa5KYX2KSCFchw_giUi_UA-';

  // This is used for email verification and password reset.
  //
  // Add this exact URL to:
  // Supabase Dashboard
  // > Authentication
  // > URL Configuration
  // > Redirect URLs
  static const String authRedirectUrl = 'io.pawcare.app://login-callback/';

  static const String pawcareAiFunction = 'pawcare-ai';
}
