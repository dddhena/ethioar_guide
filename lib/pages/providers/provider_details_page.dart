import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../../models/service_provider.dart';
import '../../models/provider_service.dart';
import '../../models/reservation.dart';
import '../../services/auth_service.dart';
import '../../services/service_provider_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/snackbar_helper.dart';
import '../map_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ProviderDetailsPage extends StatefulWidget {
  final ServiceProvider provider;

  const ProviderDetailsPage({super.key, required this.provider});

  @override
  State<ProviderDetailsPage> createState() => _ProviderDetailsPageState();
}

class _ProviderDetailsPageState extends State<ProviderDetailsPage> {
  final ServiceProviderService _service = ServiceProviderService();
  final AuthService _auth = AuthService();

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

  void _showBookingSheet(ProviderService serviceItem) {
    final currentUser = _auth.currentUser;
    final touristNameCtrl = TextEditingController(text: currentUser?.displayName ?? '');
    final touristEmailCtrl = TextEditingController(text: currentUser?.email ?? '');
    final touristPhoneCtrl = TextEditingController();
    final specialRequestsCtrl = TextEditingController();

    DateTime checkInDate = DateTime.now().add(const Duration(days: 1));
    DateTime? checkOutDate = widget.provider.businessType == 'hotel'
        ? DateTime.now().add(const Duration(days: 2))
        : null;
    int guests = 1;
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final nights = (checkOutDate != null)
                ? checkOutDate!.difference(checkInDate).inDays.clamp(1, 30)
                : 1;
            final calculatedTotal = serviceItem.price * nights * (widget.provider.businessType == 'hotel' ? 1 : guests);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reserve ${serviceItem.name}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              widget.provider.businessName,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    // Date Pickers
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: checkInDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  checkInDate = picked;
                                  if (checkOutDate != null && checkOutDate!.isBefore(checkInDate)) {
                                    checkOutDate = checkInDate.add(const Duration(days: 1));
                                  }
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.provider.businessType == 'hotel' ? 'Check-in Date' : 'Visit / Service Date',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${checkInDate.day}/${checkInDate.month}/${checkInDate.year}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (widget.provider.businessType == 'hotel') ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: checkOutDate ?? checkInDate.add(const Duration(days: 1)),
                                  firstDate: checkInDate.add(const Duration(days: 1)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setModalState(() => checkOutDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Check-out Date', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                    const SizedBox(height: 4),
                                    Text(
                                      checkOutDate != null
                                          ? '${checkOutDate!.day}/${checkOutDate!.month}/${checkOutDate!.year}'
                                          : 'Select',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Guest Count & Contact
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: touristNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Your Name',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: touristPhoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Number of Guests / Seats:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: guests > 1 ? () => setModalState(() => guests--) : null,
                            ),
                            Text('$guests', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: guests < serviceItem.capacity ? () => setModalState(() => guests++) : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: specialRequestsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Special Requests / Arrival Notes (Optional)',
                        prefixIcon: Icon(Icons.notes),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Price Summary Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Estimated Total:', style: TextStyle(fontSize: 12, color: Colors.teal)),
                              Text(
                                '${calculatedTotal.toStringAsFixed(0)} ETB',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                              ),
                            ],
                          ),
                          Text(
                            widget.provider.businessType == 'hotel' ? '($nights night${nights == 1 ? '' : 's'})' : '($guests guest${guests == 1 ? '' : 's'})',
                            style: TextStyle(fontSize: 12, color: Colors.teal.shade700, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: submitting
                          ? null
                          : () async {
                              final name = touristNameCtrl.text.trim();
                              if (name.isEmpty) {
                                SnackbarHelper.show(context, 'Please enter your name.');
                                return;
                              }

                              setModalState(() => submitting = true);
                              try {
                                final reservation = Reservation(
                                  id: '',
                                  touristId: currentUser?.uid ?? 'guest-${DateTime.now().millisecondsSinceEpoch}',
                                  touristName: name,
                                  touristEmail: touristEmailCtrl.text.trim(),
                                  touristPhone: touristPhoneCtrl.text.trim(),
                                  providerId: widget.provider.id,
                                  providerName: widget.provider.businessName,
                                  serviceId: serviceItem.id,
                                  serviceName: serviceItem.name,
                                  serviceType: widget.provider.businessType,
                                  checkInDate: checkInDate,
                                  checkOutDate: checkOutDate,
                                  numberOfGuests: guests,
                                  totalAmount: calculatedTotal,
                                  specialRequests: specialRequestsCtrl.text.trim(),
                                  status: 'pending',
                                );

                                await _service.createReservation(reservation);
                                if (ctx.mounted) Navigator.of(ctx).pop();
                                if (context.mounted) {
                                  SnackbarHelper.show(context, 'Reservation sent! Waiting for provider confirmation.');
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  SnackbarHelper.show(context, 'Booking error: $e');
                                }
                              } finally {
                                if (ctx.mounted) setModalState(() => submitting = false);
                              }
                            },
                      icon: submitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_circle),
                      label: Text(submitting ? 'Submitting...' : 'Confirm Reservation Request'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;

    return AppScaffold(
      title: p.businessName,
      actions: [
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
