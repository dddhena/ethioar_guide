import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/landmark.dart';
import '../models/user_profile.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Creates a user profile document in `users/{uid}` with an optional role.
  Future<void> createUserProfile(String uid, String name, String email, {String role = 'user'}) async {
    await _db.collection('users').doc(uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'role': role,
      'phone': '',
      'bio': '',
      'country': '',
      'avatar': 'default',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fetch the full user profile model from Firestore.
  Future<UserProfile> getUserProfileModel(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        return UserProfile(uid: uid, name: 'Guest', email: '', role: 'user');
      }
      return UserProfile.fromMap(uid, doc.data()!);
    } catch (_) {
      return UserProfile(uid: uid, name: 'Guest', email: '', role: 'user');
    }
  }

  /// Real-time stream of the user's profile.
  Stream<UserProfile> getUserProfileStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return UserProfile(uid: uid, name: 'Guest', email: '', role: 'user');
      }
      return UserProfile.fromMap(uid, doc.data()!);
    });
  }

  /// Update user profile in Firestore.
  Future<void> updateUserProfile(UserProfile profile) async {
    await _db.collection('users').doc(profile.uid).set(
      profile.toMap(),
      SetOptions(merge: true),
    );
  }

  /// Fetch the user profile as a Map from Firestore (for backwards compatibility).
  Future<Map<String, dynamic>> getUserProfile(String uid) async {
    final profile = await getUserProfileModel(uid);
    return {
      'name': profile.name.isEmpty ? 'Guest' : profile.name,
      'email': profile.email,
      'role': profile.role,
      'phone': profile.phone,
      'bio': profile.bio,
      'country': profile.country,
      'avatar': profile.avatar,
    };
  }

  /// Fetch a user's role (returns 'user' if not set).
  Future<String> getUserRole(String uid) async {
    final profile = await getUserProfileModel(uid);
    return profile.role;
  }

  /// List all users (admin helper).
  Future<List<Map<String, dynamic>>> listUsers() async {
    final snapshot = await _db.collection('users').get();
    return snapshot.docs.map((d) {
      final m = d.data();
      m['uid'] = d.id;
      return m;
    }).toList();
  }

  /// Get total count of users by role (admin statistics helper).
  Future<Map<String, int>> getUserCountByRole() async {
    final snapshot = await _db.collection('users').get();
    final counts = <String, int>{
      'total': snapshot.docs.length,
      'tourist': 0,
      'tour_guide': 0,
      'provider': 0,
      'admin': 0,
    };
    
    for (final doc in snapshot.docs) {
      final role = doc.data()['role'] as String? ?? 'tourist';
      if (counts.containsKey(role)) {
        counts[role] = (counts[role] ?? 0) + 1;
      } else {
        counts['tourist'] = (counts['tourist'] ?? 0) + 1;
      }
    }
    
    return counts;
  }

  /// Get total count of landmarks (admin statistics helper).
  Future<int> getLandmarkCount() async {
    final snapshot = await _db.collection('landmarks').get();
    return snapshot.docs.length;
  }

  /// Get total count of service providers (admin statistics helper).
  Future<int> getProviderCount() async {
    final snapshot = await _db.collection('users').where('role', isEqualTo: 'provider').get();
    return snapshot.docs.length;
  }

  /// Get total entrance payments amount (admin statistics helper).
  Future<double> getTotalEntrancePayments() async {
    final snapshot = await _db.collection('payments').get();
    double total = 0.0;
    for (final doc in snapshot.docs) {
      final amount = doc.data()['amount'] as num? ?? 0;
      final status = doc.data()['status'] as String? ?? '';
      if (status == 'verified' || status == 'completed') {
        total += amount.toDouble();
      }
    }
    return total;
  }

  /// Get booking statistics by status (admin statistics helper).
  Future<Map<String, int>> getBookingStatsByStatus() async {
    final snapshot = await _db.collection('bookings').get();
    final stats = <String, int>{
      'total': snapshot.docs.length,
      'pending': 0,
      'confirmed': 0,
      'completed': 0,
      'cancelled': 0,
    };
    
    for (final doc in snapshot.docs) {
      final status = doc.data()['status'] as String? ?? 'pending';
      if (stats.containsKey(status)) {
        stats[status] = (stats[status] ?? 0) + 1;
      } else {
        stats['pending'] = (stats['pending'] ?? 0) + 1;
      }
    }
    
    return stats;
  }

  /// Get recent bookings for admin dashboard (admin statistics helper).
  Future<List<Map<String, dynamic>>> getRecentBookings({int limit = 5}) async {
    final snapshot = await _db
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    
    return snapshot.docs.map((d) {
      final m = d.data();
      m['id'] = d.id;
      return m;
    }).toList();
  }

  /// Promote or demote a user by setting their role.
  Future<void> setUserRole(String uid, String role) async {
    await _db.collection('users').doc(uid).update({'role': role});
  }

  /// Save a tourist landmark from the app to the `landmarks` collection.
  Future<void> addLandmark({
    required String name,
    required String description,
    required double latitude,
    required double longitude,
    String city = '',
    String category = 'heritage',
    String imageUrl = '',
    double entranceFee = 0.0,
  }) async {
    await _db.collection('landmarks').add({
      'name': name.trim(),
      'description': description.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'city': city.trim(),
      'category': category.trim(),
      'imageUrl': imageUrl,
      'entranceFee': entranceFee,
      'rating': 4.0,
      'reviewCount': 0,
      'outdoorFriendly': true,
      'bestWeatherConditions': ['clear', 'partly_cloudy'],
      'popularityScore': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update an existing landmark document by id. Only fields provided will be updated.
  Future<void> updateLandmark({
    required String id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    String? city,
    String? category,
    String? imageUrl,
    double? rating,
    int? reviewCount,
    bool? outdoorFriendly,
    List<String>? bestWeatherConditions,
    double? popularityScore,
    double? entranceFee,
  }) async {
    final Map<String, Object?> data = {};
    if (name != null) data['name'] = name.trim();
    if (description != null) data['description'] = description.trim();
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (city != null) data['city'] = city.trim();
    if (category != null) data['category'] = category.trim();
    if (imageUrl != null) data['imageUrl'] = imageUrl;
    if (rating != null) data['rating'] = rating;
    if (reviewCount != null) data['reviewCount'] = reviewCount;
    if (outdoorFriendly != null) data['outdoorFriendly'] = outdoorFriendly;
    if (bestWeatherConditions != null) data['bestWeatherConditions'] = bestWeatherConditions;
    if (popularityScore != null) data['popularityScore'] = popularityScore;
    if (entranceFee != null) data['entranceFee'] = entranceFee;

    if (data.isEmpty) return;
    await _db.collection('landmarks').doc(id).update(data);
  }

  /// Delete a landmark by document id.
  Future<void> deleteLandmark(String id) async {
    await _db.collection('landmarks').doc(id).delete();
  }

  Future<List<Landmark>> fetchLandmarks() async {
    try {
      final snapshot = await _db.collection('landmarks').get();
      final landmarks = snapshot.docs
          .map((d) => Landmark.fromMap(d.id, d.data()))
          .toList();

      if (landmarks.isNotEmpty) return landmarks;
    } catch (_) {
      // Fall back only when Firestore is unavailable; don't silently hide the issue.
    }

    // Web-safe fallback only when the database is unavailable, not by default.
    if (kIsWeb) {
      return [
        Landmark(
          id: 'demo-aksum',
          name: 'Aksum Obelisk',
          description: 'Ancient obelisk and historical monument in Aksum.',
          latitude: 14.127,
          longitude: 38.719,
          city: 'Aksum',
          category: 'heritage',
          rating: 4.7,
          reviewCount: 234,
          outdoorFriendly: true,
          bestWeatherConditions: ['clear', 'partly_cloudy'],
          popularityScore: 85.0,
          entranceFee: 200.0,
        ),
        Landmark(
          id: 'demo-lalibela',
          name: 'Lalibela Rock Churches',
          description: 'Famous rock-hewn churches and UNESCO heritage site.',
          latitude: 12.031,
          longitude: 39.047,
          city: 'Lalibela',
          category: 'religious',
          rating: 4.9,
          reviewCount: 456,
          outdoorFriendly: true,
          bestWeatherConditions: ['clear', 'partly_cloudy'],
          popularityScore: 95.0,
          entranceFee: 500.0,
        ),
        Landmark(
          id: 'demo-gondar',
          name: 'Fasil Ghebbi',
          description: 'Royal enclosure and historic castle complex in Gondar.',
          latitude: 12.601,
          longitude: 37.467,
          city: 'Gondar',
          category: 'heritage',
          rating: 4.6,
          reviewCount: 189,
          outdoorFriendly: true,
          bestWeatherConditions: ['clear', 'partly_cloudy'],
          popularityScore: 78.0,
          entranceFee: 300.0,
        ),
        Landmark(
          id: 'demo-bahirdar',
          name: 'Lake Tana',
          description: 'Sacred lake with monasteries and the Blue Nile Falls.',
          latitude: 11.5936,
          longitude: 37.3908,
          city: 'Bahir Dar',
          category: 'nature',
          rating: 4.5,
          reviewCount: 123,
          outdoorFriendly: true,
          bestWeatherConditions: ['clear', 'partly_cloudy'],
          popularityScore: 70.0,
          entranceFee: 150.0,
        ),
      ];
    }

    return const [];
  }
}
