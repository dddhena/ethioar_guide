import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../models/emergency_alert.dart';
import '../../services/audio_narration_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/emergency_service.dart';
import '../../theme/ethio_theme.dart';
import '../../utils/web_helpers.dart';
import '../../pages/chat/chat_page.dart';

/// Full-screen high-priority modal dialog that pops up immediately on the Admin's
/// device whenever a tourist broadcasts a critical emergency SOS request.
class AdminEmergencyPopUpDialog extends StatefulWidget {
  final EmergencyAlert alert;

  const AdminEmergencyPopUpDialog({
    super.key,
    required this.alert,
  });

  static Future<void> show(BuildContext context, EmergencyAlert alert) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminEmergencyPopUpDialog(alert: alert),
    );
  }

  @override
  State<AdminEmergencyPopUpDialog> createState() => _AdminEmergencyPopUpDialogState();
}

class _AdminEmergencyPopUpDialogState extends State<AdminEmergencyPopUpDialog>
    with SingleTickerProviderStateMixin {
  final EmergencyService _emergencyService = EmergencyService();
  final AudioNarrationService _audioService = AudioNarrationService();
  final AuthService _auth = AuthService();
  final ChatService _chatService = ChatService();

  late AnimationController _pulseController;
  bool _isSilenced = false;
  bool _isResponding = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _silenceAlarm() {
    setState(() => _isSilenced = true);
    _audioService.stop();
  }

  void _openGoogleMaps() {
    final url = 'https://www.google.com/maps/search/?api=1&query=${widget.alert.latitude},${widget.alert.longitude}';
    if (kIsWeb) {
      openWebUrl(url);
    }
  }

  Future<void> _chatWithTourist() async {
    _silenceAlarm();
    Navigator.of(context).pop();

    final admin = _auth.currentUser;
    if (admin == null) return;

    final conv = await _chatService.getOrCreateConversation(
      currentUserId: admin.uid,
      currentUserName: admin.displayName ?? 'Admin Response Team',
      currentUserRole: 'admin',
      otherUserId: widget.alert.touristId,
      otherUserName: widget.alert.touristName,
      otherUserRole: 'tourist',
      channelType: 'emergency_sos',
    );

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatPage(
            chatId: conv.id,
            otherUserId: widget.alert.touristId,
            otherUserName: widget.alert.touristName,
            otherUserRole: 'tourist',
            channelType: 'emergency_sos',
          ),
        ),
      );
    }
  }

  Future<void> _dispatchResponse() async {
    setState(() => _isResponding = true);
    _silenceAlarm();

    final admin = _auth.currentUser;
    await _emergencyService.updateEmergencyStatus(
      widget.alert.id,
      'responding',
      responderId: admin?.uid ?? 'admin-responder',
      responderName: admin?.displayName ?? 'Central Dispatch Team',
    );

    if (mounted) {
      setState(() => _isResponding = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: EthioColors.forest,
          content: Text('Dispatched response team to ${widget.alert.touristName} (${widget.alert.locationName}). Tourist notified.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;

    return PopScope(
      canPop: false,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: const Color(0xFF161E2E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.6 + _pulseController.value * 0.4),
                  width: 3.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withValues(alpha: 0.35 * _pulseController.value),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Emergency Header Banner
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.warning_amber_rounded, color: Colors.yellowAccent, size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CRITICAL EMERGENCY SOS',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              Text(
                                'Immediate Tourist Assistance Requested',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        // Silence Audio Alarm Button
                        IconButton(
                          icon: Icon(
                            _isSilenced ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                            color: _isSilenced ? Colors.white38 : Colors.greenAccent,
                          ),
                          tooltip: _isSilenced ? 'Alarm Silenced' : 'Silence Voice Alarm',
                          onPressed: _silenceAlarm,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 12),

                    // Tourist Profile & Contact Info Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 18,
                                backgroundColor: EthioColors.forest,
                                child: Icon(Icons.person, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      alert.touristName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      alert.touristPhone.isNotEmpty ? alert.touristPhone : alert.touristEmail,
                                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.redAccent),
                                ),
                                child: Text(
                                  alert.typeLabel,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          const Text(
                            'EMERGENCY SITUATION NOTE:',
                            style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '"${alert.message}"',
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 14, color: Colors.cyanAccent),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'GPS: ${alert.latitude.toStringAsFixed(5)}, ${alert.longitude.toStringAsFixed(5)} (${alert.locationName})',
                                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Primary Action: Dispatch Response Team
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isResponding ? null : _dispatchResponse,
                      icon: _isResponding
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.directions_run_rounded, size: 20),
                      label: Text(
                        _isResponding ? 'Dispatching...' : 'Dispatch Team / Mark Responding',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Secondary Actions: Open GPS Map & Chat with Tourist
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.cyanAccent,
                              side: const BorderSide(color: Colors.cyanAccent),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _openGoogleMaps,
                            icon: const Icon(Icons.map_rounded, size: 16),
                            label: const Text('View on Map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white38),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _chatWithTourist,
                            icon: const Icon(Icons.chat_rounded, size: 16),
                            label: const Text('Message Tourist', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Dismiss Button
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.white54),
                      onPressed: () {
                        _silenceAlarm();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Dismiss Popup (Keep Alert Active)'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

