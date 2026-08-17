import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/service_provider_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/snackbar_helper.dart';
import '../../models/reservation.dart';
import '../../models/service_provider.dart';
import '../../services/chat_service.dart';
import '../chat/chat_page.dart';
import 'register_provider_page.dart';

class ProviderReservationsPage extends StatefulWidget {
  const ProviderReservationsPage({super.key});

  @override
  State<ProviderReservationsPage> createState() => _ProviderReservationsPageState();
}

class _ProviderReservationsPageState extends State<ProviderReservationsPage> {
  final AuthService _auth = AuthService();
  final ServiceProviderService _service = ServiceProviderService();
  final ChatService _chatService = ChatService();

  ServiceProvider? _provider;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final p = await _service.getProviderByUserId(user.uid);
      if (mounted) {
        setState(() {
          _provider = p;
          _loadingProfile = false;
        });
      }
    } else {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return AppScaffold(
        title: 'Reservations',
        body: const Center(child: Text('Please log in as a provider.')),
      );
    }

    if (_loadingProfile) {
      return AppScaffold(
        title: 'Incoming Reservations',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_provider == null) {
      return AppScaffold(
        title: 'Incoming Reservations',
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'No Business Registered',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please register your business profile to start receiving tourist bookings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_business),
                  label: const Text('Register Business'),
                  onPressed: () async {
                    final res = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const RegisterProviderPage()),
                    );
                    if (res == true) _loadProfile();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final queryTarget = _provider!.id.isNotEmpty ? _provider!.id : user.uid;

    return AppScaffold(
      title: 'Incoming Reservations',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.teal.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.business, color: Colors.teal.shade800, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Managing bookings for: ${_provider!.businessName}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: StreamBuilder<List<Reservation>>(
              stream: _service.getProviderReservationsStream(queryTarget),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final list = snapshot.data ?? [];

                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.inbox, size: 64, color: Colors.teal.shade700),
                          ),
                          const SizedBox(height: 18),
                          const Text('No Reservations Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            'When tourists book and pay for your services, they will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final r = list[i];
                    final isConf = r.isConfirmed;
                    final isDecl = r.isDeclined;

                    final statusColor = isConf
                        ? Colors.green.shade800
                        : isDecl
                            ? Colors.red.shade800
                            : Colors.orange.shade900;
                    final statusBg = isConf
                        ? Colors.green.shade50
                        : isDecl
                            ? Colors.red.shade50
                            : Colors.orange.shade50;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    r.serviceName.isNotEmpty ? r.serviceName : 'Service Booking',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    r.status.toUpperCase(),
                                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Tourist: ${r.touristName} (${r.touristPhone.isNotEmpty ? r.touristPhone : r.touristEmail})', style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('Dates: ${r.formattedDates} • ${r.numberOfGuests} Guests • Total: ${r.formattedTotal}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                            if (r.specialRequests.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Note: "${r.specialRequests}"', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                            ],
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.teal.shade800,
                                    side: BorderSide(color: Colors.teal.shade300),
                                  ),
                                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                                  label: const Text('Message Tourist', style: TextStyle(fontSize: 12)),
                                  onPressed: () async {
                                    if (user == null) return;
                                    final conv = await _chatService.getOrCreateConversation(
                                      currentUserId: user.uid,
                                      currentUserName: _provider?.businessName ?? 'Provider',
                                      currentUserRole: 'provider',
                                      otherUserId: r.touristId,
                                      otherUserName: r.touristName.isNotEmpty ? r.touristName : 'Tourist',
                                      otherUserRole: 'tourist',
                                      channelType: 'provider_tourist',
                                    );
                                    if (context.mounted) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ChatPage(
                                            chatId: conv.id,
                                            otherUserId: r.touristId,
                                            otherUserName: r.touristName.isNotEmpty ? r.touristName : 'Tourist',
                                            otherUserRole: 'tourist',
                                            channelType: 'provider_tourist',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                if (r.isPending)
                                  Row(
                                    children: [
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                        onPressed: () async {
                                          await _service.updateReservationStatus(r.id, 'declined');
                                          if (context.mounted) SnackbarHelper.show(context, 'Reservation declined');
                                        },
                                        child: const Text('Decline'),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal.shade700,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () async {
                                          await _service.updateReservationStatus(r.id, 'confirmed');
                                          if (context.mounted) SnackbarHelper.show(context, 'Reservation confirmed! Tourist notified.');
                                        },
                                        child: const Text('Confirm'),
                                      ),
                                    ],
                                  ),
                              ],
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
}
