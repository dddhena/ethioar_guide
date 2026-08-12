import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firestore_service.dart';

class AuthService {
  FirebaseAuth? _auth;

  FirebaseAuth? get _firebaseAuth {
    // Don't attempt to access FirebaseAuth if Firebase isn't initialized.
    // Firebase.apps is populated after Firebase.initializeApp().
    try {
      if (Firebase.apps.isEmpty) return null;
    } catch (_) {
      // If firebase_core isn't available for some reason, treat as not initialized.
      return null;
    }
    _auth ??= FirebaseAuth.instance;
    return _auth;
  }

  Future<User?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final auth = _firebaseAuth;
    if (auth == null) {
      // Running in web/offline mode or Firebase not configured.
      return null;
    }

    final cred = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user;
    if (user != null) {
      await user.updateDisplayName(name);
      // default role is 'user' on registration
      await FirestoreService().createUserProfile(user.uid, name, email, role: 'user');
    }
    return user;
  }

  Future<User?> login({required String email, required String password}) async {
    final auth = _firebaseAuth;
    if (auth == null) return null;
    final cred = await auth.signInWithEmailAndPassword(email: email, password: password);
    return cred.user;
  }

  Future<void> signOut() async {
    final auth = _firebaseAuth;
    if (auth == null) return;
    await auth.signOut();
  }

  User? get currentUser => _firebaseAuth?.currentUser;
}
