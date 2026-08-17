import 'package:cloud_firestore/cloud_firestore.dart';

class TourPackage {
  final String id;
  final String guideId;
  final String name;
  final String tourType;
  final String description;
  final double durationHours;
  final double price;
  final List<String> attractions;
  final List<String> waypoints;
  final Map<String, String> audioFiles;
  final String language;
  final int downloadCount;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TourPackage({
    required this.id,
    required this.guideId,
    required this.name,
    this.tourType = 'cultural-heritage',
    this.description = '',
    this.durationHours = 4,
    this.price = 0,
    this.attractions = const [],
    this.waypoints = const [],
    this.audioFiles = const {},
    this.language = 'English',
    this.downloadCount = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  String get formattedPrice => '${price.toStringAsFixed(0)} ETB';

  String get durationLabel {
    if (durationHours == durationHours.roundToDouble()) {
      return '${durationHours.toInt()} hours';
    }
    return '${durationHours.toStringAsFixed(1)} hours';
  }

  String get attractionsLabel =>
      attractions.isEmpty ? 'No attractions listed' : attractions.join(', ');

  factory TourPackage.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    List<String> parseList(dynamic val) {
      if (val is List) return val.map((e) => e.toString()).toList();
      return [];
    }

    Map<String, String> parseAudio(dynamic val) {
      if (val is Map) {
        return val.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
      return {};
    }

    return TourPackage(
      id: id,
      guideId: map['guideId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      tourType: map['tourType'] as String? ?? 'cultural-heritage',
      description: map['description'] as String? ?? '',
      durationHours: (map['durationHours'] ?? 4).toDouble(),
      price: (map['price'] ?? 0).toDouble(),
      attractions: parseList(map['attractions']),
      waypoints: parseList(map['waypoints']),
      audioFiles: parseAudio(map['audioFiles']),
      language: map['language'] as String? ?? 'English',
      downloadCount: ((map['downloadCount'] ?? 0) as num).toInt(),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'guideId': guideId,
      'name': name.trim(),
      'tourType': tourType,
      'description': description.trim(),
      'durationHours': durationHours,
      'price': price,
      'attractions': attractions,
      'waypoints': waypoints,
      'audioFiles': audioFiles,
      'language': language,
      'downloadCount': downloadCount,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
