import 'package:flutter/material.dart';
import '../../models/service_provider.dart';
import '../../models/provider_service.dart';
import '../../models/reservation.dart';
import '../../services/auth_service.dart';
import '../../services/service_provider_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/snackbar_helper.dart';
import 'register_provider_page.dart';

class ProviderDashboardPage extends StatefulWidget {
  const ProviderDashboardPage({super.key});

  @override
  State<ProviderDashboardPage> createState() => _ProviderDashboardPageState();
}

class _ProviderDashboardPageState extends State<ProviderDashboardPage> with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();
  final ServiceProviderService _service = ServiceProviderService();

  late TabController _tabController;
  ServiceProvider? _provider;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProviderProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProviderProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final p = await _service.getProviderByUserId(user.uid);
      if (mounted) {
        setState(() {
          _provider = p;
          _loading = false;
        });
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddServiceDialog([ProviderService? existing]) {
    if (_provider == null) return;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final priceCtrl = TextEditingController(text: existing != null ? existing.price.toStringAsFixed(0) : '1500');
    final capacityCtrl = TextEditingController(text: existing != null ? existing.capacity.toString() : '2');
    String type = existing?.serviceType ?? (_provider!.businessType == 'hotel' ? 'room' : _provider!.businessType == 'restaurant' ? 'dining' : 'vehicle');
    bool isAvailable = existing?.isAvailable ?? true;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(existing != null ? 'Edit Service' : 'Add New Service / Option'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Service Name (e.g. Deluxe Room, VIP Table, Shuttle)'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Description & Features'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Price (ETB)', prefixText: 'ETB '),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: capacityCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Capacity (Guests/Seats)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Available for booking'),
                      value: isAvailable,
                      onChanged: (v) => setDialogState(() => isAvailable = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;
                          setDialogState(() => saving = true);
                          try {
                            final item = ProviderService(
                              id: existing?.id ?? '',
                              providerId: _provider!.id,
                              name: name,
                              serviceType: type,
                              description: descCtrl.text.trim(),
                              price: double.tryParse(priceCtrl.text) ?? 0.0,
                              capacity: int.tryParse(capacityCtrl.text) ?? 1,
                              isAvailable: isAvailable,
                            );

                            if (existing != null) {
                              await _service.updateService(item);
                            } else {
                              await _service.addService(item);
                            }

                            if (ctx.mounted) Navigator.of(ctx).pop();
                            if (context.mounted) {
                              SnackbarHelper.show(context, existing != null ? 'Service updated' : 'Service added');
                            }
                          } catch (e) {
                            if (context.mounted) SnackbarHelper.show(context, 'Error saving service: $e');
                          } finally {
                            if (ctx.mounted) setDialogState(() => saving = false);
                          }
                        },
                  child: Text(saving ? 'Saving...' : (existing != null ? 'Update' : 'Add Service')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppScaffold(
        title: 'Provider Dashboard',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_provider == null) {
      return AppScaffold(
        title: 'Provider Dashboard',
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.store_mall_directory_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No Business Registered Yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Register your hotel, restaurant, or transport business to manage services and receive bookings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_business),
                  label: const Text('Register Business Now'),
                  onPressed: () async {
                    final res = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const RegisterProviderPage()),
                    );
                    if (res == true) _loadProviderProfile();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AppScaffold(
      title: 'Provider Portal',
      body: Column(
        children: [
          // Business Summary Header Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.teal.shade50,
                    child: Text(_provider!.typeIcon, style: const TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _provider!.businessName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text('${_provider!.typeDisplayName} • ${_provider!.city}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: const Text('Verified & Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: Colors.teal.shade800,
            indicatorColor: Colors.teal.shade700,
            tabs: const [
              Tab(icon: Icon(Icons.list_alt), text: 'Services / Catalog'),
              Tab(icon: Icon(Icons.inbox), text: 'Reservations Manager'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildServicesTab(),
                _buildReservationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Manage Options & Pricing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Service Option'),
                onPressed: () => _showAddServiceDialog(),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ProviderService>>(
            stream: _service.getServicesStream(_provider!.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No service options listed yet.'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _showAddServiceDialog(),
                        child: const Text('Add First Service'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final item = list[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${item.formattedPrice} • ${item.capacityLabel}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () => _showAddServiceDialog(item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            onPressed: () async {
                              await _service.deleteService(item.id);
                              if (context.mounted) SnackbarHelper.show(context, 'Service deleted');
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
    );
  }

  Widget _buildReservationsTab() {
    return StreamBuilder<List<Reservation>>(
      stream: _service.getProviderReservationsStream(_provider!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snapshot.data ?? [];

        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                const Text('No reservations received yet', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Tourist booking requests will appear here in real time.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, i) {
            final r = list[i];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          r.serviceName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: r.isConfirmed
                                ? Colors.green.shade50
                                : r.isDeclined
                                    ? Colors.red.shade50
                                    : Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            r.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: r.isConfirmed
                                  ? Colors.green.shade800
                                  : r.isDeclined
                                      ? Colors.red.shade800
                                      : Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Tourist: ${r.touristName} (${r.touristPhone.isNotEmpty ? r.touristPhone : r.touristEmail})', style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Dates: ${r.formattedDates} • ${r.numberOfGuests} Guests • Total: ${r.formattedTotal}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    if (r.specialRequests.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Note: "${r.specialRequests}"', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                    ],
                    if (r.isPending) ...[
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
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
                            child: const Text('Confirm Booking'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
