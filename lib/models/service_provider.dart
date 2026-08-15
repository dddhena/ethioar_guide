import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceProvider {
  final String id;
  final String userId;
  final String businessName;
  final String businessType; // 'hotel', 'restaurant', 'transport'
  final String description;
  final String address;
  final String city;
  final String region;
  final double latitude;
  final double longitude;
  final String phone;
  final List<String> facilities;
  final String priceRange; // '$', '$$', '$$$', '$$$$'
  final String openingHours;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final String approvalStatus; // 'pending', 'approved', 'rejected'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ServiceProvider({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.businessType,
    this.description = '',
    this.address = '',
    this.city = '',
    this.region = '',
    this.latitude = 9.0320,
    this.longitude = 38.7469,
    this.phone = '',
    this.facilities = const [],
    this.priceRange = r'$$',
    this.openingHours = '24/7',
    this.images = const [],
    this.rating = 4.5,
    this.reviewCount = 0,
    this.approvalStatus = 'approved',
    this.createdAt,
    this.updatedAt,
  });

  bool get isApproved => approvalStatus.toLowerCase() == 'approved';
  bool get isPending => approvalStatus.toLowerCase() == 'pending';

  String get typeIcon {
    switch (businessType.toLowerCase()) {
      case 'hotel':
        return '🏨';
      case 'restaurant':
        return '🍽️';
      case 'transport':
        return '🚗';
      default:
        return '🏢';
    }
  }

  String get typeDisplayName {
    switch (businessType.toLowerCase()) {
      case 'hotel':
        return 'Hotel & Lodging';
      case 'restaurant':
        return 'Restaurant & Dining';
      case 'transport':
        return 'Transport & Car Rental';
      default:
        return businessType;
    }
  }

  factory ServiceProvider.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    List<String> parseList(dynamic val) {
      if (val is List) return val.map((e) => e.toString()).toList();
      return [];
    }

    return ServiceProvider(
      id: id,
      userId: map['userId'] as String? ?? '',
      businessName: map['businessName'] as String? ?? '',
      businessType: map['businessType'] as String? ?? 'hotel',
      description: map['description'] as String? ?? '',
      address: map['address'] as String? ?? '',
      city: map['city'] as String? ?? '',
      region: map['region'] as String? ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      phone: map['phone'] as String? ?? '',
      facilities: parseList(map['facilities']),
      priceRange: map['priceRange'] as String? ?? r'$$',
      openingHours: map['openingHours'] as String? ?? '24/7',
      images: parseList(map['images']),
      rating: (map['rating'] ?? 4.5).toDouble(),
      reviewCount: (map['reviewCount'] ?? 0) as int,
      approvalStatus: map['approvalStatus'] as String? ?? 'approved',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'businessName': businessName.trim(),
      'businessType': businessType,
      'description': description.trim(),
      'address': address.trim(),
      'city': city.trim(),
      'region': region.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone.trim(),
      'facilities': facilities,
      'priceRange': priceRange,
      'openingHours': openingHours.trim(),
      'images': images,
      'rating': rating,
      'reviewCount': reviewCount,
      'approvalStatus': approvalStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ServiceProvider copyWith({
    String? id,
    String? userId,
    String? businessName,
    String? businessType,
    String? description,
    String? address,
    String? city,
    String? region,
    double? latitude,
    double? longitude,
    String? phone,
    List<String>? facilities,
    String? priceRange,
    String? openingHours,
    List<String>? images,
    double? rating,
    int? reviewCount,
    String? approvalStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceProvider(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      region: region ?? this.region,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      facilities: facilities ?? this.facilities,
      priceRange: priceRange ?? this.priceRange,
      openingHours: openingHours ?? this.openingHours,
      images: images ?? this.images,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
