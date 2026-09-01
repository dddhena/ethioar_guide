import 'package:flutter/material.dart';
import '../../models/service_provider.dart';
import '../../services/service_provider_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/snackbar_helper.dart';

class ProviderEditProfilePage extends StatefulWidget {
  final ServiceProvider provider;

  const ProviderEditProfilePage({super.key, required this.provider});

  @override
  State<ProviderEditProfilePage> createState() => _ProviderEditProfilePageState();
}

class _ProviderEditProfilePageState extends State<ProviderEditProfilePage> {
  final ServiceProviderService _service = ServiceProviderService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _businessNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _phoneController;
  late TextEditingController _openingHoursController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(text: widget.provider.businessName);
    _descriptionController = TextEditingController(text: widget.provider.description);
    _addressController = TextEditingController(text: widget.provider.address);
    _cityController = TextEditingController(text: widget.provider.city);
    _phoneController = TextEditingController(text: widget.provider.phone);
    _openingHoursController = TextEditingController(text: widget.provider.openingHours);
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _openingHoursController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final updatedProvider = widget.provider.copyWith(
        businessName: _businessNameController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        phone: _phoneController.text.trim(),
        openingHours: _openingHoursController.text.trim(),
      );

      await _service.updateServiceProvider(updatedProvider);

      if (mounted) {
        SnackbarHelper.show(context, 'Profile updated successfully');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.show(context, 'Error updating profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Edit Profile',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.teal.shade100,
                      child: Text(
                        widget.provider.typeIcon,
                        style: const TextStyle(fontSize: 50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.provider.typeDisplayName,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Business Information
              const Text(
                'Business Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) => value?.trim().isEmpty ?? true ? 'Business name is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) => value?.trim().isEmpty ?? true ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) => value?.trim().isEmpty ?? true ? 'Address is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (value) => value?.trim().isEmpty ?? true ? 'City is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) => value?.trim().isEmpty ?? true ? 'Phone number is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _openingHoursController,
                decoration: const InputDecoration(
                  labelText: 'Opening Hours',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                  hintText: 'e.g., 9:00 AM - 10:00 PM',
                ),
              ),
              const SizedBox(height: 24),

              // Current Status Display
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Rating: ${widget.provider.rating.toStringAsFixed(1)} (${widget.provider.reviewCount} reviews)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.attach_money, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Price Range: ${widget.provider.priceRange}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.verified, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Status: ${widget.provider.approvalStatus.toUpperCase()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.provider.isApproved ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}