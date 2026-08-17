import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../../models/service_provider.dart';
import '../../models/provider_service.dart';
import '../../services/service_provider_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/snackbar_helper.dart';
import '../map_picker.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../chat/chat_page.dart';
import '../booking/booking_payment_flow_page.dart';

class ProviderDetailsPage extends StatefulWidget {
  final ServiceProvider provider;

  const ProviderDetailsPage({super.key, required this.provider});

  @override
  State<ProviderDetailsPage> createState() => _ProviderDetailsPageState();
}

class _ProviderDetailsPageState extends State<ProviderDetailsPage> {
  final ServiceProviderService _service = ServiceProviderService();
  final AuthService _auth = AuthService();
  final ChatService _chatService = ChatService();

  bool _loadingServices = true;
  List<ProviderService> _services = [];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final list = await _service.fetchServicesForProvider(widget.provider.id);
    if (mounted) {
      setState(() {
        _services = list;
        _loadingServices = false;
      });
    }
  }

  void _openDirections() {
    final lat = widget.provider.latitude;
    final lon = widget.provider.longitude;
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon';
    if (kIsWeb) {
      html.window.open(url, '_blank');
    }
  }

  Future<void> _messageProvider() async {
    final user = _auth.currentUser;
    if (user == null) {
      SnackbarHelper.show(context, 'Please sign in to message this provider.');
      return;
    }

    final targetUserId = widget.provider.userId.isNotEmpty ? widget.provider.userId : widget.provider.id;

    final conv = await _chatService.getOrCreateConversation(
      currentUserId: user.uid,
      currentUserName: user.displayName ?? 'Tourist',
      currentUserRole: 'tourist',
      otherUserId: targetUserId,
      otherUserName: widget.provider.businessName,
      otherUserRole: 'provider',
      channelType: 'provider_tourist',
    );

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatPage(
            chatId: conv.id,
            otherUserId: targetUserId,
            otherUserName: widget.provider.businessName,
            otherUserRole: 'provider',
            channelType: 'provider_tourist',
          ),
        ),
      );
    }
  }

  void _showBookingSheet(ProviderService serviceItem) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingPaymentFlowPage(
          provider: widget.provider,
          serviceItem: serviceItem,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;

    return AppScaffold(
      title: p.businessName,
      actions: [
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          tooltip: 'Message Provider',
          onPressed: _messageProvider,
        ),
        IconButton(
          icon: const Icon(Icons.directions),
          tooltip: 'Get Directions',
          onPressed: _openDirections,
        ),
      ],
      body: ListView(
        children: [
          // Header Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.teal.shade50,
                        child: Text(p.typeIcon, style: const TextStyle(fontSize: 32)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.businessName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${p.typeDisplayName} • ${p.priceRange}',
                              style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '${p.rating.toStringAsFixed(1)} (${p.reviewCount})',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    p.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.4),
                  ),
                  const Divider(height: 24),
                  // Location & Contact Info
                  _buildInfoRow(Icons.location_on, '${p.address}, ${p.city}'),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.phone, p.phone.isNotEmpty ? p.phone : 'Contact Available in app'),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.access_time, 'Opening hours: ${p.openingHours}'),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.teal.shade800,
                          side: BorderSide(color: Colors.teal.shade400),
                        ),
                        icon: const Icon(Icons.map, size: 16),
                        label: const Text('View on Map'),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MapPickerPage(
                                initialPosition: LatLng(p.latitude, p.longitude),
                                readOnly: true,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.directions, size: 16),
                        label: const Text('Directions'),
                        onPressed: _openDirections,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Facilities Section
          if (p.facilities.isNotEmpty) ...[
            Text(
              'Facilities & Amenities',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: p.facilities.map((f) {
                return Chip(
                  avatar: const Icon(Icons.check, size: 16, color: Colors.teal),
                  label: Text(f, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.teal.shade50,
                  side: BorderSide(color: Colors.teal.shade200),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
          // Available Services / Rooms Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available ${p.businessType == "hotel" ? "Rooms & Suites" : p.businessType == "restaurant" ? "Dining & Tables" : "Vehicles & Tours"}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (_services.isNotEmpty)
                Text(
                  '${_services.length} Options',
                  style: TextStyle(fontSize: 12, color: Colors.teal.shade700, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loadingServices)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_services.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.grey, size: 36),
                      const SizedBox(height: 8),
                      const Text('No individual service packages listed yet.'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          _showBookingSheet(
                            ProviderService(
                              id: 'general-booking',
                              providerId: p.id,
                              name: 'General Reservation',
                              price: 0,
                              capacity: 4,
                            ),
                          );
                        },
                        child: const Text('Book General Reservation'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._services.map((s) => _buildServiceCard(s)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.teal.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        ),
      ],
    );
  }

  Widget _buildServiceCard(ProviderService serviceItem) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    serviceItem.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade300),
                  ),
                  child: Text(
                    serviceItem.formattedPrice,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900, fontSize: 13),
                  ),
                ),
              ],
            ),
            if (serviceItem.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                serviceItem.description,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(serviceItem.capacityLabel, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  ),
                  icon: const Icon(Icons.bookmark_add, size: 16),
                  label: const Text('Reserve This Option', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => _showBookingSheet(serviceItem),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
