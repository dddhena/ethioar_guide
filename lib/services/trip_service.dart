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
  }) async {
    final doc = await _trips(touristId).add({
      'touristId': touristId,
      'name': name.trim(),
      'country': country,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'placeIds': <String>[],
      'status': 'planning',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
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
  }) async {
    await _trips(touristId).doc(tripId).update({
      'placeIds': FieldValue.arrayUnion([placeId]),
    });
  }

  Future<void> markCompleted(String touristId, String tripId) async {
    await _trips(touristId).doc(tripId).update({'status': 'completed'});
  }
}
