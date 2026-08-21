import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip.dart';

class TripService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _trips(String touristId) =>
      _db.collection('users').doc(touristId).collection('trips');

  Future<String> createTrip({
    required String touristId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String country = 'Ethiopia',
    List<String> placeIds = const [],
    double entranceFeeTotal = 0.0,
    String entrancePaymentStatus = 'unpaid',
    String? entrancePaymentId,
  }) async {
    final doc = await _trips(touristId).add({
      'touristId': touristId,
      'name': name.trim(),
      'country': country,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'placeIds': placeIds,
      'status': 'planning',
      'entranceFeeTotal': entranceFeeTotal,
      'entrancePaymentStatus': entrancePaymentStatus,
      'entrancePaymentId': entrancePaymentId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<TouristTrip?> getTrip(String touristId, String tripId) async {
    try {
      final doc = await _trips(touristId).doc(tripId).get();
      if (!doc.exists || doc.data() == null) return null;
      return TouristTrip.fromMap(doc.id, doc.data()!);
    } catch (e) {
      return null;
    }
  }

  Future<List<TouristTrip>> getTrips(String touristId) async {
    try {
      final snapshot = await _trips(touristId).orderBy('startDate', descending: false).get();
      return snapshot.docs.map((d) => TouristTrip.fromMap(d.id, d.data())).toList();
    } catch (e) {
      print('Error fetching trips: $e');
      return [];
    }
  }

  Stream<List<TouristTrip>> getTripsStream(String touristId) {
    return _trips(touristId).orderBy('startDate', descending: false).snapshots().map(
          (snapshot) => snapshot.docs.map((d) => TouristTrip.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> addPlaceToTrip({
    required String touristId,
    required String tripId,
    required String placeId,
    double? newEntranceFeeTotal,
  }) async {
    final Map<String, dynamic> updates = {
      'placeIds': FieldValue.arrayUnion([placeId]),
    };
    if (newEntranceFeeTotal != null) {
      updates['entranceFeeTotal'] = newEntranceFeeTotal;
    }
    await _trips(touristId).doc(tripId).update(updates);
  }

  Future<void> removePlaceFromTrip({
    required String touristId,
    required String tripId,
    required String placeId,
    double? newEntranceFeeTotal,
  }) async {
    final Map<String, dynamic> updates = {
      'placeIds': FieldValue.arrayRemove([placeId]),
    };
    if (newEntranceFeeTotal != null) {
      updates['entranceFeeTotal'] = newEntranceFeeTotal;
    }
    await _trips(touristId).doc(tripId).update(updates);
  }

  Future<void> updateTripEntrancePayment({
    required String touristId,
    required String tripId,
    required String status,
    String? paymentId,
    double? entranceFeeTotal,
  }) async {
    final Map<String, dynamic> data = {
      'entrancePaymentStatus': status,
    };
    if (paymentId != null) {
      data['entrancePaymentId'] = paymentId;
    }
    if (entranceFeeTotal != null) {
      data['entranceFeeTotal'] = entranceFeeTotal;
    }
    await _trips(touristId).doc(tripId).update(data);
  }

  Future<void> markCompleted(String touristId, String tripId) async {
    await _trips(touristId).doc(tripId).update({'status': 'completed'});
  }
}
