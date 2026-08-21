import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final String userId;
  final String bookingId;
  final String providerId;
  final double amount;
  final String paymentMethod; // 'daraja_mpesa', 'telebirr', 'cbe_birr', 'card'
  final String transactionId;
  final String status; // 'completed', 'pending', 'verified', 'rejected', 'failed'
  final String receiptUrl;
  final String paymentType; // 'entrance_fee', 'provider_service', 'tour_guide'
  final String tripId;
  final String landmarkId;
  final String title;
  final String payerName;
  final String payerPhone;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? adminNotes;
  final DateTime? createdAt;

  Payment({
    required this.id,
    this.userId = '',
    this.bookingId = '',
    this.providerId = '',
    this.amount = 0.0,
    this.paymentMethod = 'daraja_mpesa',
    this.transactionId = '',
    this.status = 'completed',
    this.receiptUrl = '',
    this.paymentType = 'provider_service',
    this.tripId = '',
    this.landmarkId = '',
    this.title = '',
    this.payerName = '',
    this.payerPhone = '',
    this.verifiedBy,
    this.verifiedAt,
    this.adminNotes,
    this.createdAt,
  });

  // Backward compatibility getter
  String get reservationId => bookingId;

  bool get isPending => status == 'pending';
  bool get isVerified => status == 'verified' || status == 'completed';
  bool get isRejected => status == 'rejected';
  bool get isEntranceFee => paymentType == 'entrance_fee';

  factory Payment.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return Payment(
      id: id,
      userId: map['userId'] as String? ?? '',
      bookingId: (map['bookingId'] ?? map['reservationId']) as String? ?? '',
      providerId: map['providerId'] as String? ?? '',
      amount: ((map['amount'] ?? 0) as num).toDouble(),
      paymentMethod: map['paymentMethod'] as String? ?? 'daraja_mpesa',
      transactionId: map['transactionId'] as String? ?? '',
      status: map['status'] as String? ?? 'completed',
      receiptUrl: map['receiptUrl'] as String? ?? '',
      paymentType: map['paymentType'] as String? ?? (map['tripId'] != null && (map['tripId'] as String).isNotEmpty ? 'entrance_fee' : 'provider_service'),
      tripId: map['tripId'] as String? ?? '',
      landmarkId: map['landmarkId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      payerName: map['payerName'] as String? ?? '',
      payerPhone: map['payerPhone'] as String? ?? '',
      verifiedBy: map['verifiedBy'] as String?,
      verifiedAt: parseDate(map['verifiedAt']),
      adminNotes: map['adminNotes'] as String?,
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bookingId': bookingId,
      'reservationId': bookingId,
      'providerId': providerId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'status': status,
      'receiptUrl': receiptUrl,
      'paymentType': paymentType,
      'tripId': tripId,
      'landmarkId': landmarkId,
      'title': title,
      'payerName': payerName,
      'payerPhone': payerPhone,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'adminNotes': adminNotes,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Payment copyWith({
    String? status,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? adminNotes,
    String? receiptUrl,
  }) {
    return Payment(
      id: id,
      userId: userId,
      bookingId: bookingId,
      providerId: providerId,
      amount: amount,
      paymentMethod: paymentMethod,
      transactionId: transactionId,
      status: status ?? this.status,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      paymentType: paymentType,
      tripId: tripId,
      landmarkId: landmarkId,
      title: title,
      payerName: payerName,
      payerPhone: payerPhone,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt,
    );
  }

  String get formattedMethod {
    switch (paymentMethod.toLowerCase()) {
      case 'daraja_mpesa':
      case 'mpesa':
      case 'daraja':
        return 'Safaricom M-Pesa';
      case 'telebirr':
        return 'Telebirr';
      case 'cbe_birr':
      case 'cbebirr':
        return 'CBE Birr';
      case 'card':
        return 'Card Payment';
      case 'bank':
        return 'Bank Transfer';
      default:
        return paymentMethod.toUpperCase();
    }
  }

  String get formattedAmount => '${amount.toStringAsFixed(2)} ETB';
}

