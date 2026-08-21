import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment.dart';
import '../services/notification_service.dart';
import '../services/trip_service.dart';

class PaymentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String generateTransactionReference(String paymentMethod) {
    final randomDigits = Random().nextInt(900000) + 100000;
    switch (paymentMethod.toLowerCase()) {
      case 'telebirr':
        return 'TB-$randomDigits';
      case 'cbe_birr':
      case 'cbebirr':
        return 'CBE-$randomDigits';
      case 'daraja_mpesa':
      case 'mpesa':
        return 'SAF-MPESA-$randomDigits';
      case 'card':
        return 'CARD-$randomDigits';
      default:
        return 'TX-$randomDigits';
    }
  }

  /// Creates a payment for tourism place entrance fees submitted by a tourist.
  /// Sets status to 'pending' for admin verification.
  Future<String> createEntrancePayment({
    required String userId,
    required double amount,
    required String paymentMethod,
    required String tripId,
    String landmarkId = '',
    required String title,
    String payerName = '',
    String payerPhone = '',
    String transactionId = '',
    String receiptUrl = '',
  }) async {
    final txId = transactionId.trim().isNotEmpty
        ? transactionId.trim()
        : generateTransactionReference(paymentMethod);

    final paymentDoc = await _db.collection('payments').add({
      'userId': userId,
      'bookingId': tripId,
      'tripId': tripId,
      'landmarkId': landmarkId,
      'title': title,
      'payerName': payerName,
      'payerPhone': payerPhone,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'transactionId': txId,
      'status': 'pending', // Starts pending for Admin verification
      'paymentType': 'entrance_fee',
      'receiptUrl': receiptUrl.isNotEmpty ? receiptUrl : 'https://receipts.ethioar.guide/tx/$txId',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Also update the trip entrance payment status to pending and link paymentId
    if (tripId.isNotEmpty && userId.isNotEmpty) {
      await TripService().updateTripEntrancePayment(
        touristId: userId,
        tripId: tripId,
        status: 'pending',
        paymentId: paymentDoc.id,
      );
    }

    return paymentDoc.id;
  }

  /// Admin verifies or rejects an entrance fee payment.
  Future<void> verifyPayment({
    required String paymentId,
    required String adminUid,
    required bool approved,
    String? adminNotes,
    String? tripId,
    String? touristId,
    String? title,
  }) async {
    final status = approved ? 'verified' : 'rejected';
    final now = DateTime.now();

    await _db.collection('payments').doc(paymentId).update({
      'status': status,
      'verifiedBy': adminUid,
      'verifiedAt': Timestamp.fromDate(now),
      if (adminNotes != null) 'adminNotes': adminNotes.trim(),
    });

    // Update associated trip if applicable
    if (touristId != null && touristId.isNotEmpty && tripId != null && tripId.isNotEmpty) {
      await TripService().updateTripEntrancePayment(
        touristId: touristId,
        tripId: tripId,
        status: status,
        paymentId: paymentId,
      );
    }

    // Send notification to tourist
    if (touristId != null && touristId.isNotEmpty) {
      final tripName = (title != null && title.isNotEmpty) ? title : 'your trip entrance fee';
      if (approved) {
        await NotificationService().sendNotification(
          userId: touristId,
          title: 'Entrance Payment Verified! 🎉',
          message: 'Your entrance fee payment for $tripName has been verified by the administrator. Enjoy your visit!',
          type: 'payment_success',
          relatedId: paymentId,
        );
      } else {
        await NotificationService().sendNotification(
          userId: touristId,
          title: 'Entrance Payment Not Verified',
          message: 'Your entrance payment for $tripName was not verified.${adminNotes != null && adminNotes.isNotEmpty ? " Reason: $adminNotes" : " Please check your transaction details and resubmit."}',
          type: 'payment_declined',
          relatedId: paymentId,
        );
      }
    }
  }

  /// Initiates a Daraja STK push for the given reservation.
  /// Returns the checkout request ID or simulated transaction ID.
  Future<String> initiatePayment({
    required String reservationId,
    required double amount,
    required String userId,
    String paymentMethod = 'daraja_mpesa',
    String phone = '',
  }) async {
    final checkoutId = generateTransactionReference(paymentMethod);

    final paymentDoc = await _db.collection('payments').add({
      'userId': userId,
      'bookingId': reservationId,
      'reservationId': reservationId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'transactionId': checkoutId,
      'status': 'completed',
      'paymentType': 'provider_service',
      'receiptUrl': 'https://receipts.ethioar.guide/tx/$checkoutId',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return paymentDoc.id;
  }

  /// Stream of entrance fee payments for admin verification.
  Stream<List<Payment>> getEntrancePaymentsStream({String? statusFilter}) {
    Query<Map<String, dynamic>> query = _db.collection('payments');
    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((d) => Payment.fromMap(d.id, d.data()))
          .where((p) => p.paymentType == 'entrance_fee' || p.tripId.isNotEmpty)
          .toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }

  /// Stream of all payments (for admin overview).
  Stream<List<Payment>> getAllPaymentsStream({String? statusFilter}) {
    Query<Map<String, dynamic>> query = _db.collection('payments');
    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((d) => Payment.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }

  /// Stream of payment updates for a given reservation or trip.
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
