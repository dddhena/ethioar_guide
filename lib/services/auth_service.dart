import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
    String role = 'tourist',
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
      await FirestoreService().createUserProfile(user.uid, name, email, role: role);
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

  /// Update the current user's display name in Firebase Auth.
  Future<void> updateDisplayName(String name) async {
    final user = _firebaseAuth?.currentUser;
    if (user != null) {
      await user.updateDisplayName(name.trim());
      await user.reload();
    }
  }

  /// Change password for currently signed in user, re-authenticating first.
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth?.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No user is currently signed in.',
      );
    }

    // Re-authenticate user before updating sensitive credentials
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }

  /// Send password reset link to user's email
  Future<void> sendPasswordResetEmail(String email) async {
    final auth = _firebaseAuth;
    if (auth == null) return;
    await auth.sendPasswordResetEmail(email: email.trim());
  }

  User? get currentUser => _firebaseAuth?.currentUser;

  Stream<User?> get authStateChanges =>
      _firebaseAuth?.authStateChanges() ?? const Stream.empty();
}
