import 'package:cloud_firestore/cloud_firestore.dart';

class GuideProfile {
  final String userId;
  final String fullName;
  final String displayName;
  final String email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String city;
  final int yearsOfExperience;
  final List<String> languages;
  final List<String> specialties;
  final String bio;
  final List<String> services;
  final Map<String, dynamic> pricing;
  final Map<String, dynamic> availability;
  final bool profileCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  GuideProfile({
    required this.userId,
    required this.fullName,
    required this.displayName,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    required this.city,
    required this.yearsOfExperience,
    required this.languages,
    required this.specialties,
    required this.bio,
    required this.services,
    required this.pricing,
    required this.availability,
    required this.profileCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GuideProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GuideProfile(
      userId: data['userId'] ?? '',
      fullName: data['fullName'] ?? '',
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'],
      profileImageUrl: data['profileImageUrl'],
      city: data['city'] ?? '',
      yearsOfExperience: data['yearsOfExperience'] ?? 0,
      languages: List<String>.from(data['languages'] ?? []),
      specialties: List<String>.from(data['specialties'] ?? []),
      bio: data['bio'] ?? '',
      services: List<String>.from(data['services'] ?? []),
      pricing: data['pricing'] ?? {},
      availability: data['availability'] ?? {},
      profileCompleted: data['profileCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'city': city,
      'yearsOfExperience': yearsOfExperience,
      'languages': languages,
      'specialties': specialties,
      'bio': bio,
      'services': services,
      'pricing': pricing,
      'availability': availability,
      'profileCompleted': profileCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Helper getters for display
  String get publicName => displayName.isNotEmpty ? displayName : fullName;
  String get languagesLabel => languages.join(' • ');
  String get specialtiesLabel => specialties.join(' •');
  
  bool get hasPhoto => profileImageUrl != null && profileImageUrl!.isNotEmpty;
  
  String get ratingLabel {
    if (rating == 0) return 'New Guide';
    return rating.toStringAsFixed(1);
  }
  
  String get experienceLabel => '$yearsOfExperience Years';
  
  Map<String, dynamic> get pricingInfo => pricing;
  String get pricingFormatted {
    final amount = pricing['amount'] ?? 0;
    final type = pricing['type'] ?? 'Per Tour';
    return 'ETB $amount / $type';
  }
  
  String get pricingLabel {
    final amount = pricing['amount'] ?? 0;
    final type = pricing['type'] ?? 'Per Tour';
    return 'ETB $amount / $type';
  }

  String get availabilityLabel {
    final days = availability['days'] as List<String>?;
    if (days == null || days.isEmpty) return 'Contact for availability';
    return days.join(', ');
  }

  double get rating => 0.0; // Will be calculated from reviews later

  GuideProfile copyWith({
    String? userId,
    String? fullName,
    String? displayName,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    String? city,
    int? yearsOfExperience,
    List<String>? languages,
    List<String>? specialties,
    String? bio,
    List<String>? services,
    Map<String, dynamic>? pricing,
    Map<String, dynamic>? availability,
    bool? profileCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GuideProfile(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      city: city ?? this.city,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      languages: languages ?? this.languages,
      specialties: specialties ?? this.specialties,
      bio: bio ?? this.bio,
      services: services ?? this.services,
      pricing: pricing ?? this.pricing,
      availability: availability ?? this.availability,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
