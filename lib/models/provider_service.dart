import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderService {
  final String id;
  final String providerId;
  final String name; // e.g. "Standard King Room", "Table for 4", "Airport Shuttle"
  final String serviceType; // 'room', 'dining', 'vehicle', 'package'
  final String description;
  final double price; // in ETB / USD
  final int capacity; // number of guests / rooms / passengers
  final bool isAvailable;
  final List<String> images;
  final DateTime? createdAt;

  ProviderService({
    required this.id,
    required this.providerId,
    required this.name,
    this.serviceType = 'room',
    this.description = '',
    this.price = 0.0,
    this.capacity = 1,
    this.isAvailable = true,
    this.images = const [],
    this.createdAt,
  });

  String get formattedPrice => '${price.toStringAsFixed(0)} ETB';

  String get capacityLabel {
    switch (serviceType.toLowerCase()) {
      case 'room':
        return '$capacity Guests';
      case 'dining':
        return '$capacity Seats';
      case 'vehicle':
        return '$capacity Passengers';
      default:
        return 'Capacity: $capacity';
    }
  }

  factory ProviderService.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    List<String> parseList(dynamic val) {
      if (val is List) return val.map((e) => e.toString()).toList();
      return [];
    }

    return ProviderService(
      id: id,
      providerId: map['providerId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      serviceType: map['serviceType'] as String? ?? 'room',
      description: map['description'] as String? ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      capacity: (map['capacity'] ?? 1) as int,
      isAvailable: map['isAvailable'] as bool? ?? true,
      images: parseList(map['images']),
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'name': name.trim(),
      'serviceType': serviceType,
      'description': description.trim(),
      'price': price,
      'capacity': capacity,
      'isAvailable': isAvailable,
      'images': images,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  ProviderService copyWith({
    String? id,
    String? providerId,
    String? name,
    String? serviceType,
    String? description,
    double? price,
    int? capacity,
    bool? isAvailable,
    List<String>? images,
    DateTime? createdAt,
  }) {
    return ProviderService(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      name: name ?? this.name,
      serviceType: serviceType ?? this.serviceType,
      description: description ?? this.description,
      price: price ?? this.price,
      capacity: capacity ?? this.capacity,
      isAvailable: isAvailable ?? this.isAvailable,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
