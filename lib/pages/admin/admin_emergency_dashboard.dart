import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../../models/emergency_alert.dart';
import '../../services/auth_service.dart';
import '../../services/emergency_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/snackbar_helper.dart';
import '../chat/chat_page.dart';

class AdminEmergencyDashboard extends StatefulWidget {
  const AdminEmergencyDashboard({super.key});

  @override
  State<AdminEmergencyDashboard> createState() => _AdminEmergencyDashboardState();
}

class _AdminEmergencyDashboardState extends State<AdminEmergencyDashboard> {
  final EmergencyService _emergencyService = EmergencyService();
  final AuthService _auth = AuthService();
  final ChatService _chatService = ChatService();

  String _filterStatus = 'all'; // 'all', 'active', 'responding', 'resolved'

  @override
  void initState() {
    super.initState();
    _emergencyService.requestBackgroundNotificationPermission();
  }

  void _openInGoogleMaps(double lat, double lng) {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (kIsWeb) {
      html.window.open(url, '_blank');
    }
  }

  Future<void> _messageTourist(EmergencyAlert alert) async {
    final admin = _auth.currentUser;
    if (admin == null) return;

    final conv = await _chatService.getOrCreateConversation(
      currentUserId: admin.uid,
      currentUserName: admin.displayName ?? 'Admin Response Team',
      currentUserRole: 'admin',
      otherUserId: alert.touristId,
      otherUserName: alert.touristName,
      otherUserRole: 'tourist',
      channelType: 'emergency_sos',
    );

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatPage(
            chatId: conv.id,
            otherUserId: alert.touristId,
            otherUserName: alert.touristName,
            otherUserRole: 'tourist',
            channelType: 'emergency_sos',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = _auth.currentUser;

    return AppScaffold(
      title: '🚨 Emergency SOS Command Center',
      body: Column(
        children: [
          // Background alerting info banner
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.red.shade800, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Background Alerts Active: You will receive high-priority desktop notifications even when this tab is minimized.',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade900, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // Filter bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                _filterChip('all', 'All Alerts'),
                _filterChip('active', '🔴 Active Urgent'),
                _filterChip('responding', '🟡 Responding'),
                _filterChip('resolved', '🟢 Resolved'),
              ],
            ),
          ),

          // Live Alerts List
          Expanded(
            child: StreamBuilder<List<EmergencyAlert>>(
              stream: _emergencyService.getEmergenciesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allAlerts = snapshot.data ?? [];

                final filtered = allAlerts.where((a) {
                  if (_filterStatus == 'all') return true;
                  return a.status == _filterStatus;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.verified_user, size: 64, color: Colors.green.shade700),
                          ),
                          const SizedBox(height: 18),
                          const Text('All Clear — No Active SOS Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('When tourists broadcast emergency SOS requests, they will appear here in real time.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final a = filtered[i];

                    Color badgeColor;
                    Color badgeBg;
                    String badgeLabel;

                    if (a.isActive) {
                      badgeColor = Colors.red.shade900;
                      badgeBg = Colors.red.shade100;
                      badgeLabel = 'CRITICAL ACTIVE 🔴';
                    } else if (a.isResponding) {
                      badgeColor = Colors.orange.shade900;
                      badgeBg = Colors.orange.shade100;
                      badgeLabel = 'DISPATCHED 🟡';
                    } else {
                      badgeColor = Colors.green.shade900;
                      badgeBg = Colors.green.shade100;
                      badgeLabel = 'RESOLVED 🟢';
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: a.isActive ? Colors.red.shade400 : Colors.grey.shade300, width: a.isActive ? 2 : 1),
                      ),
                      elevation: a.isActive ? 4 : 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(a.typeLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    badgeLabel,
                                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Tourist: ${a.touristName} (${a.touristPhone.isNotEmpty ? a.touristPhone : a.touristEmail})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('Emergency Note: "${a.message}"', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade800, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('GPS: ${a.latitude.toStringAsFixed(5)}, ${a.longitude.toStringAsFixed(5)} • Reported: ${a.timeAgo}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            const Divider(height: 18),

                            // Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.map, size: 16),
                                  label: const Text('View GPS on Map', style: TextStyle(fontSize: 12)),
                                  onPressed: () => _openInGoogleMaps(a.latitude, a.longitude),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.chat, size: 16),
                                  label: const Text('Message', style: TextStyle(fontSize: 12)),
                                  onPressed: () => _messageTourist(a),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Response state workflow
                            if (a.isActive)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade800,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(38),
                                ),
                                icon: const Icon(Icons.directions_run),
                                label: const Text('Dispatch / Mark as Responding'),
                                onPressed: () async {
                                  await _emergencyService.updateEmergencyStatus(
                                    a.id,
                                    'responding',
                                    responderId: admin?.uid,
                                    responderName: admin?.displayName ?? 'Admin Team',
                                  );
                                  if (context.mounted) SnackbarHelper.show(context, 'Status updated: Responding');
                                },
                              ),
                            if (a.isResponding)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(38),
                                ),
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Mark Emergency as Resolved'),
                                onPressed: () async {
                                  await _emergencyService.updateEmergencyStatus(
                                    a.id,
                                    'resolved',
                                    responderId: admin?.uid,
                                    responderName: admin?.displayName ?? 'Admin Team',
                                  );
                                  if (context.mounted) SnackbarHelper.show(context, 'Emergency marked as resolved');
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String statusKey, String label) {
    final isSelected = _filterStatus == statusKey;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        selectedColor: Colors.red.shade100,
        checkmarkColor: Colors.red.shade800,
        onSelected: (_) => setState(() => _filterStatus = statusKey),
      ),
    );
  }
}
