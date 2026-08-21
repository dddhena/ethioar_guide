import 'package:flutter/material.dart';
import '../models/landmark.dart';
import '../models/trip.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/payment_service.dart';
import '../services/trip_service.dart';
import '../theme/ethio_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/place_image.dart';
import 'landmark_detail_page.dart';
import 'landmarks_page.dart';

class TripDetailPage extends StatefulWidget {
  final TouristTrip trip;

  const TripDetailPage({super.key, required this.trip});

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  final _fs = FirestoreService();
  final _tripService = TripService();
  final _paymentService = PaymentService();
  final _auth = AuthService();

  late TouristTrip _trip;
  List<Landmark> _places = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _loadPlacesAndTrip();
  }

  Future<void> _loadPlacesAndTrip() async {
    setState(() => _loading = true);
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final updatedTrip = await _tripService.getTrip(uid, _trip.id);
      if (updatedTrip != null) {
        _trip = updatedTrip;
      }
    }

    final all = await _fs.fetchLandmarks();
    _places = all.where((l) => _trip.placeIds.contains(l.id)).toList();
    if (mounted) setState(() => _loading = false);
  }

  double get _calculatedEntranceTotal {
    return _places.fold<double>(0.0, (sum, p) => sum + p.entranceFee);
  }

  Future<void> _markCompleted() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _tripService.markCompleted(uid, _trip.id);
    setState(() {
      _trip = _trip.copyWith(status: 'completed');
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip marked as completed! 🎓 Payments closed.')),
      );
    }
  }

  Future<void> _removePlace(Landmark place) async {
    if (_trip.isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot modify a completed trip.')),
      );
      return;
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final newPlaceIds = List<String>.from(_trip.placeIds)..remove(place.id);
    final newTotal = _places
        .where((p) => p.id != place.id)
        .fold<double>(0.0, (sum, p) => sum + p.entranceFee);

    await _tripService.removePlaceFromTrip(
      touristId: uid,
      tripId: _trip.id,
      placeId: place.id,
      newEntranceFeeTotal: newTotal,
    );

    setState(() {
      _trip = _trip.copyWith(
        placeIds: newPlaceIds,
        entranceFeeTotal: newTotal,
      );
      _places.removeWhere((p) => p.id == place.id);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${place.name} removed from trip')),
      );
    }
  }

  void _showPaymentBottomSheet() {
    // Payment is disabled if trip is completed, already verified/paid, or currently pending verification
    if (_trip.isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This trip is completed. No more payments can be made.')),
      );
      return;
    }
    if (_trip.isEntrancePaid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrance payment is already verified for this trip.')),
      );
      return;
    }
    if (_trip.isEntrancePending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment is currently pending Admin verification.')),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    String selectedMethod = 'telebirr';
    final txController = TextEditingController(
      text: PaymentService.generateTransactionReference(selectedMethod),
    );
    final phoneController = TextEditingController();
    bool submitting = false;
    final totalFee = _calculatedEntranceTotal;
    final isRetry = _trip.isEntranceRejected;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    children: [
                      Icon(
                        isRetry ? Icons.replay : Icons.confirmation_number,
                        color: isRetry ? Colors.red.shade700 : EthioColors.forest,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isRetry ? 'Retry Entrance Payment' : 'Pay Entrance Fees',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isRetry
                        ? 'Submit a new payment reference to get verified by the admin.'
                        : 'Admission payment for ${_places.length} attraction${_places.length > 1 ? "s" : ""} in "${_trip.name}"',
                    style: const TextStyle(fontSize: 13, color: EthioColors.muted),
                  ),
                  const Divider(height: 24),

                  // Amount Summary
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isRetry ? Colors.red.shade50 : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isRetry ? Colors.red.shade200 : Colors.amber.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Admission Due:', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '${totalFee.toStringAsFixed(2)} ETB',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Method Selection
                  const Text('Select Payment Method:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _PayMethodButton(
                          label: 'Telebirr',
                          icon: '📱',
                          selected: selectedMethod == 'telebirr',
                          onTap: () {
                            setModalState(() {
                              selectedMethod = 'telebirr';
                              txController.text = PaymentService.generateTransactionReference(selectedMethod);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PayMethodButton(
                          label: 'M-Pesa',
                          icon: '🟢',
                          selected: selectedMethod == 'daraja_mpesa',
                          onTap: () {
                            setModalState(() {
                              selectedMethod = 'daraja_mpesa';
                              txController.text = PaymentService.generateTransactionReference(selectedMethod);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PayMethodButton(
                          label: 'CBE Birr',
                          icon: '🏦',
                          selected: selectedMethod == 'cbe_birr',
                          onTap: () {
                            setModalState(() {
                              selectedMethod = 'cbe_birr';
                              txController.text = PaymentService.generateTransactionReference(selectedMethod);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Transaction Reference Field
                  TextField(
                    controller: txController,
                    decoration: InputDecoration(
                      labelText: 'Transaction Reference ID',
                      prefixIcon: const Icon(Icons.receipt_long),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        onPressed: () {
                          setModalState(() {
                            txController.text = PaymentService.generateTransactionReference(selectedMethod);
                          });
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Payer Phone (Optional)',
                      hintText: '+251 91 234 5678',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.admin_panel_settings, size: 16, color: Colors.blue),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Admin verification will verify your entrance tickets upon submission.',
                            style: TextStyle(fontSize: 11, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRetry ? Colors.teal.shade800 : EthioColors.forest,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: submitting
                        ? null
                        : () async {
                            final txId = txController.text.trim();
                            if (txId.isEmpty) return;

                            setModalState(() => submitting = true);
                            try {
                              final paymentId = await _paymentService.createEntrancePayment(
                                userId: user.uid,
                                amount: totalFee,
                                paymentMethod: selectedMethod,
                                tripId: _trip.id,
                                title: 'Entrance Tickets: ${_trip.name} (${_places.length} places)',
                                payerName: user.displayName ?? user.email ?? 'Tourist',
                                payerPhone: phoneController.text.trim(),
                                transactionId: txId,
                              );

                              await _tripService.updateTripEntrancePayment(
                                touristId: user.uid,
                                tripId: _trip.id,
                                status: 'pending',
                                paymentId: paymentId,
                                entranceFeeTotal: totalFee,
                              );

                              if (mounted) {
                                Navigator.of(ctx).pop();
                                _loadPlacesAndTrip();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Payment submitted! Awaiting Admin verification. 🎟️'),
                                    backgroundColor: EthioColors.forest,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to submit payment: $e')),
                                );
                              }
                            }
                          },
                    child: submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            isRetry
                                ? 'Resubmit ${totalFee.toStringAsFixed(0)} ETB for Verification'
                                : 'Submit ${totalFee.toStringAsFixed(0)} ETB for Verification',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalFee = _calculatedEntranceTotal;

    return AppScaffold(
      title: _trip.name,
      body: RefreshIndicator(
        onRefresh: _loadPlacesAndTrip,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _trip.isCompleted
                      ? [Colors.blueGrey.shade700, Colors.blueGrey.shade500]
                      : [EthioColors.forest, EthioColors.forestLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _trip.isCompleted
                        ? Colors.blueGrey.withValues(alpha: 0.25)
                        : EthioColors.forest.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_trip.isCompleted ? '🎓' : '🇪🇹', style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _trip.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _trip.dateRangeLabel,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _trip.status.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Entrance Payment Status Card ─────────────────────────
            if (_places.isNotEmpty) ...[
              _EntrancePaymentStatusCard(
                trip: _trip,
                totalFee: totalFee,
                onPayNow: _showPaymentBottomSheet,
              ),
              const SizedBox(height: 24),
            ],

            // Places Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Places to Visit (${_places.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: EthioColors.charcoal),
                ),
                if (!_trip.isCompleted)
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LandmarksPage()),
                      );
                      _loadPlacesAndTrip();
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Place'),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_places.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: EthioColors.divider),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.map_outlined, size: 48, color: EthioColors.muted),
                    const SizedBox(height: 12),
                    const Text('No places added to this trip yet', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text('Explore attractions and tap "Add to Trip" to organize your itinerary.',
                        textAlign: TextAlign.center, style: TextStyle(color: EthioColors.muted, fontSize: 13)),
                    const SizedBox(height: 16),
                    if (!_trip.isCompleted)
                      ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LandmarksPage()),
                          );
                          _loadPlacesAndTrip();
                        },
                        icon: const Icon(Icons.explore),
                        label: const Text('Browse Places'),
                      ),
                  ],
                ),
              )
            else
              ..._places.map((place) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: SizedBox(
                        width: 60,
                        height: 60,
                        child: PlaceImage(landmark: place, height: 60, borderRadius: BorderRadius.circular(8)),
                      ),
                      title: Text(place.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text('${place.city.isNotEmpty ? place.city : place.category} • ⭐ ${place.rating.toStringAsFixed(1)}'),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: place.entranceFee > 0 ? Colors.amber.shade50 : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '🎟️ ${place.formattedEntranceFee}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: place.entranceFee > 0 ? Colors.amber.shade900 : Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (val) {
                          if (val == 'details') {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => LandmarkDetailPage(landmark: place)),
                            );
                          } else if (val == 'remove') {
                            _removePlace(place);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'details', child: Text('View Details')),
                          if (!_trip.isCompleted)
                            const PopupMenuItem(value: 'remove', child: Text('Remove from Trip', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => LandmarkDetailPage(landmark: place)),
                        );
                      },
                    ),
                  )),

            const SizedBox(height: 24),
            if (!_trip.isCompleted)
              OutlinedButton.icon(
                onPressed: _markCompleted,
                icon: const Icon(Icons.check_circle_outline, color: EthioColors.forest),
                label: const Text('Mark Trip as Completed', style: TextStyle(color: EthioColors.forest)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: EthioColors.forest),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EntrancePaymentStatusCard extends StatelessWidget {
  final TouristTrip trip;
  final double totalFee;
  final VoidCallback onPayNow;

  const _EntrancePaymentStatusCard({
    required this.trip,
    required this.totalFee,
    required this.onPayNow,
  });

  @override
  Widget build(BuildContext context) {
    final status = trip.entrancePaymentStatus.toLowerCase();
    final isPaid = status == 'verified' || status == 'completed';
    final isPending = status == 'pending';
    final isRejected = status == 'rejected';
    final isTripCompleted = trip.isCompleted;

    Color cardBg = Colors.orange.shade50;
    Color borderColor = Colors.orange.shade200;
    IconData icon = Icons.confirmation_number_outlined;
    Color iconColor = Colors.orange.shade800;
    String statusTitle = 'Entrance Payment Pending';
    String statusDesc = 'Your payment has been submitted and is awaiting administrator verification.';

    if (isTripCompleted) {
      if (isPaid) {
        cardBg = Colors.green.shade50;
        borderColor = Colors.green.shade200;
        icon = Icons.verified;
        iconColor = Colors.green.shade800;
        statusTitle = 'Trip Completed • Entrance Verified ✅';
        statusDesc = 'This trip is completed and entrance access was verified. No further payments needed.';
      } else {
        cardBg = Colors.grey.shade100;
        borderColor = Colors.grey.shade300;
        icon = Icons.lock_outline;
        iconColor = Colors.grey.shade700;
        statusTitle = 'Trip Completed (Payments Closed) 🔒';
        statusDesc = 'This trip has ended. No further entrance payments can be made for this trip.';
      }
    } else if (isPaid) {
      cardBg = Colors.green.shade50;
      borderColor = Colors.green.shade200;
      icon = Icons.verified;
      iconColor = Colors.green.shade800;
      statusTitle = 'Entrance Access Verified! ✅';
      statusDesc = 'All entrance fees are verified by admin. You have full admission clearance for this trip! No further payment required.';
    } else if (isPending) {
      cardBg = Colors.amber.shade50;
      borderColor = Colors.amber.shade300;
      icon = Icons.hourglass_top;
      iconColor = Colors.amber.shade900;
      statusTitle = 'Admin Verification in Progress ⏳';
      statusDesc = 'Payment submitted. An admin is verifying your transaction. Please wait for verification.';
    } else if (isRejected) {
      cardBg = Colors.red.shade50;
      borderColor = Colors.red.shade200;
      icon = Icons.cancel_outlined;
      iconColor = Colors.red.shade800;
      statusTitle = 'Payment Rejected by Admin ❌';
      statusDesc = 'Your previous payment could not be verified by the admin. You can submit a new payment below.';
    } else {
      // unpaid
      cardBg = Colors.blue.shade50;
      borderColor = Colors.blue.shade200;
      icon = Icons.payment;
      iconColor = Colors.blue.shade800;
      statusTitle = 'Entrance Fee: ${totalFee.toStringAsFixed(0)} ETB';
      statusDesc = totalFee > 0
          ? 'Pay admission fees for your scheduled places to get entry verification.'
          : 'All selected places have free admission.';
    }

    // Only allow paying if:
    // 1. Trip is NOT completed
    // 2. Payment is NOT already verified/completed
    // 3. Payment is NOT currently pending verification
    // 4. Either unpaid or rejected
    final canPay = !isTripCompleted && !isPaid && !isPending && totalFee > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: iconColor,
                  ),
                ),
              ),
              if (totalFee > 0)
                Text(
                  '${totalFee.toStringAsFixed(0)} ETB',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: iconColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(statusDesc, style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
          if (canPay) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRejected ? Colors.teal.shade800 : EthioColors.forest,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(isRejected ? Icons.replay : Icons.payment, size: 18),
                label: Text(isRejected ? 'Pay Again (Retry Payment)' : 'Pay Entrance Fee Now'),
                onPressed: onPayNow,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PayMethodButton extends StatelessWidget {
  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  const _PayMethodButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.teal.shade700 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.teal.shade700 : EthioColors.divider,
          ),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : EthioColors.charcoal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
