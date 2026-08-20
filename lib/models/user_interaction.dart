import 'package:cloud_firestore/cloud_firestore.dart';

class UserInteraction {
  final String id;
  final String touristId;
  final String attractionId;
  final String interactionType;
  final dynamic value;
  final DateTime timestamp;

  UserInteraction({
    required this.id,
    required this.touristId,
    required this.attractionId,
    required this.interactionType,
    this.value,
    required this.timestamp,
  });

  // Interaction types
  static const String view = 'view';
  static const String favorite = 'favorite';
  static const String rating = 'rating';
  static const String itineraryAdd = 'itinerary_add';
  static const String arOpen = 'ar_open';
  static const String booking = 'booking';

  factory UserInteraction.fromMap(String id, Map<String, dynamic> data) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return UserInteraction(
      id: id,
      touristId: data['touristId'] ?? '',
      attractionId: data['attractionId'] ?? '',
      interactionType: data['interactionType'] ?? '',
      value: data['value'],
      timestamp: parseDate(data['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'touristId': touristId,
      'attractionId': attractionId,
      'interactionType': interactionType,
      'value': value,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  // Calculate interaction weight for recommendation scoring
  double get weight {
    switch (interactionType) {
      case booking:
        return 5.0;
      case rating:
        return (value as num? ?? 0).toDouble() * 0.8;
      case favorite:
        return 3.0;
      case itineraryAdd:
        return 2.5;
      case arOpen:
        return 2.0;
      case view:
        return 1.0;
      default:
        return 0.5;
    }
  }
}