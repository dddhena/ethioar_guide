import 'package:flutter/material.dart';
import '../models/payment.dart';
import '../services/auth_service.dart';
import '../services/service_provider_service.dart';
import '../widgets/app_scaffold.dart';

class TouristPaymentsPage extends StatelessWidget {
  const TouristPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final user = auth.currentUser;
    final service = ServiceProviderService();

    if (user == null) {
      return AppScaffold(
        title: 'My Payments',
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Please sign in to view payment records.', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return AppScaffold(
      title: 'My Payments',
      body: StreamBuilder<List<Payment>>(
        stream: service.getTouristPaymentsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
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
                      child: Icon(Icons.receipt_long, size: 64, color: Colors.teal.shade700),
                    ),
                    const SizedBox(height: 18),
                    const Text('No Payments Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'When you book and pay for hotel stays, dining, or tours using Safaricom M-Pesa or Telebirr, receipts will show up here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final p = list[index];

              final isCompleted = p.status == 'completed' || p.status == 'verified' || p.status == 'paid';
              final isFailed = p.status == 'failed' || p.status == 'rejected';

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

              final statusLabel = isCompleted
                  ? 'VERIFIED'
                  : isFailed
                      ? (p.status == 'rejected' ? 'REJECTED' : 'FAILED')
                      : 'PENDING VERIFICATION';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
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
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: p.isEntranceFee ? Colors.amber.shade50 : Colors.teal.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  p.isEntranceFee ? Icons.confirmation_number_outlined : Icons.payment,
                                  color: p.isEntranceFee ? Colors.amber.shade900 : Colors.teal.shade800,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.title.isNotEmpty ? p.title : p.formattedMethod,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  if (p.createdAt != null)
                                    Text(
                                      '${p.formattedMethod} • ${p.createdAt!.day}/${p.createdAt!.month}/${p.createdAt!.year}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (p.adminNotes != null && p.adminNotes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Admin note: ${p.adminNotes}',
                            style: const TextStyle(fontSize: 11, color: Colors.red),
                          ),
                        ),
                      ],
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Transaction Reference:', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              Text(
                                p.transactionId.isNotEmpty ? p.transactionId : 'N/A',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Amount:', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              Text(
                                p.formattedAmount,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.teal.shade900,
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
    );
  }
}
