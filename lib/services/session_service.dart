import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

enum SessionStatus {
  active,
  expired,
  unauthenticated,
}

/// Service managing user authentication sessions, automatic expiration,
/// and unified logout behavior across EthioAR Guide.
class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  static const String _keyLoginTime = 'ethio_session_login_time';
  static const String _keyLastActive = 'ethio_session_last_active';
  static const String _keyUid = 'ethio_session_uid';

  /// Session validity duration: 7 days of inactivity before expiration
  static const Duration defaultSessionDuration = Duration(days: 7);

  /// Call whenever a user successfully logs in or registers
  Future<void> recordLogin(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_keyLoginTime, now);
    await prefs.setInt(_keyLastActive, now);
    await prefs.setString(_keyUid, uid);
  }

  /// Update the last activity timestamp to keep active session alive
  Future<void> touchActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastActive, DateTime.now().millisecondsSinceEpoch);
  }

  /// Check whether the current session is valid, expired, or unauthenticated
  Future<SessionStatus> checkSessionStatus() async {
    final auth = AuthService();
    final user = auth.currentUser;
    if (user == null) {
      return SessionStatus.unauthenticated;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastActive = prefs.getInt(_keyLastActive);

    // If user is logged in in Firebase but no local timestamp, establish session now
    if (lastActive == null) {
      await recordLogin(user.uid);
      return SessionStatus.active;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final diffMs = now - lastActive;

    if (diffMs > defaultSessionDuration.inMilliseconds) {
      // Session has expired
      return SessionStatus.expired;
    }

    // Still valid, keep alive
    await touchActivity();
    return SessionStatus.active;
  }

  /// Unified logout method for the entire application.
  /// Handles Firebase sign-out, session cleanup, and redirects cleanly
  /// to the first welcome landing page.
  Future<void> logout(BuildContext context, {String? reason}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoginTime);
    await prefs.remove(_keyLastActive);
    await prefs.remove(_keyUid);

    await AuthService().signOut();

    if (!context.mounted) return;

    // Reset navigation stack to root welcome screen
    Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);

    if (reason != null && reason.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reason),
          backgroundColor: const Color(0xFF5E4534), // EthioColors.earth
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
