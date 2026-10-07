import 'dart:typed_data';

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

  static Future<AuthResponse> verifyPasswordResetCode({
    required String email,
    required String code,
  }) {
    return client.auth.verifyOTP(
      email: email.trim(),
      token: code.trim(),
      type: OtpType.recovery,
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

  /// Saves profile metadata and, when supplied, uploads the selected image to
  /// the existing public pet-photos bucket under the signed-in user's folder.
  static Future<UserResponse> updateProfile({
    String? fullName,
    Uint8List? photoBytes,
    String? photoExtension,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Please sign in to update your profile.');

    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName.trim();

    String? uploadedPath;
    String? previousAvatarUrl;
    if (photoBytes != null && photoBytes.isNotEmpty) {
      final extension = _cleanImageExtension(photoExtension);
      uploadedPath =
          '${user.id}/profile_${DateTime.now().millisecondsSinceEpoch}.$extension';
      previousAvatarUrl = user.userMetadata?['avatar_url']?.toString();

      await client.storage.from('pet-photos').uploadBinary(
            uploadedPath,
            photoBytes,
            fileOptions: FileOptions(
              contentType: _contentTypeFor(extension),
              upsert: true,
            ),
          );
      data['avatar_url'] =
          client.storage.from('pet-photos').getPublicUrl(uploadedPath);
    }

    try {
      final response = await client.auth.updateUser(UserAttributes(data: data));
      if (uploadedPath != null && previousAvatarUrl != null) {
        final oldPath = _profileStoragePath(previousAvatarUrl);
        if (oldPath != null && oldPath != uploadedPath) {
          try {
            await client.storage.from('pet-photos').remove([oldPath]);
          } catch (_) {
            // The profile update is successful even if an old image cannot
            // be removed due to storage policy or network errors.
          }
        }
      }
      return response;
    } catch (_) {
      if (uploadedPath != null) {
        try {
          await client.storage.from('pet-photos').remove([uploadedPath]);
        } catch (_) {}
      }
      rethrow;
    }
  }

  static Future<UserResponse> updateProfilePhoto({
    required Uint8List photoBytes,
    required String photoExtension,
  }) {
    final fullName = currentUser?.userMetadata?['full_name']?.toString();
    return updateProfile(
      fullName: fullName,
      photoBytes: photoBytes,
      photoExtension: photoExtension,
    );
  }

  static String _cleanImageExtension(String? extension) {
    final value = extension?.toLowerCase().replaceAll('.', '').trim();
    return const {'jpg', 'jpeg', 'png', 'webp', 'heic'}.contains(value)
        ? value!
        : 'jpg';
  }

  static String _contentTypeFor(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'application/octet-stream',
    };
  }

  static String? _profileStoragePath(String url) {
    const marker = '/storage/v1/object/public/pet-photos/';
    final markerIndex = url.indexOf(marker);
    if (markerIndex < 0) return null;
    return Uri.decodeComponent(url.substring(markerIndex + marker.length));
  }

  // --------------------------------------------------
  // LOG OUT
  // --------------------------------------------------

  static Future<void> signOut() {
    return client.auth.signOut();
  }
}
