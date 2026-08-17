import 'package:cloud_firestore/cloud_firestore.dart';

class Guide {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String profileImageUrl;
  final String bio;
  final List<String> languages;
  final List<String> qualifications;
  final int experienceYears;
  final double price;
  final double rating;
  final int reviewCount;
  /// Weekday name → available (Monday … Sunday).
  final Map<String, bool> availability;
  final String status; // active / pending / inactive
  final DateTime? createdAt;

  static const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  Guide({
    required this.id,
    required this.userId,
    this.name = '',
    this.email = '',
    this.phone = '',
    this.profileImageUrl = '',
    this.bio = '',
    this.languages = const ['English'],
    this.qualifications = const [],
    this.experienceYears = 1,
    this.price = 0,
    this.rating = 0,
    this.reviewCount = 0,
    this.availability = const {},
    this.status = 'active',
    this.createdAt,
  });

  bool get isActive => status.toLowerCase() == 'active';

  String get formattedPrice => '${price.toStringAsFixed(0)} ETB / day';

  String get languagesLabel => languages.isEmpty ? '—' : languages.join(', ');

  String get qualificationsLabel =>
      qualifications.isEmpty ? 'None listed' : qualifications.join(' • ');

  List<String> get availableDays => weekdays
      .where((d) => availability[d] ?? false)
      .toList();

  String get availabilitySummary {
    final days = availableDays;
    if (days.isEmpty) return 'No days marked available';
    if (days.length == 7) return 'Available every day';
    return days.join(', ');
  }

  factory Guide.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    List<String> parseList(dynamic val) {
      if (val is List) return val.map((e) => e.toString()).toList();
      if (val is String && val.trim().isNotEmpty) {
        return val.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    Map<String, bool> parseAvailability(dynamic val) {
      final result = <String, bool>{};
      for (final day in weekdays) {
        result[day] = true;
      }
      if (val is Map) {
        for (final day in weekdays) {
          result[day] = val[day] == true;
        }
      }
      return result;
    }

    return Guide(
      id: id,
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      profileImageUrl: map['profileImageUrl'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      languages: parseList(map['languages']),
      qualifications: parseList(map['qualifications']),
      experienceYears: ((map['experienceYears'] ?? 1) as num).toInt(),
      price: (map['price'] ?? 0).toDouble(),
      rating: (map['rating'] ?? 0).toDouble(),
      reviewCount: ((map['reviewCount'] ?? 0) as num).toInt(),
      availability: parseAvailability(map['availability']),
      status: map['status'] as String? ?? 'active',
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'profileImageUrl': profileImageUrl.trim(),
      'bio': bio.trim(),
      'languages': languages,
      'qualifications': qualifications,
      'experienceYears': experienceYears,
      'price': price,
      'rating': rating,
      'reviewCount': reviewCount,
      'availability': availability,
      'status': status,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  Guide copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    String? bio,
    List<String>? languages,
    List<String>? qualifications,
    int? experienceYears,
    double? price,
    double? rating,
    int? reviewCount,
    Map<String, bool>? availability,
    String? status,
    DateTime? createdAt,
  }) {
    return Guide(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      languages: languages ?? this.languages,
      qualifications: qualifications ?? this.qualifications,
      experienceYears: experienceYears ?? this.experienceYears,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      availability: availability ?? this.availability,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
