import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';

class AuthService {
  AuthService._();

  static final SupabaseClient client = Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  // --------------------------------------------------
  // SIGN UP
  // --------------------------------------------------

  static Future<AuthResponse> signUp({
    required String fullName,
    required String email,
    required String password,
  }) {
    return client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
      },
    );
  }

  // --------------------------------------------------
  // VERIFY SIGNUP EMAIL OTP
  // --------------------------------------------------

  static Future<AuthResponse> verifySignupCode({
    required String email,
    required String code,
  }) {
    return client.auth.verifyOTP(
      email: email.trim(),
      token: code.trim(),
      type: OtpType.signup,
    );
  }

  // --------------------------------------------------
  // RESEND SIGNUP VERIFICATION CODE
  // --------------------------------------------------

  static Future<void> resendSignupCode(
    String email,
  ) async {
    await client.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
    );
  }

  // --------------------------------------------------
  // LOGIN
  // --------------------------------------------------

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  // --------------------------------------------------
  // GOOGLE LOGIN
  // --------------------------------------------------

  static Future<void> signInWithGoogle() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : AppConstants.authRedirectUrl,
      authScreenLaunchMode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
  }

  // --------------------------------------------------
  // FORGOT PASSWORD
  // --------------------------------------------------

  static Future<void> sendPasswordReset(
    String email,
  ) {
    return client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: AppConstants.authRedirectUrl,
    );
  }

  // --------------------------------------------------
  // UPDATE PASSWORD
  // --------------------------------------------------

  static Future<UserResponse> updatePassword(
    String password,
  ) {
    return client.auth.updateUser(
      UserAttributes(
        password: password,
      ),
    );
  }

  // --------------------------------------------------
  // UPDATE NAME
  // --------------------------------------------------

  static Future<UserResponse> updateFullName(
    String fullName,
  ) {
    return client.auth.updateUser(
      UserAttributes(
        data: {
          'full_name': fullName.trim(),
        },
      ),
    );
  }

  // --------------------------------------------------
  // LOG OUT
  // --------------------------------------------------

  static Future<void> signOut() {
    return client.auth.signOut();
  }
}
