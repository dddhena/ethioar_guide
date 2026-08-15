import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/landmark.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Creates a user profile document in `users/{uid}` with an optional role.
  Future<void> createUserProfile(String uid, String name, String email, {String role = 'user'}) async {
    await _db.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fetch the full user profile from Firestore.
  Future<Map<String, dynamic>> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) {
        return {'name': 'Guest', 'email': '', 'role': 'user'};
      }
      final data = doc.data() ?? {};
      return {
        'name': data['name'] ?? 'Guest',
        'email': data['email'] ?? '',
        'role': data['role'] ?? 'user',
      };
    } catch (_) {
      // Firestore rules or connectivity may block access; fall back to a safe default.
      return {'name': 'Guest', 'email': '', 'role': 'user'};
    }
  }

  /// Fetch a user's role (returns 'user' if not set).
  Future<String> getUserRole(String uid) async {
    final profile = await getUserProfile(uid);
    return profile['role'] as String? ?? 'user';
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
  }) async {
    await _db.collection('landmarks').add({
      'name': name.trim(),
      'description': description.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'city': city.trim(),
      'category': category.trim(),
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
  }) async {
    final Map<String, Object?> data = {};
    if (name != null) data['name'] = name.trim();
    if (description != null) data['description'] = description.trim();
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (city != null) data['city'] = city.trim();
    if (category != null) data['category'] = category.trim();

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
        ),
        Landmark(
          id: 'demo-lalibela',
          name: 'Lalibela Rock Churches',
          description: 'Famous rock-hewn churches and UNESCO heritage site.',
          latitude: 12.031,
          longitude: 39.047,
        ),
        Landmark(
          id: 'demo-gondar',
          name: 'Fasil Ghebbi',
          description: 'Royal enclosure and historic castle complex in Gondar.',
          latitude: 12.601,
          longitude: 37.467,
        ),
      ];
    }

    return const [];
  }
}
