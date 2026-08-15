import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/landmark.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_scaffold.dart';
import 'camera_preview.dart';
import 'map_picker.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthService _auth = AuthService();
  final FirestoreService _fs = FirestoreService();
  String _name = 'Guest';
  String _role = 'user';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _name = 'Guest';
        _role = 'user';
        _loading = false;
      });
      return;
    }

    try {
      final profile = await _fs.getUserProfile(uid);
      if (!mounted) return;
      setState(() {
        _name = profile['name'] as String? ?? 'Guest';
        _role = profile['role'] as String? ?? 'user';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _name = 'Guest';
        _role = 'user';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Dashboard',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(child: Text(_name.isNotEmpty ? _name[0] : 'G')),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome, $_name', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 4),
                            Text('Role: $_role'),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.explore),
                  label: const Text('AR Tourist Guide'),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CameraPreviewPage())),
                ),
                const SizedBox(height: 12),
                if (_role == 'admin') ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Admin: Manage Users'),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminPage())),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.location_on),
                    label: const Text('Add Landmark'),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddLandmarkPage())),
                  ),
                ],
              ],
            ),
    );
  }
}

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
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  bool _saving = false;
  bool _locationPicked = false;

  @override
  void initState() {
    super.initState();
    if (widget.landmark != null) {
      final lm = widget.landmark!;
      _nameController.text = lm.name;
      _descriptionController.text = lm.description;
      _latitudeController.text = lm.latitude.toString();
      _longitudeController.text = lm.longitude.toString();
      _locationPicked = true;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_locationPicked != true) {
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

      if (widget.id != null) {
        await FirestoreService().updateLandmark(
          id: widget.id!,
          name: name,
          description: description,
          latitude: lat,
          longitude: lng,
          city: city,
          category: category,
        );
      } else {
        await FirestoreService().addLandmark(
          name: name,
          description: description,
          latitude: lat,
          longitude: lng,
          city: city,
          category: category,
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
              decoration: const InputDecoration(labelText: 'Landmark name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_locationPicked == true)
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
                    if (_locationPicked == true) {
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
                  label: Text(_locationPicked == true ? 'Change location on map' : 'Pick location on map'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : 'Save Landmark'),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple admin page to manage roles
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
    setState(() {
      _loading = false;
    });
  }

  Future<void> _setRole(String uid, String role) async {
    await _fs.setUserRole(uid, role);
    await _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'User Management',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, i) {
                final u = _users[i];
                return ListTile(
                  title: Text(u['name'] ?? u['email'] ?? 'Unknown'),
                  subtitle: Text(u['email'] ?? ''),
                  trailing: DropdownButton<String>(
                    value: (u['role'] as String?) ?? 'user',
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('User')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (v) async {
                      if (v != null) await _setRole(u['uid'], v);
                    },
                  ),
                );
              },
            ),
    );
  }
}
