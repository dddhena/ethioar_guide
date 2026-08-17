import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emergency_alert.dart';
import 'notification_service.dart';

class EmergencyService {
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Trigger emergency SOS broadcast from tourist to all Admins
  Future<String> triggerEmergency({
    required String touristId,
    required String touristName,
    String touristPhone = '',
    String touristEmail = '',
    required double latitude,
    required double longitude,
    String locationName = 'Ethiopia',
    required String emergencyType,
    required String message,
  }) async {
    final docRef = _db.collection('emergencies').doc();

    final alert = EmergencyAlert(
      id: docRef.id,
      touristId: touristId,
      touristName: touristName,
      touristPhone: touristPhone,
      touristEmail: touristEmail,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      emergencyType: emergencyType,
      message: message,
      status: 'active',
      createdAt: DateTime.now(),
    );

    await docRef.set(alert.toMap());

    // Broadcast to all Admin users in Firestore
    try {
      final adminUsers = await _db
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      for (final doc in adminUsers.docs) {
        await NotificationService().sendNotification(
          userId: doc.id,
          title: '🚨 CRITICAL EMERGENCY SOS: $touristName',
          message: '${alert.typeLabel} reported at ($latitude, $longitude): "$message". Immediate action required.',
          type: 'emergency_sos',
          relatedId: docRef.id,
        );
      }
    } catch (_) {}

    // Trigger local background sound & system notification
    showSystemBackgroundNotification(
      '🚨 EMERGENCY SOS ALERT: $touristName',
      '${alert.typeLabel}: $message (Location: $latitude, $longitude)',
    );

    return docRef.id;
  }

  /// Real-time stream of all active / recent emergency alerts for Admins
  Stream<List<EmergencyAlert>> getEmergenciesStream() {
    return _db.collection('emergencies').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => EmergencyAlert.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }

  /// Stream of active (unresolved) emergencies count for admin badge
  Stream<int> getActiveEmergencyCountStream() {
    return getEmergenciesStream().map(
      (list) => list.where((a) => a.isActive || a.isResponding).length,
    );
  }

  /// Admin updates emergency status
  Future<void> updateEmergencyStatus(
    String emergencyId,
    String status, {
    String? responderId,
    String? responderName,
  }) async {
    final updateData = <String, dynamic>{
      'status': status,
      'responderId': responderId,
      'responderName': responderName,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == 'resolved') {
      updateData['resolvedAt'] = FieldValue.serverTimestamp();
    }

    await _db.collection('emergencies').doc(emergencyId).update(updateData);

    // Notify the tourist about emergency status update
    try {
      final doc = await _db.collection('emergencies').doc(emergencyId).get();
      if (doc.exists && doc.data() != null) {
        final alert = EmergencyAlert.fromMap(doc.id, doc.data()!);
        if (alert.touristId.isNotEmpty) {
          final isResponding = status == 'responding';
          final isResolved = status == 'resolved';

          final title = isResponding
              ? '👮 Admin Emergency Response En Route!'
              : isResolved
                  ? '✅ Emergency Marked Resolved'
                  : 'Emergency Status: ${status.toUpperCase()}';

          final msg = isResponding
              ? 'Admin responder ${responderName ?? 'Support Team'} has been dispatched to your location ($alert.locationName).'
              : isResolved
                  ? 'Your emergency alert has been resolved. Please stay safe!'
                  : 'Emergency status updated to $status.';

          await NotificationService().sendNotification(
            userId: alert.touristId,
            title: title,
            message: msg,
            type: 'emergency_sos',
            relatedId: emergencyId,
          );
        }
      }
    } catch (_) {}
  }

  // ==========================================
  // BACKGROUND SYSTEM NOTIFICATIONS & AUDIO
  // ==========================================

  /// Request browser/system notification permission for background alerting
  Future<void> requestBackgroundNotificationPermission() async {
    if (kIsWeb) {
      try {
        if (html.Notification.permission != 'granted') {
          await html.Notification.requestPermission();
        }
      } catch (_) {}
    }
  }

  /// Fire an out-of-app OS / Browser notification even if the tab is minimized
  void showSystemBackgroundNotification(String title, String body) {
    if (kIsWeb) {
      try {
        if (html.Notification.permission == 'granted') {
          html.Notification(
            title,
            body: body,
            icon: 'favicon.png',
          );
        }
      } catch (_) {}

      _playEmergencyTone();
    }
  }

  /// Short siren via the browser Web Audio API (`AudioContext` is not in dart:html).
  void _playEmergencyTone() {
    try {
      final ctor = globalContext.getProperty<JSFunction?>(
            'AudioContext'.toJS,
          ) ??
          globalContext.getProperty<JSFunction?>(
            'webkitAudioContext'.toJS,
          );
      if (ctor == null) return;

      final audioCtx = ctor.callAsConstructor<JSObject>();
      final osc = audioCtx.callMethod<JSObject>('createOscillator'.toJS);
      final gain = audioCtx.callMethod<JSObject>('createGain'.toJS);

      osc.setProperty('type'.toJS, 'sawtooth'.toJS);
      osc
          .getProperty<JSObject>('frequency'.toJS)
          .setProperty('value'.toJS, 880.toJS);
      gain.getProperty<JSObject>('gain'.toJS).setProperty('value'.toJS, 0.3.toJS);

      osc.callMethod('connect'.toJS, gain);
      gain.callMethod(
        'connect'.toJS,
        audioCtx.getProperty('destination'.toJS),
      );
      osc.callMethod('start'.toJS);

      Future.delayed(const Duration(milliseconds: 600), () {
        osc.callMethod('stop'.toJS);
        audioCtx.callMethod('close'.toJS);
      });
    } catch (_) {}
  }
}
