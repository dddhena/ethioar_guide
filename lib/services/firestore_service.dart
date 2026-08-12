import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/landmark.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Creates a user profile document in `users/{uid}` with an optional role.
  Future<void> createUserProfile(String uid, String name, String email, {String role = 'user'}) async {
    if (kIsWeb) return; // Skip on web when Firebase isn't configured
    await _db.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fetch a user's role (returns 'user' if not set).
  Future<String> getUserRole(String uid) async {
    if (kIsWeb) return 'user';
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return 'user';
    final data = doc.data();
    if (data == null) return 'user';
    return (data['role'] as String?) ?? 'user';
  }

  /// List all users (admin helper).
  Future<List<Map<String, dynamic>>> listUsers() async {
    if (kIsWeb) return [];
    final snapshot = await _db.collection('users').get();
    return snapshot.docs.map((d) {
      final m = d.data();
      m['uid'] = d.id;
      return m;
    }).toList();
  }

  /// Promote or demote a user by setting their role.
  Future<void> setUserRole(String uid, String role) async {
    if (kIsWeb) return;
    await _db.collection('users').doc(uid).update({'role': role});
  }

  Future<List<Landmark>> fetchLandmarks() async {
    if (kIsWeb) {
      // Return sample landmarks for web mode when Firestore may be unavailable
      return [
        Landmark(id: '1', name: 'Aksum Obelisk', description: 'Ancient obelisk in Aksum', latitude: 14.127, longitude: 38.719),
        Landmark(id: '2', name: 'Lalibela Rock Churches', description: 'Famous rock-hewn churches', latitude: 12.031, longitude: 39.047),
      ];
    }

    final snapshot = await _db.collection('landmarks').get();
    return snapshot.docs.map((d) => Landmark.fromMap(d.id, d.data())).toList();
  }
}
