import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/payment.dart';
import '../../services/auth_service.dart';
import '../../services/payment_service.dart';
import '../../theme/ethio_theme.dart';
import '../../widgets/app_scaffold.dart';

class AdminPaymentVerificationPage extends StatefulWidget {
  const AdminPaymentVerificationPage({super.key});

  @override
  State<AdminPaymentVerificationPage> createState() => _AdminPaymentVerificationPageState();
}

class _AdminPaymentVerificationPageState extends State<AdminPaymentVerificationPage>
    with SingleTickerProviderStateMixin {
  final PaymentService _paymentService = PaymentService();
  final AuthService _auth = AuthService();

  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _verifyPayment(Payment payment, bool approve) async {
    final adminUid = _auth.currentUser?.uid ?? 'admin';
    String? adminNotes;

    if (!approve) {
      final notesController = TextEditingController();
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red),
              SizedBox(width: 8),
              Text('Reject Payment'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to reject payment "${payment.transactionId}" for ${payment.formattedAmount}?'),
              const SizedBox(height: 14),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Reason for Rejection',
                  hintText: 'e.g., Transaction ID not found or amount mismatch',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm Rejection', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm != true) return;
      adminNotes = notesController.text.trim();
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.verified, color: Colors.green),
              SizedBox(width: 8),
              Text('Verify & Approve Payment'),
            ],
          ),
          content: Text(
            'Confirm receipt of ${payment.formattedAmount} via ${payment.formattedMethod} (Ref: ${payment.transactionId})?\n\nThis will grant entrance clearance to the tourist and notify them.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Verify & Approve', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    try {
      await _paymentService.verifyPayment(
        paymentId: payment.id,
        adminUid: adminUid,
        approved: approve,
        adminNotes: adminNotes,
        tripId: payment.tripId,
        touristId: payment.userId,
        title: payment.title,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve
                ? 'Payment verified and entrance access approved! 🎉'
                : 'Payment marked as rejected.'),
            backgroundColor: approve ? Colors.green.shade700 : Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating payment: $e')),
        );
      }
    }
  }

  void _showDetailsDialog(Payment p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EthioColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  _StatusBadge(status: p.status),
                ],
              ),
              const Divider(height: 24),
              _DetailRow(label: 'Item / Trip', value: p.title.isNotEmpty ? p.title : 'Trip Entrance Fee'),
              _DetailRow(label: 'Amount Paid', value: p.formattedAmount, isBold: true, valueColor: Colors.teal.shade900),
              _DetailRow(label: 'Payment Method', value: p.formattedMethod),
              _DetailRow(label: 'Transaction Ref', value: p.transactionId.isNotEmpty ? p.transactionId : 'N/A', isCopyable: true),
              _DetailRow(label: 'Tourist ID', value: p.userId.isNotEmpty ? p.userId : 'N/A'),
              if (p.payerName.isNotEmpty) _DetailRow(label: 'Payer Name', value: p.payerName),
              if (p.payerPhone.isNotEmpty) _DetailRow(label: 'Payer Phone', value: p.payerPhone),
              if (p.createdAt != null)
                _DetailRow(
                  label: 'Date Submitted',
                  value: '${p.createdAt!.day}/${p.createdAt!.month}/${p.createdAt!.year} ${p.createdAt!.hour.toString().padLeft(2, '0')}:${p.createdAt!.minute.toString().padLeft(2, '0')}',
                ),
              if (p.adminNotes != null && p.adminNotes!.isNotEmpty)
                _DetailRow(label: 'Admin Notes', value: p.adminNotes!, valueColor: Colors.red.shade700),
              const SizedBox(height: 20),
              if (p.isPending) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _verifyPayment(p, false);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('Approve & Verify'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _verifyPayment(p, true);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Entrance Fee Verifications',
      body: StreamBuilder<List<Payment>>(
        stream: _paymentService.getEntrancePaymentsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allPayments = snapshot.data ?? [];

          final pending = allPayments.where((p) => p.isPending).toList();
          final verified = allPayments.where((p) => p.isVerified).toList();
          final rejected = allPayments.where((p) => p.isRejected).toList();

          return Column(
            children: [
              // ── Header Stats ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                color: Colors.teal.shade800,
                child: Column(
                  children: [
                    Row(
                      children: [
                        _StatBox(
                          title: 'Pending',
                          count: '${pending.length}',
                          color: Colors.orange.shade300,
                          icon: Icons.hourglass_top,
                        ),
                        const SizedBox(width: 10),
                        _StatBox(
                          title: 'Verified',
                          count: '${verified.length}',
                          color: Colors.green.shade300,
                          icon: Icons.check_circle_outline,
                        ),
                        const SizedBox(width: 10),
                        _StatBox(
                          title: 'Total Fees',
                          count: '${allPayments.fold<double>(0, (sum, p) => sum + (p.isVerified ? p.amount : 0)).toStringAsFixed(0)} ETB',
                          color: Colors.amber.shade300,
                          icon: Icons.payments_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Search bar
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'Search by Ref ID, Title or Tourist ID...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Tabs ──────────────────────────────────────────────────
              Container(
                color: Colors.teal.shade900,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.amber,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(text: 'Pending (${pending.length})'),
                    Tab(text: 'Verified (${verified.length})'),
                    Tab(text: 'Rejected (${rejected.length})'),
                    Tab(text: 'All (${allPayments.length})'),
                  ],
                ),
              ),

              // ── Tab Views ─────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPaymentList(pending, 'No pending entrance payments to verify 🎉'),
                    _buildPaymentList(verified, 'No verified entrance payments yet'),
                    _buildPaymentList(rejected, 'No rejected payments'),
                    _buildPaymentList(allPayments, 'No entrance payment transactions found'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentList(List<Payment> list, String emptyMessage) {
    var filtered = list;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.transactionId.toLowerCase().contains(_searchQuery) ||
            p.title.toLowerCase().contains(_searchQuery) ||
            p.userId.toLowerCase().contains(_searchQuery) ||
            p.payerName.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final p = filtered[index];
        return _PaymentVerificationCard(
          payment: p,
          onVerify: () => _verifyPayment(p, true),
          onReject: () => _verifyPayment(p, false),
          onTap: () => _showDetailsDialog(p),
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String count;
  final Color color;
  final IconData icon;

  const _StatBox({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              count,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentVerificationCard extends StatelessWidget {
  final Payment payment;
  final VoidCallback onVerify;
  final VoidCallback onReject;
  final VoidCallback onTap;

  const _PaymentVerificationCard({
    required this.payment,
    required this.onVerify,
    required this.onReject,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Item Title & Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('🇪🇹', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.title.isNotEmpty ? payment.title : 'Trip Entrance Fee',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          payment.payerName.isNotEmpty
                              ? 'Tourist: ${payment.payerName}'
                              : 'User ID: ${payment.userId.isNotEmpty ? payment.userId.substring(0, payment.userId.length > 8 ? 8 : payment.userId.length) : "Guest"}...',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: payment.status),
                ],
              ),
              const Divider(height: 20),

              // Middle: Method, Amount, Ref
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Method: ${payment.formattedMethod}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'Ref: ${payment.transactionId}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontFamily: 'monospace'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 14),
                            tooltip: 'Copy Reference',
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: payment.transactionId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Transaction Ref copied to clipboard')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    payment.formattedAmount,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade900,
                    ),
                  ),
                ],
              ),

              if (payment.adminNotes != null && payment.adminNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: Colors.red),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Note: ${payment.adminNotes}',
                          style: const TextStyle(fontSize: 11, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Bottom Actions (if pending)
              if (payment.isPending) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Reject', style: TextStyle(fontSize: 13)),
                        onPressed: onReject,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Verify & Approve', style: TextStyle(fontSize: 13)),
                        onPressed: onVerify,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isVerified = status == 'verified' || status == 'completed';
    final isRejected = status == 'rejected' || status == 'failed';

    final color = isVerified
        ? Colors.green.shade700
        : isRejected
            ? Colors.red.shade700
            : Colors.orange.shade800;

    final bg = isVerified
        ? Colors.green.shade50
        : isRejected
            ? Colors.red.shade50
            : Colors.orange.shade50;

    final label = isVerified
        ? 'VERIFIED'
        : isRejected
            ? 'REJECTED'
            : 'PENDING';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;
  final bool isCopyable;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
    this.isCopyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                      color: valueColor ?? EthioColors.charcoal,
                    ),
                  ),
                ),
                if (isCopyable)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 14),
                    padding: const EdgeInsets.only(left: 4),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$label copied')),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
