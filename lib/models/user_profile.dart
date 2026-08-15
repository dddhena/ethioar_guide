import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String phone;
  final String bio;
  final String country;
  final String avatar;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.role = 'tourist',
    this.phone = '',
    this.bio = '',
    this.country = '',
    this.avatar = 'default',
    this.createdAt,
    this.updatedAt,
  });

  bool get isAdmin      => role.toLowerCase() == 'admin';
  bool get isProvider   => role.toLowerCase() == 'provider';
  bool get isTourGuide  => role.toLowerCase() == 'tour_guide';
  /// Tourists are role='tourist' OR legacy role='user'
  bool get isTourist    => role.toLowerCase() == 'tourist' || role.toLowerCase() == 'user';

  String get initials {
    if (name.trim().isEmpty) {
      return email.isNotEmpty ? email[0].toUpperCase() : 'U';
    }
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return UserProfile(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'tourist',
      phone: map['phone'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      country: map['country'] as String? ?? '',
      avatar: map['avatar'] as String? ?? 'default',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'email': email.trim(),
      'role': role,
      'phone': phone.trim(),
      'bio': bio.trim(),
      'country': country.trim(),
      'avatar': avatar,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? role,
    String? phone,
    String? bio,
    String? country,
    String? avatar,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      country: country ?? this.country,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
