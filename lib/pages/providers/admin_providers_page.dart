import 'package:flutter/material.dart';
import '../../models/service_provider.dart';
import '../../services/service_provider_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/snackbar_helper.dart';

class AdminProvidersPage extends StatefulWidget {
  const AdminProvidersPage({super.key});

  @override
  State<AdminProvidersPage> createState() => _AdminProvidersPageState();
}

class _AdminProvidersPageState extends State<AdminProvidersPage> {
  final ServiceProviderService _service = ServiceProviderService();
  bool _loading = true;
  List<ServiceProvider> _providers = [];

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() => _loading = true);
    final list = await _service.fetchAllProvidersAdmin();
    if (mounted) {
      setState(() {
        _providers = list;
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    await _service.updateProviderApprovalStatus(id, status);
    if (mounted) {
      SnackbarHelper.show(context, 'Provider status updated to $status');
      _loadProviders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Admin: Verify Providers',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _providers.isEmpty
              ? const Center(child: Text('No service providers found.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _providers.length,
                  itemBuilder: (context, i) {
                    final p = _providers[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade50,
                          child: Text(p.typeIcon, style: const TextStyle(fontSize: 22)),
                        ),
                        title: Text(p.businessName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${p.typeDisplayName} • ${p.city} • Status: ${p.approvalStatus.toUpperCase()}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!p.isApproved)
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                tooltip: 'Approve Provider',
                                onPressed: () => _updateStatus(p.id, 'approved'),
                              ),
                            if (p.approvalStatus != 'rejected')
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                tooltip: 'Reject Provider',
                                onPressed: () => _updateStatus(p.id, 'rejected'),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
