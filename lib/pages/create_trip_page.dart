import 'package:flutter/material.dart';
import '../models/landmark.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/payment_service.dart';
import '../services/trip_service.dart';
import '../theme/ethio_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/place_image.dart';

class CreateTripPage extends StatefulWidget {
  final List<String>? initialPlaceIds;

  const CreateTripPage({super.key, this.initialPlaceIds});

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'My Ethiopian Adventure');
  final _countryController = TextEditingController(text: 'Ethiopia');
  final _payerPhoneController = TextEditingController();
  final _txRefController = TextEditingController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 2));
  DateTime _endDate = DateTime.now().add(const Duration(days: 9));

  final FirestoreService _fs = FirestoreService();
  final PaymentService _paymentService = PaymentService();

  List<Landmark> _allLandmarks = [];
  final Set<String> _selectedPlaceIds = {};
  bool _loadingLandmarks = true;
  bool _saving = false;

  // Payment configuration
  bool _payEntranceNow = true;
  String _selectedPaymentMethod = 'telebirr'; // telebirr, daraja_mpesa, cbe_birr, card

  @override
  void initState() {
    super.initState();
    if (widget.initialPlaceIds != null) {
      _selectedPlaceIds.addAll(widget.initialPlaceIds!);
    }
    _loadLandmarks();
    _generateDefaultRef();
  }

  void _generateDefaultRef() {
    _txRefController.text = PaymentService.generateTransactionReference(_selectedPaymentMethod);
  }

  Future<void> _loadLandmarks() async {
    try {
      final list = await _fs.fetchLandmarks();
      if (mounted) {
        setState(() {
          _allLandmarks = list;
          _loadingLandmarks = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingLandmarks = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _payerPhoneController.dispose();
    _txRefController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 7));
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isAfter(_startDate) ? _endDate : _startDate.add(const Duration(days: 1)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  double get _totalEntranceFee {
    double total = 0.0;
    for (final id in _selectedPlaceIds) {
      final match = _allLandmarks.where((l) => l.id == id);
      if (match.isNotEmpty) {
        total += match.first.entranceFee;
      }
    }
    return total;
  }

  void _openPlaceSelector() {
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
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: EthioColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select Tourism Places',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_selectedPlaceIds.length} selected',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: EthioColors.forest),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _loadingLandmarks
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: _allLandmarks.length,
                                itemBuilder: (context, index) {
                                  final place = _allLandmarks[index];
                                  final isSelected = _selectedPlaceIds.contains(place.id);

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: isSelected ? EthioColors.forest : EthioColors.divider,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    color: isSelected ? EthioColors.forest.withValues(alpha: 0.05) : Colors.white,
                                    child: CheckboxListTile(
                                      value: isSelected,
                                      activeColor: EthioColors.forest,
                                      onChanged: (bool? val) {
                                        setModalState(() {
                                          if (val == true) {
                                            _selectedPlaceIds.add(place.id);
                                          } else {
                                            _selectedPlaceIds.remove(place.id);
                                          }
                                        });
                                        setState(() {});
                                      },
                                      secondary: SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: PlaceImage(
                                          landmark: place,
                                          height: 50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      title: Text(
                                        place.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      subtitle: Row(
                                        children: [
                                          Text(
                                            place.city.isNotEmpty ? place.city : place.category,
                                            style: const TextStyle(fontSize: 12, color: EthioColors.muted),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: place.entranceFee > 0
                                                  ? Colors.amber.shade50
                                                  : Colors.green.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              place.formattedEntranceFee,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: place.entranceFee > 0
                                                    ? Colors.amber.shade900
                                                    : Colors.green.shade800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EthioColors.forest,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Done (${_selectedPlaceIds.length} places)'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = AuthService().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to create a trip')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final tripName = _nameController.text.trim();
      final totalFee = _totalEntranceFee;
      final shouldPayNow = _payEntranceNow && totalFee > 0;

      // 1. Create the Trip
      final tripId = await TripService().createTrip(
        touristId: user.uid,
        name: tripName,
        startDate: _startDate,
        endDate: _endDate,
        country: _countryController.text.trim(),
        placeIds: _selectedPlaceIds.toList(),
        entranceFeeTotal: totalFee,
        entrancePaymentStatus: shouldPayNow ? 'pending' : (totalFee == 0 ? 'verified' : 'unpaid'),
      );

      // 2. If paying now, create entrance payment for admin verification
      if (shouldPayNow) {
        final paymentId = await _paymentService.createEntrancePayment(
          userId: user.uid,
          amount: totalFee,
          paymentMethod: _selectedPaymentMethod,
          tripId: tripId,
          title: 'Entrance Tickets: $tripName (${_selectedPlaceIds.length} places)',
          payerName: user.displayName ?? user.email ?? 'Tourist',
          payerPhone: _payerPhoneController.text.trim(),
          transactionId: _txRefController.text.trim(),
        );

        await TripService().updateTripEntrancePayment(
          touristId: user.uid,
          tripId: tripId,
          status: 'pending',
          paymentId: paymentId,
          entranceFeeTotal: totalFee,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(shouldPayNow
              ? 'Trip created! Entrance fee payment submitted for Admin verification. 🎟️'
              : 'Trip created successfully! 🎉'),
          backgroundColor: EthioColors.forest,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create trip: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPlaces = _allLandmarks.where((l) => _selectedPlaceIds.contains(l.id)).toList();
    final totalFee = _totalEntranceFee;

    return AppScaffold(
      title: 'Create New Trip',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Destination country card
            const Text(
              'Where are you going?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: EthioColors.charcoal),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EthioColors.divider),
              ),
              child: const Row(
                children: [
                  Text('🇪🇹', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 12),
                  Text('Ethiopia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Trip Name
            const Text(
              'Trip name',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: EthioColors.charcoal),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. My Ethiopia Adventure',
                prefixIcon: const Icon(Icons.luggage_outlined),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: EthioColors.divider),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a trip name' : null,
            ),
            const SizedBox(height: 20),

            // Dates
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start date',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: EthioColors.charcoal),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickStartDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: EthioColors.divider),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month, size: 18, color: EthioColors.forest),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _formatDate(_startDate),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'End date',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: EthioColors.charcoal),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickEndDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: EthioColors.divider),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month, size: 18, color: EthioColors.terracotta),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _formatDate(_endDate),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Section: Add Places to this Trip ─────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Places to Visit',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: EthioColors.charcoal),
                ),
                TextButton.icon(
                  onPressed: _openPlaceSelector,
                  icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                  label: Text(_selectedPlaceIds.isEmpty ? 'Select Places' : 'Add / Change'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_selectedPlaceIds.isEmpty)
              InkWell(
                onTap: _openPlaceSelector,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: EthioColors.divider, style: BorderStyle.solid),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.place_outlined, size: 36, color: EthioColors.forest),
                      SizedBox(height: 8),
                      Text(
                        'Tap here to add tourism places to this trip',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Choose attractions like Lalibela, Aksum, Gondar, Simien...',
                        style: TextStyle(color: EthioColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: EthioColors.forest.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...selectedPlaces.map((place) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: PlaceImage(landmark: place, height: 44),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      place.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      place.city.isNotEmpty ? place.city : place.category,
                                      style: const TextStyle(fontSize: 12, color: EthioColors.muted),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                place.formattedEntranceFee,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: place.entranceFee > 0 ? Colors.amber.shade900 : Colors.green.shade800,
                                  fontSize: 12,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    _selectedPlaceIds.remove(place.id);
                                  });
                                },
                              ),
                            ],
                          ),
                        )),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Places: ${selectedPlaces.length}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Entrance Total: ${totalFee.toStringAsFixed(0)} ETB',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: EthioColors.forest, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // ── Section: Entrance Fee & Admin Verification ──────────────
            if (totalFee > 0) ...[
              const SizedBox(height: 24),
              const Text(
                'Entrance Fee & Payment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: EthioColors.charcoal),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.confirmation_number_outlined, color: Colors.amber, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Entrance Admission', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(
                                'Admission for ${selectedPlaces.length} selected attraction${selectedPlaces.length > 1 ? "s" : ""}',
                                style: const TextStyle(fontSize: 12, color: EthioColors.muted),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${totalFee.toStringAsFixed(0)} ETB',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Payment timing choice
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Pay Entrance Now'),
                            selected: _payEntranceNow,
                            selectedColor: Colors.teal.shade700,
                            labelStyle: TextStyle(
                              color: _payEntranceNow ? Colors.white : EthioColors.charcoal,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) => setState(() => _payEntranceNow = true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Pay Later'),
                            selected: !_payEntranceNow,
                            selectedColor: Colors.teal.shade700,
                            labelStyle: TextStyle(
                              color: !_payEntranceNow ? Colors.white : EthioColors.charcoal,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) => setState(() => _payEntranceNow = false),
                          ),
                        ),
                      ],
                    ),

                    if (_payEntranceNow) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Select Payment Method:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),

                      // Method Radios
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _PaymentMethodChip(
                              label: 'Telebirr',
                              icon: '📱',
                              selected: _selectedPaymentMethod == 'telebirr',
                              onTap: () {
                                setState(() {
                                  _selectedPaymentMethod = 'telebirr';
                                  _generateDefaultRef();
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _PaymentMethodChip(
                              label: 'M-Pesa',
                              icon: '🟢',
                              selected: _selectedPaymentMethod == 'daraja_mpesa',
                              onTap: () {
                                setState(() {
                                  _selectedPaymentMethod = 'daraja_mpesa';
                                  _generateDefaultRef();
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _PaymentMethodChip(
                              label: 'CBE Birr',
                              icon: '🏦',
                              selected: _selectedPaymentMethod == 'cbe_birr',
                              onTap: () {
                                setState(() {
                                  _selectedPaymentMethod = 'cbe_birr';
                                  _generateDefaultRef();
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _PaymentMethodChip(
                              label: 'Card',
                              icon: '💳',
                              selected: _selectedPaymentMethod == 'card',
                              onTap: () {
                                setState(() {
                                  _selectedPaymentMethod = 'card';
                                  _generateDefaultRef();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Transaction Reference Field
                      TextFormField(
                        controller: _txRefController,
                        decoration: InputDecoration(
                          labelText: 'Transaction Reference ID',
                          hintText: 'e.g. TB-589211',
                          prefixIcon: const Icon(Icons.receipt_long),
                          fillColor: Colors.white,
                          filled: true,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.refresh, size: 18),
                            tooltip: 'Generate new ID',
                            onPressed: _generateDefaultRef,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (v) => _payEntranceNow && (v == null || v.trim().isEmpty)
                            ? 'Please enter the transaction reference'
                            : null,
                      ),
                      const SizedBox(height: 10),

                      // Payer Phone Field
                      TextFormField(
                        controller: _payerPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Payer Phone (Optional)',
                          hintText: 'e.g. +251 91 234 5678',
                          prefixIcon: const Icon(Icons.phone),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Notice regarding Admin verification
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.shield_outlined, size: 16, color: Colors.blue.shade800),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Admin Verification Required: Your entrance fee transaction will be reviewed and verified by an administrator before tickets are confirmed.',
                                style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: EthioColors.forest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _payEntranceNow && totalFee > 0 ? 'Create Trip & Pay Entrance' : 'Create Trip',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentMethodChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.teal.shade700 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.teal.shade700 : EthioColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : EthioColors.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
