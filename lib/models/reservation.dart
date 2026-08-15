import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  final String id;
  final String touristId;
  final String touristName;
  final String touristEmail;
  final String touristPhone;
  final String providerId;
  final String providerName;
  final String serviceId;
  final String serviceName;
  final String serviceType; // 'hotel', 'restaurant', 'transport'
  final DateTime checkInDate;
  final DateTime? checkOutDate;
  final int numberOfGuests;
  final double totalAmount;
  final String specialRequests;
  final String status; // 'pending', 'confirmed', 'declined', 'completed', 'cancelled'
  final DateTime? createdAt;

  Reservation({
    required this.id,
    required this.touristId,
    required this.touristName,
    required this.touristEmail,
    this.touristPhone = '',
    required this.providerId,
    required this.providerName,
    required this.serviceId,
    required this.serviceName,
    required this.serviceType,
    required this.checkInDate,
    this.checkOutDate,
    this.numberOfGuests = 1,
    this.totalAmount = 0.0,
    this.specialRequests = '',
    this.status = 'pending',
    this.createdAt,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isConfirmed => status.toLowerCase() == 'confirmed';
  bool get isDeclined => status.toLowerCase() == 'declined';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  String get formattedTotal => '${totalAmount.toStringAsFixed(0)} ETB';

  String get formattedDates {
    final start = '${checkInDate.day}/${checkInDate.month}/${checkInDate.year}';
    if (checkOutDate != null) {
      final end = '${checkOutDate!.day}/${checkOutDate!.month}/${checkOutDate!.year}';
      return '$start ➔ $end';
    }
    return start;
  }

  factory Reservation.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic val, [DateTime? fallback]) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? (fallback ?? DateTime.now());
      return fallback ?? DateTime.now();
    }

    return Reservation(
      id: id,
      touristId: map['touristId'] as String? ?? '',
      touristName: map['touristName'] as String? ?? 'Tourist',
      touristEmail: map['touristEmail'] as String? ?? '',
      touristPhone: map['touristPhone'] as String? ?? '',
      providerId: map['providerId'] as String? ?? '',
      providerName: map['providerName'] as String? ?? 'Provider',
      serviceId: map['serviceId'] as String? ?? '',
      serviceName: map['serviceName'] as String? ?? 'Service',
      serviceType: map['serviceType'] as String? ?? 'hotel',
      checkInDate: parseDate(map['checkInDate']),
      checkOutDate: map['checkOutDate'] != null ? parseDate(map['checkOutDate']) : null,
      numberOfGuests: (map['numberOfGuests'] ?? 1) as int,
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      specialRequests: map['specialRequests'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: map['createdAt'] != null ? parseDate(map['createdAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'touristId': touristId,
      'touristName': touristName.trim(),
      'touristEmail': touristEmail.trim(),
      'touristPhone': touristPhone.trim(),
      'providerId': providerId,
      'providerName': providerName.trim(),
      'serviceId': serviceId,
      'serviceName': serviceName.trim(),
      'serviceType': serviceType,
      'checkInDate': Timestamp.fromDate(checkInDate),
      'checkOutDate': checkOutDate != null ? Timestamp.fromDate(checkOutDate!) : null,
      'numberOfGuests': numberOfGuests,
      'totalAmount': totalAmount,
      'specialRequests': specialRequests.trim(),
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Reservation copyWith({
    String? id,
    String? touristId,
    String? touristName,
    String? touristEmail,
    String? touristPhone,
    String? providerId,
    String? providerName,
    String? serviceId,
    String? serviceName,
    String? serviceType,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? numberOfGuests,
    double? totalAmount,
    String? specialRequests,
    String? status,
    DateTime? createdAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      touristId: touristId ?? this.touristId,
      touristName: touristName ?? this.touristName,
      touristEmail: touristEmail ?? this.touristEmail,
      touristPhone: touristPhone ?? this.touristPhone,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      serviceType: serviceType ?? this.serviceType,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      numberOfGuests: numberOfGuests ?? this.numberOfGuests,
      totalAmount: totalAmount ?? this.totalAmount,
      specialRequests: specialRequests ?? this.specialRequests,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
