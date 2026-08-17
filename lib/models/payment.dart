import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final String userId;
  final String bookingId;
  final String providerId;
  final double amount;
  final String paymentMethod; // 'daraja_mpesa', 'telebirr', 'cbe_birr', 'card'
  final String transactionId;
  final String status; // 'completed', 'pending', 'failed'
  final String receiptUrl;
  final DateTime? createdAt;

  Payment({
    required this.id,
    this.userId = '',
    required this.bookingId,
    this.providerId = '',
    this.amount = 0.0,
    this.paymentMethod = 'daraja_mpesa',
    this.transactionId = '',
    this.status = 'completed',
    this.receiptUrl = '',
    this.createdAt,
  });

  // Backward compatibility getter
  String get reservationId => bookingId;

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
      amount: (map['amount'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] as String? ?? 'daraja_mpesa',
      transactionId: map['transactionId'] as String? ?? '',
      status: map['status'] as String? ?? 'completed',
      receiptUrl: map['receiptUrl'] as String? ?? '',
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
      'createdAt': FieldValue.serverTimestamp(),
    };
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
      default:
        return paymentMethod.toUpperCase();
    }
  }

  String get formattedAmount => '${amount.toStringAsFixed(2)} ETB';
}
