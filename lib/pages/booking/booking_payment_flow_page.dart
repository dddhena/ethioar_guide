import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/service_provider.dart';
import '../../models/provider_service.dart';
import '../../models/reservation.dart';
import '../../models/payment.dart';
import '../../services/auth_service.dart';
import '../../services/service_provider_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/snackbar_helper.dart';
import '../providers/my_reservations_page.dart';

class BookingPaymentFlowPage extends StatefulWidget {
  final ServiceProvider provider;
  final ProviderService serviceItem;

  const BookingPaymentFlowPage({
    super.key,
    required this.provider,
    required this.serviceItem,
  });

  @override
  State<BookingPaymentFlowPage> createState() => _BookingPaymentFlowPageState();
}

class _BookingPaymentFlowPageState extends State<BookingPaymentFlowPage> {
  final ServiceProviderService _service = ServiceProviderService();
  final AuthService _auth = AuthService();

  int _currentStep = 0; // 0: Details, 1: Review, 2: Payment Method, 3: Processing, 4: Result

  // Step 1 Form Data
  late DateTime _checkInDate;
  DateTime? _checkOutDate;
  int _guests = 1;
  final TextEditingController _touristNameCtrl = TextEditingController();
  final TextEditingController _touristEmailCtrl = TextEditingController();
  final TextEditingController _touristPhoneCtrl = TextEditingController();
  final TextEditingController _specialRequestsCtrl = TextEditingController();

  // Step 3 Payment Data
  String _selectedMethod = 'daraja_mpesa'; // 'daraja_mpesa', 'telebirr', 'cbe_birr', 'card'
  final TextEditingController _paymentPhoneCtrl = TextEditingController();

  // Step 4 & 5 Processing / Result
  bool _isProcessing = false;
  String _processingStatusText = 'Initiating transaction...';
  bool _paymentSuccess = false;
  String _transactionId = '';
  String _createdReservationId = '';
  String _createdPaymentId = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkInDate = DateTime.now().add(const Duration(days: 1));
    if (widget.provider.businessType == 'hotel') {
      _checkOutDate = _checkInDate.add(const Duration(days: 1));
    }

    final user = _auth.currentUser;
    if (user != null) {
      _touristNameCtrl.text = user.displayName ?? '';
      _touristEmailCtrl.text = user.email ?? '';
    }
    _paymentPhoneCtrl.text = '0712345678'; // Default Safaricom test prefix
  }

  @override
  void dispose() {
    _touristNameCtrl.dispose();
    _touristEmailCtrl.dispose();
    _touristPhoneCtrl.dispose();
    _specialRequestsCtrl.dispose();
    _paymentPhoneCtrl.dispose();
    super.dispose();
  }

  int get _nights {
    if (_checkOutDate == null) return 1;
    final diff = _checkOutDate!.difference(_checkInDate).inDays;
    return diff <= 0 ? 1 : diff;
  }

  double get _calculatedTotal {
    final basePrice = widget.serviceItem.price;
    if (widget.provider.businessType == 'hotel') {
      return basePrice * _nights;
    }
    return basePrice * _guests;
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  // ==========================================
  // PAYMENT PROCESSING & GATEWAY SIMULATION
  // ==========================================

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
      _currentStep = 3;
      _processingStatusText = _selectedMethod == 'daraja_mpesa'
          ? 'Connecting to Safaricom Daraja M-Pesa Gateway...'
          : 'Connecting to Payment Gateway...';
      _errorMessage = null;
    });

    try {
      // Step A: STK push prompt initiation
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() {
        _processingStatusText = _selectedMethod == 'daraja_mpesa'
            ? 'STK Push sent to ${_paymentPhoneCtrl.text.trim()}! Please enter PIN on phone...'
            : 'Sending authentication prompt to mobile wallet...';
      });

      // Show simulated STK PIN popup for Daraja M-Pesa if user is on mobile/web
      if (_selectedMethod == 'daraja_mpesa' || _selectedMethod == 'telebirr') {
        final authorized = await _showStkPinSimulationDialog();
        if (!authorized) {
          if (!mounted) return;
          setState(() {
            _isProcessing = false;
            _paymentSuccess = false;
            _currentStep = 4;
            _errorMessage = 'Payment was cancelled or PIN was entered incorrectly.';
          });
          return;
        }
      } else {
        await Future.delayed(const Duration(seconds: 2));
      }

      if (!mounted) return;
      setState(() {
        _processingStatusText = 'Verifying transaction with gateway...';
      });

      await Future.delayed(const Duration(milliseconds: 1200));

      // Generate unique Ethiopian payment reference
      final randomDigits = Random().nextInt(900000) + 100000;
      final txPrefix = _selectedMethod == 'daraja_mpesa'
          ? 'SAF-MPESA-ET'
          : _selectedMethod == 'telebirr'
              ? 'TB-ET'
              : _selectedMethod == 'cbe_birr'
                  ? 'CBE-ET'
                  : 'CARD-ET';
      _transactionId = '$txPrefix-$randomDigits';

      final user = _auth.currentUser;
      final touristUid = user?.uid ?? 'tourist-${DateTime.now().millisecondsSinceEpoch}';

      // 1. Create Reservation Doc
      final reservation = Reservation(
        id: '',
        touristId: touristUid,
        touristName: _touristNameCtrl.text.trim(),
        touristEmail: _touristEmailCtrl.text.trim(),
        touristPhone: _touristPhoneCtrl.text.trim(),
        providerId: widget.provider.id,
        providerName: widget.provider.businessName,
        serviceId: widget.serviceItem.id,
        serviceName: widget.serviceItem.name,
        serviceType: widget.provider.businessType,
        checkInDate: _checkInDate,
        checkOutDate: _checkOutDate,
        numberOfGuests: _guests,
        totalAmount: _calculatedTotal,
        specialRequests: _specialRequestsCtrl.text.trim(),
        status: 'pending', // Waiting for provider to accept
      );

      _createdReservationId = await _service.createReservation(reservation);

      // 2. Create Payment Doc
      final payment = Payment(
        id: '',
        userId: touristUid,
        bookingId: _createdReservationId,
        providerId: widget.provider.id,
        amount: _calculatedTotal,
        paymentMethod: _selectedMethod,
        transactionId: _transactionId,
        status: 'completed',
        receiptUrl: 'https://receipts.ethioar.guide/tx/$_transactionId',
        createdAt: DateTime.now(),
      );

      _createdPaymentId = await _service.createPayment(payment);

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _paymentSuccess = true;
        _currentStep = 4;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _paymentSuccess = false;
        _currentStep = 4;
        _errorMessage = 'Gateway error: $e';
      });
    }
  }

  Future<bool> _showStkPinSimulationDialog() async {
    final pinCtrl = TextEditingController();
    bool confirmed = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _selectedMethod == 'daraja_mpesa' ? Colors.green.shade50 : Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.phone_android,
                color: _selectedMethod == 'daraja_mpesa' ? Colors.green.shade700 : Colors.blue.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedMethod == 'daraja_mpesa' ? 'Safaricom M-Pesa PIN' : 'Telebirr PIN Prompt',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pay ${_calculatedTotal.toStringAsFixed(2)} ETB to ${widget.provider.businessName}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Sent to: ${_paymentPhoneCtrl.text.trim()}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Enter 4-Digit M-Pesa PIN',
                hintText: '••••',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              confirmed = false;
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedMethod == 'daraja_mpesa' ? Colors.green.shade700 : Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              confirmed = true;
              Navigator.of(ctx).pop();
            },
            child: const Text('Authorize Payment'),
          ),
        ],
      ),
    );
    return confirmed;
  }

  // ==========================================
  // WIDGET STEP BUILDERS
  // ==========================================

  Widget _buildStep1Details() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Service header card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.provider.businessType == 'hotel'
                          ? Icons.hotel
                          : widget.provider.businessType == 'restaurant'
                              ? Icons.restaurant
                              : Icons.directions_car,
                      color: Colors.teal.shade800,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.serviceItem.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.provider.businessName,
                          style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.serviceItem.formattedPrice} • ${widget.serviceItem.capacityLabel}',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tourist Contact Form
          const Text('1. Tourist Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          TextFormField(
            controller: _touristNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Full Name *',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _touristPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _touristEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Booking schedule
          const Text('2. Schedule & Guests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text('Check-In: ${_formatDate(_checkInDate)}'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _checkInDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _checkInDate = picked;
                        if (_checkOutDate != null && _checkOutDate!.isBefore(picked)) {
                          _checkOutDate = picked.add(const Duration(days: 1));
                        }
                      });
                    }
                  },
                ),
              ),
              if (widget.provider.businessType == 'hotel') ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event, size: 16),
                    label: Text('Check-Out: ${_checkOutDate != null ? _formatDate(_checkOutDate!) : 'Pick'}'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _checkOutDate ?? _checkInDate.add(const Duration(days: 1)),
                        firstDate: _checkInDate.add(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _checkOutDate = picked);
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Guest Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.provider.businessType == 'hotel' ? 'Number of Guests:' : 'Quantity / Guests:',
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _guests > 1 ? () => setState(() => _guests--) : null,
                  ),
                  Text('$_guests', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(() => _guests++),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: _specialRequestsCtrl,
            decoration: const InputDecoration(
              labelText: 'Special Requests / Notes (Optional)',
              prefixIcon: Icon(Icons.notes),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (_touristNameCtrl.text.trim().isEmpty) {
                SnackbarHelper.show(context, 'Please enter your name.');
                return;
              }
              setState(() => _currentStep = 1);
            },
            child: const Text('Review Booking Summary →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Review() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Order summary card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long, color: Colors.teal.shade800),
                      const SizedBox(width: 8),
                      const Text('Booking Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 24),
                  _summaryRow('Service', widget.serviceItem.name),
                  _summaryRow('Provider', widget.provider.businessName),
                  _summaryRow('Tourist Name', _touristNameCtrl.text.trim()),
                  _summaryRow('Dates', widget.provider.businessType == 'hotel'
                      ? '${_formatDate(_checkInDate)} - ${_formatDate(_checkOutDate!)} ($_nights night${_nights == 1 ? '' : 's'})'
                      : _formatDate(_checkInDate)),
                  _summaryRow('Guests', '$_guests guest${_guests == 1 ? '' : 's'}'),
                  if (_specialRequestsCtrl.text.trim().isNotEmpty)
                    _summaryRow('Special Note', _specialRequestsCtrl.text.trim()),
                  const Divider(height: 24),
                  _summaryRow('Base Price', '${widget.serviceItem.price.toStringAsFixed(2)} ETB'),
                  _summaryRow('Service Fee (5%)', '${(_calculatedTotal * 0.05).toStringAsFixed(2)} ETB'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total to Pay:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
                        Text(
                          '${_calculatedTotal.toStringAsFixed(2)} ETB',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.teal.shade900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  child: const Text('← Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => setState(() => _currentStep = 2),
                  child: const Text('Proceed to Payment →', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3PaymentMethod() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Select Payment Gateway', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 6),
          Text('Supported Ethiopian mobile wallets and cards:', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 16),

          // 1. Safaricom Daraja M-Pesa
          _paymentMethodTile(
            id: 'daraja_mpesa',
            title: 'Safaricom M-Pesa (Daraja STK)',
            subtitle: 'Instant STK Push on Safaricom Ethiopia',
            icon: Icons.flash_on,
            iconColor: Colors.green.shade700,
            bgColor: Colors.green.shade50,
            badge: 'Recommended',
          ),

          // 2. Telebirr
          _paymentMethodTile(
            id: 'telebirr',
            title: 'Telebirr',
            subtitle: 'Ethio Telecom Mobile Money',
            icon: Icons.account_balance_wallet,
            iconColor: Colors.blue.shade700,
            bgColor: Colors.blue.shade50,
          ),

          // 3. CBE Birr
          _paymentMethodTile(
            id: 'cbe_birr',
            title: 'CBE Birr',
            subtitle: 'Commercial Bank of Ethiopia',
            icon: Icons.account_balance,
            iconColor: Colors.purple.shade700,
            bgColor: Colors.purple.shade50,
          ),

          // 4. Card
          _paymentMethodTile(
            id: 'card',
            title: 'Debit / Credit Card',
            subtitle: 'Visa, Mastercard & Local Bank Cards',
            icon: Icons.credit_card,
            iconColor: Colors.orange.shade700,
            bgColor: Colors.orange.shade50,
          ),

          const SizedBox(height: 16),

          // Phone / details input for selected method
          if (_selectedMethod == 'daraja_mpesa' || _selectedMethod == 'telebirr' || _selectedMethod == 'cbe_birr') ...[
            Text(
              _selectedMethod == 'daraja_mpesa'
                  ? 'Safaricom Phone Number for STK Push:'
                  : 'Mobile Number for ${_selectedMethod == 'telebirr' ? 'Telebirr' : 'CBE Birr'}:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _paymentPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone_android),
                hintText: _selectedMethod == 'daraja_mpesa' ? '07XXXXXXXX or 2517XXXXXXXX' : '09XXXXXXXX',
                border: const OutlineInputBorder(),
                helperText: 'You will receive an instant push prompt to enter your PIN',
              ),
            ),
            const SizedBox(height: 20),
          ],

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 1),
                  child: const Text('← Review'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedMethod == 'daraja_mpesa' ? Colors.green.shade700 : Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.lock),
                  label: Text(
                    'Pay ${_calculatedTotal.toStringAsFixed(0)} ETB Now',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onPressed: _processPayment,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentMethodTile({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    String? badge,
  }) {
    final isSelected = _selectedMethod == id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? bgColor.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? iconColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: () => setState(() => _selectedMethod = id),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        trailing: Radio<String>(
          value: id,
          groupValue: _selectedMethod,
          activeColor: iconColor,
          onChanged: (val) {
            if (val != null) setState(() => _selectedMethod = val);
          },
        ),
      ),
    );
  }

  Widget _buildStep4Processing() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(strokeWidth: 4),
            const SizedBox(height: 24),
            Text(
              'Processing Payment...',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
            ),
            const SizedBox(height: 12),
            Text(
              _processingStatusText,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade900),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Please keep this window open while the transaction is being verified.',
                      style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep5Result() {
    if (!_paymentSuccess) {
      // FAILED STATE
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline, size: 64, color: Colors.red.shade700),
              ),
              const SizedBox(height: 18),
              const Text('Payment Failed', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 10),
              Text(
                _errorMessage ?? 'Your transaction could not be completed. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () => setState(() => _currentStep = 2),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel and Return'),
              ),
            ],
          ),
        ),
      );
    }

    // SUCCESS STATE
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green.shade700),
                const SizedBox(height: 12),
                const Text(
                  'Payment & Booking Successful!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your reservation request has been submitted to ${widget.provider.businessName}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.green.shade900),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Receipt details card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(height: 20),
                  _summaryRow('Transaction ID', _transactionId),
                  _summaryRow('Method', _selectedMethod == 'daraja_mpesa' ? 'Safaricom M-Pesa (Daraja)' : _selectedMethod.toUpperCase()),
                  _summaryRow('Amount Paid', '${_calculatedTotal.toStringAsFixed(2)} ETB'),
                  _summaryRow('Status', 'PAID / COMPLETED'),
                  _summaryRow('Reservation Status', 'Pending Provider Acceptance'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.bookmark_border),
            label: const Text('View in My Reservations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MyReservationsPage()),
              );
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done & Return to Provider'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String stepTitle;
    switch (_currentStep) {
      case 0:
        stepTitle = '1. Booking Details';
        break;
      case 1:
        stepTitle = '2. Review Booking';
        break;
      case 2:
        stepTitle = '3. Choose Payment';
        break;
      case 3:
        stepTitle = 'Processing Payment';
        break;
      case 4:
        stepTitle = _paymentSuccess ? 'Booking Confirmed' : 'Payment Failed';
        break;
      default:
        stepTitle = 'Book Service';
    }

    return AppScaffold(
      title: stepTitle,
      body: _currentStep == 0
          ? _buildStep1Details()
          : _currentStep == 1
              ? _buildStep2Review()
              : _currentStep == 2
                  ? _buildStep3PaymentMethod()
                  : _currentStep == 3
                      ? _buildStep4Processing()
                      : _buildStep5Result(),
    );
  }
}
