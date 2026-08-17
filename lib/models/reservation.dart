import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  final String id; // reservationId
  final String touristId;
  final String providerId;
  final String serviceId;
  final String serviceType;
  final DateTime checkInDate;
  final DateTime? checkOutDate;
  final int numberOfGuests;
  final double totalAmount;
  final String status; // e.g., 'pending', 'confirmed', 'completed', 'cancelled'
  final DateTime? createdAt;
  final String paymentId; // reference to Payment document
  // Optional UI fields (populated lazily)
  final String serviceName;
  final String providerName;
  final String touristName;
  final String touristPhone;
  final String touristEmail;
  final String specialRequests;

  Reservation({
    required this.id,
    required this.touristId,
    required this.providerId,
    required this.serviceId,
    required this.serviceType,
    required this.checkInDate,
    this.checkOutDate,
    this.numberOfGuests = 1,
    this.totalAmount = 0.0,
    this.status = 'pending',
    this.createdAt,
    this.paymentId = '',
    this.serviceName = '',
    this.providerName = '',
    this.touristName = '',
    this.touristPhone = '',
    this.touristEmail = '',
    this.specialRequests = '',
  });

  factory Reservation.fromMap(String id, Map<String, dynamic> map) {
    DateTime parse(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }
    return Reservation(
      id: id,
      touristId: map['touristId'] as String? ?? '',
      providerId: map['providerId'] as String? ?? '',
      serviceId: map['serviceId'] as String? ?? '',
      serviceType: map['serviceType'] as String? ?? '',
      checkInDate: parse(map['checkInDate']),
      checkOutDate: map['checkOutDate'] != null ? parse(map['checkOutDate']) : null,
      numberOfGuests: (map['numberOfGuests'] ?? 1) as int,
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      status: map['status'] as String? ?? 'pending',
      createdAt: map['createdAt'] != null ? parse(map['createdAt']) : null,
      paymentId: map['paymentId'] as String? ?? '',
      // optional UI fields
      serviceName: (map['serviceName'] as String?) ?? '',
      providerName: (map['providerName'] as String?) ?? '',
      touristName: (map['touristName'] as String?) ?? '',
      touristPhone: (map['touristPhone'] as String?) ?? '',
      touristEmail: (map['touristEmail'] as String?) ?? '',
      specialRequests: (map['specialRequests'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'touristId': touristId,
      'providerId': providerId,
      'serviceId': serviceId,
      'serviceType': serviceType,
      'checkInDate': Timestamp.fromDate(checkInDate),
      'checkOutDate': checkOutDate != null ? Timestamp.fromDate(checkOutDate!) : null,
      'numberOfGuests': numberOfGuests,
      'totalAmount': totalAmount,
      'status': status,
      'paymentId': paymentId,
      // optional UI fields
      'serviceName': serviceName,
      'providerName': providerName,
      'touristName': touristName,
      'touristPhone': touristPhone,
      'touristEmail': touristEmail,
      'specialRequests': specialRequests,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // UI helper getters
  String get formattedDates {
    final checkIn = '${checkInDate.day}/${checkInDate.month}/${checkInDate.year}';
    if (checkOutDate != null) {
      final checkOut = '${checkOutDate!.day}/${checkOutDate!.month}/${checkOutDate!.year}';
      return '$checkIn - $checkOut';
    }
    return checkIn;
  }

  String get formattedTotal {
    return '\$${totalAmount.toStringAsFixed(2)}';
  }

  bool get isPending {
    return status == 'pending';
  }

  bool get isConfirmed {
    return status == 'confirmed';
  }

  bool get isDeclined {
    return status == 'declined';
  }
}
