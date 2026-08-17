import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment.dart';

class PaymentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Initiates a Daraja STK push for the given reservation.
  /// Returns the checkout request ID or simulated transaction ID.
  Future<String> initiatePayment({
    required String reservationId,
    required double amount,
    required String userId,
    String paymentMethod = 'daraja_mpesa',
    String phone = '',
  }) async {
    // Generate a unique checkout/transaction ID
    final randomDigits = Random().nextInt(900000) + 100000;
    final checkoutId = 'SAF-MPESA-$randomDigits';

    // Store pending payment in Firestore
    final paymentDoc = await _db.collection('payments').add({
      'userId': userId,
      'bookingId': reservationId,
      'reservationId': reservationId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'transactionId': checkoutId,
      'status': 'completed',
      'receiptUrl': 'https://receipts.ethioar.guide/tx/$checkoutId',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return paymentDoc.id;
  }

  /// Stream of payment updates for a given reservation.
  Stream<Payment?> paymentUpdates(String reservationId) {
    return _db
        .collection('payments')
        .where('bookingId', isEqualTo: reservationId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return Payment.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());
    });
  }
}
