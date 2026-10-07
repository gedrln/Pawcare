import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String name;
  final String email;
  final String? avatarUrl;

  const UserProfile({
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  factory UserProfile.fromUser(User user) {
    final metadata = user.userMetadata ?? {};

    final fullName =
        (metadata['full_name'] ?? metadata['name'] ?? '').toString().trim();

    return UserProfile(
      name: fullName.isEmpty ? 'Pet Owner' : fullName,
      email: user.email ?? '',
      avatarUrl:
          (metadata['avatar_url'] ?? metadata['picture'])?.toString(),
    );
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? avatarUrl,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

const initialUserProfile = UserProfile(
  name: 'Pet Owner',
  email: '',
  avatarUrl: null,
);
