import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyAlert {
  final String id;
  final String touristId;
  final String touristName;
  final String touristPhone;
  final String touristEmail;
  final double latitude;
  final double longitude;
  final String locationName;
  final String emergencyType; // 'medical', 'security', 'lost', 'general'
  final String message;
  final String status; // 'active', 'responding', 'resolved'
  final String? responderId;
  final String? responderName;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  EmergencyAlert({
    required this.id,
    required this.touristId,
    required this.touristName,
    this.touristPhone = '',
    this.touristEmail = '',
    required this.latitude,
    required this.longitude,
    this.locationName = 'Ethiopia',
    this.emergencyType = 'general',
    this.message = 'Immediate assistance requested',
    this.status = 'active',
    this.responderId,
    this.responderName,
    this.createdAt,
    this.resolvedAt,
  });

  bool get isActive => status == 'active';
  bool get isResponding => status == 'responding';
  bool get isResolved => status == 'resolved';

  String get typeLabel {
    switch (emergencyType.toLowerCase()) {
      case 'medical':
        return '🚑 Medical Emergency';
      case 'security':
        return '👮 Security Threat';
      case 'lost':
        return '📍 Lost / Stranded';
      default:
        return '⚠️ Urgent Emergency';
    }
  }

  factory EmergencyAlert.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return EmergencyAlert(
      id: id,
      touristId: map['touristId'] as String? ?? '',
      touristName: map['touristName'] as String? ?? '',
      touristPhone: map['touristPhone'] as String? ?? '',
      touristEmail: map['touristEmail'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      locationName: map['locationName'] as String? ?? 'Ethiopia',
      emergencyType: map['emergencyType'] as String? ?? 'general',
      message: map['message'] as String? ?? 'Immediate assistance requested',
      status: map['status'] as String? ?? 'active',
      responderId: map['responderId'] as String?,
      responderName: map['responderName'] as String?,
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
      resolvedAt: parseDate(map['resolvedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'touristId': touristId,
      'touristName': touristName,
      'touristPhone': touristPhone,
      'touristEmail': touristEmail,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'emergencyType': emergencyType,
      'message': message,
      'status': status,
      'responderId': responderId,
      'responderName': responderName,
      'createdAt': FieldValue.serverTimestamp(),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }

  String get timeAgo {
    if (createdAt == null) return 'Just now';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
