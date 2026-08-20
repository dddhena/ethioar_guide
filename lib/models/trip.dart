import 'package:cloud_firestore/cloud_firestore.dart';

class TouristTrip {
  final String id;
  final String touristId;
  final String name;
  final String country;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> placeIds;
  final String status; // planning / active / completed
  final DateTime? createdAt;

  TouristTrip({
    required this.id,
    required this.touristId,
    required this.name,
    this.country = 'Ethiopia',
    required this.startDate,
    required this.endDate,
    this.placeIds = const [],
    this.status = 'planning',
    this.createdAt,
  });

  bool get isCompleted => status == 'completed';
  bool get isActive => status == 'active';

  String get dateRangeLabel {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[startDate.month - 1]} ${startDate.day} - ${months[endDate.month - 1]} ${endDate.day}';
  }

  factory TouristTrip.fromMap(String id, Map<String, dynamic> data) {
    DateTime parse(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullable(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return TouristTrip(
      id: id,
      touristId: data['touristId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      country: data['country'] as String? ?? 'Ethiopia',
      startDate: parse(data['startDate']),
      endDate: parse(data['endDate']),
      placeIds: data['placeIds'] != null ? List<String>.from(data['placeIds']) : [],
      status: data['status'] as String? ?? 'planning',
      createdAt: parseNullable(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'touristId': touristId,
      'name': name,
      'country': country,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'placeIds': placeIds,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  TouristTrip copyWith({
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? placeIds,
    String? status,
  }) {
    return TouristTrip(
      id: id,
      touristId: touristId,
      name: name ?? this.name,
      country: country,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      placeIds: placeIds ?? this.placeIds,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
