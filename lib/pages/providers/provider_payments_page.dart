import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/service_provider_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../models/payment.dart';
import '../../models/service_provider.dart';
import 'register_provider_page.dart';

class ProviderPaymentsPage extends StatefulWidget {
  const ProviderPaymentsPage({super.key});

  @override
  State<ProviderPaymentsPage> createState() => _ProviderPaymentsPageState();
}

class _ProviderPaymentsPageState extends State<ProviderPaymentsPage> {
  final AuthService _auth = AuthService();
  final ServiceProviderService _service = ServiceProviderService();

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
        title: 'Received Payments',
        body: const Center(child: Text('Please log in as a provider.')),
      );
    }

    if (_loadingProfile) {
      return AppScaffold(
        title: 'Received Payments',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_provider == null) {
      return AppScaffold(
        title: 'Received Payments',
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
                  'Please register your business profile to start tracking received payments.',
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
      title: 'Received Payments',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.green.shade800, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Payments for: ${_provider!.businessName}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: StreamBuilder<List<Payment>>(
              stream: _service.getProviderPaymentsStream(queryTarget),
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
                              color: Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.account_balance_wallet, size: 64, color: Colors.green.shade700),
                          ),
                          const SizedBox(height: 18),
                          const Text('No Payments Received Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            'Paid tourist bookings via Safaricom M-Pesa, Telebirr, and CBE Birr will be logged here.',
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
                    final p = list[i];
                    final isCompleted = p.status == 'completed' || p.status == 'paid';
                    final isFailed = p.status == 'failed';
                    final statusColor = isCompleted
                        ? Colors.green.shade700
                        : isFailed
                            ? Colors.red.shade700
                            : Colors.orange.shade800;
                    final statusBg = isCompleted
                        ? Colors.green.shade50
                        : isFailed
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
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.formattedMethod,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        if (p.createdAt != null)
                                          Text(
                                            '${p.createdAt!.day}/${p.createdAt!.month}/${p.createdAt!.year}',
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    p.status.toUpperCase(),
                                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Transaction ID:', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                    Text(
                                      p.transactionId.isNotEmpty ? p.transactionId : 'N/A',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Amount Paid:', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                    Text(
                                      p.formattedAmount,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.green.shade900,
                                      ),
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
