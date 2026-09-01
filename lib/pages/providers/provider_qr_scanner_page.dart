import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/reservation.dart';
import '../../services/service_provider_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/snackbar_helper.dart';

class ProviderQRScannerPage extends StatefulWidget {
  final String providerId;

  const ProviderQRScannerPage({super.key, required this.providerId});

  @override
  State<ProviderQRScannerPage> createState() => _ProviderQRScannerPageState();
}

class _ProviderQRScannerPageState extends State<ProviderQRScannerPage> with SingleTickerProviderStateMixin {
  final ServiceProviderService _service = ServiceProviderService();
  final TextEditingController _manualCodeCtrl = TextEditingController();
  
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  bool _isProcessing = false;
  String? _selectedSimId;

  // Scan result state
  bool _showResult = false;
  String _resultStatus = 'success'; // 'success', 'expired', 'invalid'
  Reservation? _scannedReservation;
  String? _resultErrorMsg;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    _manualCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _processScan(String reservationId) async {
    if (reservationId.trim().isEmpty) {
      SnackbarHelper.show(context, 'Please select or enter a booking reference code.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _showResult = false;
      _scannedReservation = null;
      _resultErrorMsg = null;
    });

    // Simulate scan delay (viewfinder parsing)
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      var res = await _service.getReservationById(reservationId.trim());

      if (!mounted) return;

      if (res == null) {
        // Fallback: Query payments collection directly to support entrance fees & standalone booking payments
        final payDoc = await FirebaseFirestore.instance.collection('payments').doc(reservationId.trim()).get();
        if (!mounted) return;

        if (payDoc.exists && payDoc.data() != null) {
          final payData = payDoc.data()!;
          final payStatus = payData['status'] as String? ?? '';
          final payTitle = payData['title'] as String? ?? 'Payment Receipt';
          final payAmount = ((payData['amount'] ?? 0) as num).toDouble();
          final payerName = payData['payerName'] as String? ?? 'Tourist';

          if (payStatus == 'completed_scanned' || payStatus == 'verified_scanned') {
            // Already Used/Expired
            setState(() {
              _isProcessing = false;
              _showResult = true;
              _resultStatus = 'expired';
              _scannedReservation = Reservation(
                id: reservationId.trim(),
                touristId: '',
                providerId: '',
                serviceId: '',
                serviceType: '',
                checkInDate: DateTime.now(),
                status: 'completed',
                serviceName: payTitle,
                touristName: payerName,
                totalAmount: payAmount,
              );
            });
            return;
          } else if (payStatus == 'completed' || payStatus == 'verified' || payStatus == 'paid') {
            // Mark as scanned
            await FirebaseFirestore.instance.collection('payments').doc(reservationId.trim()).update({
              'status': 'completed_scanned',
              'verifiedAt': FieldValue.serverTimestamp(),
            });

            setState(() {
              _isProcessing = false;
              _showResult = true;
              _resultStatus = 'success';
              _scannedReservation = Reservation(
                id: reservationId.trim(),
                touristId: '',
                providerId: '',
                serviceId: '',
                serviceType: '',
                checkInDate: DateTime.now(),
                status: 'completed',
                serviceName: payTitle,
                touristName: payerName,
                totalAmount: payAmount,
              );
            });
            return;
          } else {
            setState(() {
              _isProcessing = false;
              _showResult = true;
              _resultStatus = 'invalid';
              _resultErrorMsg = 'Payment status is "${payStatus.toUpperCase()}". Verification declined.';
            });
            return;
          }
        } else {
          setState(() {
            _isProcessing = false;
            _showResult = true;
            _resultStatus = 'invalid';
            _resultErrorMsg = 'Ticket not found. The reference ID "$reservationId" does not exist in our booking or payment logs.';
          });
          return;
        }
      }

      if (res.status == 'confirmed') {
        // SUCCESS: Mark reservation as completed (used/expired)
        await _service.updateReservationStatus(res.id, 'completed');
        
        // Fetch updated reservation details
        final updatedRes = await _service.getReservationById(res.id);

        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _showResult = true;
          _resultStatus = 'success';
          _scannedReservation = updatedRes ?? res;
        });
      } else if (res.status == 'completed') {
        // EXPIRED
        setState(() {
          _isProcessing = false;
          _showResult = true;
          _resultStatus = 'expired';
          _scannedReservation = res;
        });
      } else {
        // INVALID (e.g. pending, cancelled)
        setState(() {
          _isProcessing = false;
          _showResult = true;
          _resultStatus = 'invalid';
          _scannedReservation = res;
          _resultErrorMsg = 'Reservation status is "${res.status.toUpperCase()}". Tickets can only be scanned and processed once they have been PAID and CONFIRMED.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _showResult = true;
        _resultStatus = 'invalid';
        _resultErrorMsg = 'Verification Gateway Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Scan Booking QR Code',
      body: Stack(
        children: [
          // Viewfinder Camera Simulation
          Column(
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.85),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Grid Overlay for Camera feel
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.15,
                          child: GridPaper(
                            color: Colors.teal.shade300,
                            interval: 50,
                            subdivisions: 1,
                          ),
                        ),
                      ),
                      // Viewfinder Frame
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Stack(
                          children: [
                            // 4 Corners
                            _buildViewfinderCorner(top: 0, left: 0, rotateQuarter: 0),
                            _buildViewfinderCorner(top: 0, right: 0, rotateQuarter: 1),
                            _buildViewfinderCorner(bottom: 0, left: 0, rotateQuarter: 3),
                            _buildViewfinderCorner(bottom: 0, right: 0, rotateQuarter: 2),

                            // Laser Scanner line animation
                            AnimatedBuilder(
                              animation: _laserAnimation,
                              builder: (context, child) {
                                final topOffset = _laserAnimation.value * 250.0;
                                return Positioned(
                                  top: topOffset,
                                  left: 10,
                                  right: 10,
                                  child: Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.redAccent.withOpacity(0.8),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      // Helper text above box
                      const Positioned(
                        top: 24,
                        child: Text(
                          'Simulating Active Camera Viewfinder',
                          style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ),
                      // Helper text below box
                      Positioned(
                        bottom: 24,
                        child: Text(
                          _isProcessing ? '⚡ DECODING TICKET REFERENCE...' : 'Align tourist ticket QR Code inside frame',
                          style: TextStyle(
                            color: _isProcessing ? Colors.amber : Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_isProcessing)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Colors.teal),
                                SizedBox(height: 16),
                                Text(
                                  'Verifying security credentials...',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Simulation Trigger Control Panel (Representing physical scan trigger)
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Developer Scan Simulator',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Choose a tourist booking to simulate scanning their QR code:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 14),
                      StreamBuilder<List<Reservation>>(
                        stream: _service.getProviderReservationsStream(widget.providerId),
                        builder: (context, snapshot) {
                          final list = snapshot.data ?? [];
                          
                          if (list.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'No bookings registered for your business in this simulator.',
                                style: TextStyle(color: Colors.red, fontSize: 13),
                              ),
                            );
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      hint: const Text('Select a tourist booking'),
                                      value: _selectedSimId,
                                      isExpanded: true,
                                      items: list.map((r) {
                                        return DropdownMenuItem<String>(
                                          value: r.id,
                                          child: Text(
                                            '${r.touristName} (${r.serviceName}) [Status: ${r.status}]',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedSimId = val;
                                          if (val != null) {
                                            _manualCodeCtrl.text = val;
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _manualCodeCtrl,
                              decoration: InputDecoration(
                                labelText: 'Or manually paste Ticket ID / Booking Code',
                                labelStyle: const TextStyle(fontSize: 13),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              _processScan(_manualCodeCtrl.text);
                            },
                            child: const Text('Verify Scan'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Scan Result Overlay Modal/Sheet
          if (_showResult) _buildResultView(),
        ],
      ),
    );
  }

  Widget _buildViewfinderCorner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required int rotateQuarter,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: RotatedBox(
        quarterTurns: rotateQuarter,
        child: Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.teal, width: 4.5),
              left: BorderSide(color: Colors.teal, width: 4.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultView() {
    Color headerBg;
    Color iconColor;
    IconData icon;
    String statusTitle;
    String statusSubtitle;

    if (_resultStatus == 'success') {
      headerBg = Colors.green.shade600;
      iconColor = Colors.green.shade700;
      icon = Icons.check_circle;
      statusTitle = 'VERIFICATION SUCCESS';
      statusSubtitle = 'Booking ticket marked successfully as COMPLETED / USED.';
    } else if (_resultStatus == 'expired') {
      headerBg = Colors.orange.shade800;
      iconColor = Colors.orange.shade900;
      icon = Icons.warning_amber_rounded;
      statusTitle = 'TICKET EXPIRED / USED';
      statusSubtitle = 'This QR Ticket has already been scanned and verified. Expired!';
    } else {
      headerBg = Colors.red.shade700;
      iconColor = Colors.red.shade800;
      icon = Icons.error_outline_rounded;
      statusTitle = 'VERIFICATION DECLINED';
      statusSubtitle = 'This ticket does not meet activation criteria.';
    }

    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.72,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, 10),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Modal Banner
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  color: headerBg,
                  child: Column(
                    children: [
                      Text(
                        statusTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11),
                      ),
                    ],
                  ),
                ),

                // Modal Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Giant Icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 72, color: iconColor),
                        ),
                        const SizedBox(height: 20),

                        if (_resultStatus == 'success' && _scannedReservation != null) ...[
                          const Text(
                            'TICKET VERIFIED',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.green),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow('Tourist Name', _scannedReservation!.touristName),
                          _buildDetailRow('Service Options', _scannedReservation!.serviceName),
                          _buildDetailRow('Guests Count', '${_scannedReservation!.numberOfGuests} People'),
                          _buildDetailRow('Amount Paid', '${_scannedReservation!.totalAmount} ETB'),
                          _buildDetailRow('Check-in Date', _scannedReservation!.formattedDates),
                          _buildDetailRow('Booking Code', _scannedReservation!.id),
                        ] else if (_resultStatus == 'expired' && _scannedReservation != null) ...[
                          const Text(
                            'TICKET ALREADY SCANNED',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This pass was expired upon check-in. It was previously used and cannot be reuse-scanned.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow('Booking Owner', _scannedReservation!.touristName),
                          _buildDetailRow('Service Options', _scannedReservation!.serviceName),
                          _buildDetailRow('Original Booking ID', _scannedReservation!.id),
                          _buildDetailRow('Current Status', 'COMPLETED / USED', isAlert: true),
                        ] else ...[
                          const Text(
                            'INVALID QR CODE TICKET',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              _resultErrorMsg ?? 'No active registration parameters found.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Modal Footer
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade900,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      setState(() {
                        _showResult = false;
                      });
                    },
                    child: const Text('Back to Scanner'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13, 
                fontWeight: FontWeight.bold,
                color: isAlert ? Colors.red.shade800 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
