import 'package:flutter/material.dart';
import '../../models/provider_service.dart';
import '../../services/auth_service.dart';
import '../../services/service_provider_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/snackbar_helper.dart';

class ProviderServicesPage extends StatefulWidget {
  const ProviderServicesPage({super.key});

  @override
  State<ProviderServicesPage> createState() => _ProviderServicesPageState();
}

class _ProviderServicesPageState extends State<ProviderServicesPage> {
  final AuthService _auth = AuthService();
  final ServiceProviderService _service = ServiceProviderService();

  String? _providerId;

  @override
  void initState() {
    super.initState();
    _loadProviderId();
  }

  Future<void> _loadProviderId() async {
    final user = _auth.currentUser;
    if (user != null) {
      final p = await _service.getProviderByUserId(user.uid);
      if (mounted && p != null) {
        setState(() {
          _providerId = p.id;
        });
      }
    }
  }

  void _showAddServiceDialog([ProviderService? existing]) {
    if (_providerId == null) return;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final priceCtrl = TextEditingController(text: existing != null ? existing.price.toStringAsFixed(0) : '1500');
    final capacityCtrl = TextEditingController(text: existing != null ? existing.capacity.toString() : '2');
    String type = existing?.serviceType ?? 'room';
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
                              providerId: _providerId!,
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
    if (_providerId == null) {
      return const AppScaffold(
        title: 'Manage Services',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      title: 'Manage Services',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Service Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Service'),
                  onPressed: () => _showAddServiceDialog(),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ProviderService>>(
              stream: _service.getServicesStream(_providerId!),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final item = list[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
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
      ),
    );
  }
}