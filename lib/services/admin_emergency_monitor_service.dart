import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/emergency_alert.dart';
import '../services/audio_narration_service.dart';
import '../services/emergency_service.dart';
import '../utils/web_helpers.dart';
import '../widgets/admin/admin_emergency_pop_up_dialog.dart';

/// Global real-time monitoring service that listens for active tourist SOS requests
/// and triggers loud voice warnings, siren tones, system notifications, and full-screen
/// pop-up modals on the Admin's device.
class AdminEmergencyMonitorService {
  static final AdminEmergencyMonitorService _instance = AdminEmergencyMonitorService._internal();
  factory AdminEmergencyMonitorService() => _instance;
  AdminEmergencyMonitorService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AudioNarrationService _audioService = AudioNarrationService();
  final EmergencyService _emergencyService = EmergencyService();

  GlobalKey<NavigatorState>? _navigatorKey;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _emergencySubscription;
  final Set<String> _processedAlertIds = {};
  bool _isMonitoring = false;
  DateTime _monitorStartTime = DateTime.now();

  /// Starts listening for incoming tourist emergency SOS alerts across the app lifecycle
  void startMonitoring(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    if (_isMonitoring) return;
    _isMonitoring = true;
    _monitorStartTime = DateTime.now().subtract(const Duration(minutes: 5));

    _emergencyService.requestBackgroundNotificationPermission();

    _emergencySubscription?.cancel();
    _emergencySubscription = _db
        .collection('emergencies')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen(
      (snapshot) {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
            final doc = change.doc;
            final data = doc.data();
            if (data == null) continue;

            final alert = EmergencyAlert.fromMap(doc.id, data);

            // Filter for active alerts not yet acknowledged in this session
            if (alert.isActive && !_processedAlertIds.contains(alert.id)) {
              final alertTime = alert.createdAt ?? DateTime.now();
              if (alertTime.isAfter(_monitorStartTime)) {
                _processedAlertIds.add(alert.id);
                _dispatchEmergencyAlarm(alert);
              }
            }
          }
        }
      },
      onError: (err) {
        debugPrint('[AdminEmergencyMonitor] Firestore listener notice: $err');
      },
    );
  }

  /// Triggers voice siren warning, sound tone, OS notification, and on-screen pop-up modal
  Future<void> _dispatchEmergencyAlarm(EmergencyAlert alert) async {
    // 1. Voice Siren Warning (Spoken aloud by TTS)
    final spokenWarning =
        'Warning! Critical Emergency SOS alert! Tourist ${alert.touristName} has requested immediate ${alert.emergencyType} assistance. Check command center immediately!';
    _audioService.speakNavigationPrompt(spokenWarning, force: true);

    // 2. Play web/mobile alarm tone & haptic vibration
    playWebEmergencyTone();
    HapticFeedback.heavyImpact();

    // 3. Fire OS Background System Notification (pops up even if tab/app is minimized)
    _emergencyService.showSystemBackgroundNotification(
      '🚨 CRITICAL EMERGENCY SOS: ${alert.touristName}',
      '${alert.typeLabel}: "${alert.message}" reported at GPS (${alert.latitude.toStringAsFixed(4)}, ${alert.longitude.toStringAsFixed(4)})',
    );

    // 4. Pop up high-priority emergency modal dialog over current screen
    final ctx = _navigatorKey?.currentContext;
    if (ctx != null) {
      // Delay slightly so navigator context settles if currently transitioning
      Future.delayed(const Duration(milliseconds: 300), () {
        final activeCtx = _navigatorKey?.currentContext;
        if (activeCtx != null) {
          AdminEmergencyPopUpDialog.show(activeCtx, alert);
        }
      });
    }
  }

  /// Stops emergency monitoring (called on admin sign out)
  void stopMonitoring() {
    _isMonitoring = false;
    _emergencySubscription?.cancel();
    _emergencySubscription = null;
    _processedAlertIds.clear();
  }
}

