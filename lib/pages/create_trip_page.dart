import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/trip_service.dart';
import '../theme/ethio_theme.dart';
import '../widgets/app_scaffold.dart';

class CreateTripPage extends StatefulWidget {
  const CreateTripPage({super.key});

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'My Ethiopian Adventure');
  final _countryController = TextEditingController(text: 'Ethiopia');
  DateTime _startDate = DateTime.now().add(const Duration(days: 2));
  DateTime _endDate = DateTime.now().add(const Duration(days: 9));
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
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
      await TripService().createTrip(
        touristId: user.uid,
        name: _nameController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        country: _countryController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip created successfully! 🎉')),
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
    return AppScaffold(
      title: 'Create New Trip',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
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

            const Text(
              'Start date',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: EthioColors.charcoal),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickStartDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EthioColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: EthioColors.forest),
                    const SizedBox(width: 12),
                    Text(_formatDate(_startDate), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    const Icon(Icons.edit_calendar, size: 18, color: EthioColors.muted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'End date',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: EthioColors.charcoal),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickEndDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EthioColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: EthioColors.terracotta),
                    const SizedBox(width: 12),
                    Text(_formatDate(_endDate), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    const Icon(Icons.edit_calendar, size: 18, color: EthioColors.muted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: EthioColors.forest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create Trip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
