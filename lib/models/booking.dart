import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String touristId;
  final String guideId;
  final String tourId;
  final DateTime bookingDate;
  final DateTime tourDate;
  final int numberOfParticipants;
  final double totalAmount;
  final String status; // pending / confirmed / completed / cancelled
  final DateTime? createdAt;
  final String touristName;
  final String touristEmail;
  final String touristPhone;
  final String guideName;
  final String tourName;
  final String notes;

  Booking({
    required this.id,
    required this.touristId,
    required this.guideId,
    required this.tourId,
    required this.bookingDate,
    required this.tourDate,
    this.numberOfParticipants = 1,
    this.totalAmount = 0,
    this.status = 'pending',
    this.createdAt,
    this.touristName = '',
    this.touristEmail = '',
    this.touristPhone = '',
    this.guideName = '',
    this.tourName = '',
    this.notes = '',
  });

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String get formattedTotal => '${totalAmount.toStringAsFixed(0)} ETB';

  String get formattedTourDate =>
      '${tourDate.day}/${tourDate.month}/${tourDate.year}';

  factory Booking.fromMap(String id, Map<String, dynamic> map) {
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

    return Booking(
      id: id,
      touristId: map['touristId'] as String? ?? '',
      guideId: map['guideId'] as String? ?? '',
      tourId: map['tourId'] as String? ?? '',
      bookingDate: parse(map['bookingDate']),
      tourDate: parse(map['tourDate']),
      numberOfParticipants: ((map['numberOfParticipants'] ?? 1) as num).toInt(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      status: map['status'] as String? ?? 'pending',
      createdAt: parseNullable(map['createdAt']),
      touristName: map['touristName'] as String? ?? '',
      touristEmail: map['touristEmail'] as String? ?? '',
      touristPhone: map['touristPhone'] as String? ?? '',
      guideName: map['guideName'] as String? ?? '',
      tourName: map['tourName'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'touristId': touristId,
      'guideId': guideId,
      'tourId': tourId,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'tourDate': Timestamp.fromDate(tourDate),
      'numberOfParticipants': numberOfParticipants,
      'totalAmount': totalAmount,
      'status': status,
      'touristName': touristName,
      'touristEmail': touristEmail,
      'touristPhone': touristPhone,
      'guideName': guideName,
      'tourName': tourName,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
