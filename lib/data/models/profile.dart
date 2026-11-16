import 'user_role.dart';

class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    required this.role,
    required this.isActive,
  });

  final String id;
  final String? fullName;
  final UserRole role;
  final bool isActive;

  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'User';
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    final role = UserRole.fromDb(map['role'] as String?);
    if (role == null) {
      throw const FormatException('Invalid or missing profile role');
    }
    return Profile(
      id: map['id'] as String,
      fullName: map['full_name'] as String?,
      role: role,
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}
