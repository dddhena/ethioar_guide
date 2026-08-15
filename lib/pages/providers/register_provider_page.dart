import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/service_provider.dart';
import '../../services/auth_service.dart';
import '../../services/service_provider_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/snackbar_helper.dart';
import '../map_picker.dart';

class RegisterProviderPage extends StatefulWidget {
  const RegisterProviderPage({super.key});

  @override
  State<RegisterProviderPage> createState() => _RegisterProviderPageState();
}

class _RegisterProviderPageState extends State<RegisterProviderPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();
  final ServiceProviderService _service = ServiceProviderService();

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Addis Ababa');
  final _phoneCtrl = TextEditingController();
  final _openingHoursCtrl = TextEditingController(text: '24/7');

  String _businessType = 'hotel'; // 'hotel', 'restaurant', 'transport'
  String _priceRange = '\$\$';
  double _lat = 9.0320;
  double _lon = 38.7469;
  bool _locationPicked = false;
  bool _submitting = false;

  final List<String> _commonFacilities = [
    'Free WiFi',
    'Swimming Pool',
    'Restaurant & Bar',
    'Free Breakfast',
    'Spa & Wellness',
    'Airport Shuttle',
    '4WD Vehicle',
    'English Speaking Guide',
    'Parking',
    'Traditional Coffee Ceremony',
    'Live Music',
  ];
  final Set<String> _selectedFacilities = {'Free WiFi'};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    _openingHoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _auth.currentUser;
    if (user == null) {
      SnackbarHelper.show(context, 'Please sign in first to register your business.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final provider = ServiceProvider(
        id: '',
        userId: user.uid,
        businessName: _nameCtrl.text.trim(),
        businessType: _businessType,
        description: _descCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        latitude: _lat,
        longitude: _lon,
        phone: _phoneCtrl.text.trim(),
        facilities: _selectedFacilities.toList(),
        priceRange: _priceRange,
        openingHours: _openingHoursCtrl.text.trim(),
        approvalStatus: 'approved', // Auto-approved for frictionless demo & testing
      );

      await _service.registerServiceProvider(provider);

      if (mounted) {
        SnackbarHelper.show(context, '🎉 Business registered successfully!');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.show(context, 'Failed to register business: $e');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Register Service Business',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Business Category',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildTypeChip('hotel', '🏨 Hotel / Lodge'),
                        const SizedBox(width: 8),
                        _buildTypeChip('restaurant', '🍽️ Restaurant'),
                        const SizedBox(width: 8),
                        _buildTypeChip('transport', '🚗 Transport'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Business / Company Name',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Business Description & Overview',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'City / Region',
                      prefixIcon: Icon(Icons.location_city),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Contact',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Street Address / Specific Area',
                prefixIcon: Icon(Icons.place),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _openingHoursCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Opening Hours',
                      prefixIcon: Icon(Icons.access_time),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _priceRange,
                    decoration: const InputDecoration(
                      labelText: 'Price Level',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: '\$', child: Text(r'$ - Budget')),
                      DropdownMenuItem(value: '\$\$', child: Text(r'$$ - Standard')),
                      DropdownMenuItem(value: '\$\$\$', child: Text(r'$$$ - Premium')),
                      DropdownMenuItem(value: '\$\$\$\$', child: Text(r'$$$$ - Luxury')),
                    ],
                    onChanged: (v) => setState(() => _priceRange = v ?? '\$\$'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Location Coordinate Picker
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('GPS Location on Map', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${_lat.toStringAsFixed(4)}, ${_lon.toStringAsFixed(4)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade50,
                        foregroundColor: Colors.teal.shade900,
                      ),
                      icon: const Icon(Icons.map),
                      label: Text(_locationPicked ? 'Change Location on Map' : 'Pick Location on Map'),
                      onPressed: () async {
                        final result = await Navigator.of(context).push<LatLng>(
                          MaterialPageRoute(
                            builder: (_) => MapPickerPage(initialPosition: LatLng(_lat, _lon)),
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            _lat = result.latitude;
                            _lon = result.longitude;
                            _locationPicked = true;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Facilities Checklist
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Facilities & Services Offered', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _commonFacilities.map((facility) {
                        final isSelected = _selectedFacilities.contains(facility);
                        return FilterChip(
                          label: Text(facility),
                          selected: isSelected,
                          selectedColor: Colors.teal.shade700,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedFacilities.add(facility);
                              } else {
                                _selectedFacilities.remove(facility);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
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
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text(
                _submitting ? 'Registering...' : 'Submit Business Registration',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label) {
    final isSelected = _businessType == type;
    return Expanded(
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.teal.shade900)),
        selected: isSelected,
        selectedColor: Colors.teal.shade700,
        backgroundColor: Colors.teal.shade50,
        onSelected: (selected) {
          if (selected) setState(() => _businessType = type);
        },
      ),
    );
  }
}
