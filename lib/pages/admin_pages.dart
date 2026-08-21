import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/landmark.dart';
import '../services/firestore_service.dart';
import '../widgets/app_scaffold.dart';
import 'map_picker.dart';

class AddLandmarkPage extends StatefulWidget {
  final Landmark? landmark; // when provided, page works in edit mode
  final String? id;

  const AddLandmarkPage({super.key, this.landmark, this.id});

  @override
  State<AddLandmarkPage> createState() => _AddLandmarkPageState();
}

class _AddLandmarkPageState extends State<AddLandmarkPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _categoryController = TextEditingController(text: 'heritage');
  final _imageUrlController = TextEditingController();
  final _entranceFeeController = TextEditingController(text: '0');
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  bool _saving = false;
  bool _locationPicked = false;

  static const List<Map<String, String>> _sampleImages = [
    {
      'title': 'Fasil Ghebbi (Gondar)',
      'url': 'https://images.unsplash.com/photo-1578575437130-527eed3abbec?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Lalibela Rock Church',
      'url': 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Simien Mountains',
      'url': 'https://images.unsplash.com/photo-1516426122078-c23e76319801?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Lake Tana (Bahir Dar)',
      'url': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Aksum Obelisk',
      'url': 'https://images.unsplash.com/photo-1590523277543-a94d2e4eb00b?auto=format&fit=crop&w=800&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.landmark != null) {
      final lm = widget.landmark!;
      _nameController.text = lm.name;
      _descriptionController.text = lm.description;
      _cityController.text = lm.city;
      _categoryController.text = lm.category;
      _imageUrlController.text = lm.imageUrl;
      _entranceFeeController.text = lm.entranceFee > 0 ? lm.entranceFee.toStringAsFixed(0) : '0';
      _latitudeController.text = lm.latitude.toString();
      _longitudeController.text = lm.longitude.toString();
      _locationPicked = true;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_locationPicked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a location on the map first.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final name = _nameController.text;
      final description = _descriptionController.text;
      final lat = double.parse(_latitudeController.text);
      final lng = double.parse(_longitudeController.text);
      final city = _cityController.text;
      final category = _categoryController.text;
      final imageUrl = _imageUrlController.text.trim();
      final entranceFee = double.tryParse(_entranceFeeController.text.trim()) ?? 0.0;

      if (widget.id != null) {
        await FirestoreService().updateLandmark(
          id: widget.id!,
          name: name,
          description: description,
          latitude: lat,
          longitude: lng,
          city: city,
          category: category,
          imageUrl: imageUrl,
          entranceFee: entranceFee,
        );
      } else {
        await FirestoreService().addLandmark(
          name: name,
          description: description,
          latitude: lat,
          longitude: lng,
          city: city,
          category: category,
          imageUrl: imageUrl,
          entranceFee: entranceFee,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.id != null ? 'Landmark updated.' : 'Landmark saved successfully.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save landmark: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose();
    _entranceFeeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.id != null ? 'Edit Landmark' : 'Add Landmark',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Landmark name',
                prefixIcon: Icon(Icons.place),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City (e.g. Gondar, Lalibela)',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category (e.g. heritage, nature)',
                      prefixIcon: Icon(Icons.category),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _entranceFeeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Entrance / Admission Fee (ETB)',
                hintText: 'e.g. 200 (or 0 for free entry)',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
                suffixText: 'ETB',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (double.tryParse(v.trim()) == null) return 'Please enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),
            // ── Photo / Image URL section ──────────────────────────
            Text('Tourist Place Photo', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _imageUrlController,
              decoration: InputDecoration(
                labelText: 'Photo URL (http:// or https://)',
                prefixIcon: const Icon(Icons.photo_camera),
                suffixIcon: _imageUrlController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _imageUrlController.clear()),
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            if (_imageUrlController.text.trim().isNotEmpty)
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  _imageUrlController.text.trim(),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: Text('Invalid image URL or cannot load preview', style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            const Text('Or pick a sample photo:', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _sampleImages.map((sample) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.image, size: 16),
                      label: Text(sample['title']!, style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        setState(() {
                          _imageUrlController.text = sample['url']!;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_locationPicked)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Selected location', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Latitude: ${_latitudeController.text}'),
                        Text('Longitude: ${_longitudeController.text}'),
                      ],
                    ),
                  )
                else
                  const Text('No location selected yet. Tap the button below to pick a place on the map.'),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    LatLng? init;
                    if (_locationPicked) {
                      final lat = double.tryParse(_latitudeController.text);
                      final lng = double.tryParse(_longitudeController.text);
                      if (lat != null && lng != null) {
                        init = LatLng(lat, lng);
                      }
                    }
                    final result = await Navigator.of(context).push<LatLng>(
                      MaterialPageRoute(
                        builder: (_) => MapPickerPage(initialPosition: init),
                      ),
                    );
                    if (result != null) {
                      _latitudeController.text = result.latitude.toStringAsFixed(6);
                      _longitudeController.text = result.longitude.toStringAsFixed(6);
                      _locationPicked = true;
                      if (mounted) setState(() {});
                    }
                  },
                  icon: const Icon(Icons.map),
                  label: Text(_locationPicked ? 'Change location on map' : 'Pick location on map'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : 'Save Landmark'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Admin: Manage Users & Roles ──────────────────────────────────────────────
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final FirestoreService _fs = FirestoreService();
  bool _loading = true;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    _users = await _fs.listUsers();
    setState(() => _loading = false);
  }

  Future<void> _setRole(String uid, String role) async {
    await _fs.setUserRole(uid, role);
    await _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Manage Users & Roles',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, i) {
                final u = _users[i];
                final currentRole = (u['role'] as String?) ?? 'tourist';
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade50,
                      child: Text(
                        ((u['name'] as String?) ?? (u['email'] as String?) ?? 'U')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                      ),
                    ),
                    title: Text(
                      (u['name'] as String?)?.isNotEmpty == true
                          ? u['name']
                          : (u['email'] ?? 'Unknown'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(u['email'] ?? ''),
                    trailing: DropdownButton<String>(
                      value: currentRole,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'tourist',    child: Text('🧭 Tourist')),
                        DropdownMenuItem(value: 'tour_guide', child: Text('🗺️ Tour Guide')),
                        DropdownMenuItem(value: 'provider',   child: Text('🏢 Provider')),
                        DropdownMenuItem(value: 'admin',      child: Text('👑 Admin')),
                      ],
                      onChanged: (v) async {
                        if (v != null) await _setRole(u['uid'] as String, v);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
