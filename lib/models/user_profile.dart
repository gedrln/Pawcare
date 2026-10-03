import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String name;
  final String email;

  const UserProfile({
    required this.name,
    required this.email,
  });

  factory UserProfile.fromUser(User user) {
    final metadata = user.userMetadata ?? {};

    final fullName =
        (metadata['full_name'] ?? metadata['name'] ?? '').toString().trim();

    return UserProfile(
      name: fullName.isEmpty ? 'Pet Owner' : fullName,
      email: user.email ?? '',
    );
  }

  UserProfile copyWith({
    String? name,
    String? email,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }
}

const initialUserProfile = UserProfile(
  name: 'Pet Owner',
  email: '',
);
