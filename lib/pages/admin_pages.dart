import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
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
  final _site3dModelUrlController = TextEditingController();
  final _entranceFeeController = TextEditingController(text: '0');
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  bool _saving = false;
  bool _locationPicked = false;
  List<CulturalAttire> _selectedAttires = [];
  List<NativeAnimal> _selectedAnimals = [];

  static const List<Map<String, String>> _sample3DModels = [
    {
      'title': 'Bete Giyorgis 3D (Lalibela)',
      'url': 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
    },
    {
      'title': 'Fasil Castle Keep 3D (Gondar)',
      'url': 'https://modelviewer.dev/shared-assets/models/shishkebab.glb',
    },
    {
      'title': 'Axum Obelisk Monolith 3D',
      'url': 'https://modelviewer.dev/shared-assets/models/reflective-sphere.glb',
    },
  ];

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
      _site3dModelUrlController.text = lm.site3dModelUrl;
      _entranceFeeController.text = lm.entranceFee > 0 ? lm.entranceFee.toStringAsFixed(0) : '0';
      _latitudeController.text = lm.latitude.toString();
      _longitudeController.text = lm.longitude.toString();
      _locationPicked = true;
      _selectedAttires = List.from(lm.culturalAttires);
      _selectedAnimals = List.from(lm.nativeAnimals);
    } else {
      // Default initial templates for convenient admin workflow
      _selectedAttires = [
        CulturalAttire.defaultPresets[0],
        CulturalAttire.defaultPresets[1],
      ];
      _selectedAnimals = [
        NativeAnimal.defaultPresets[0],
        NativeAnimal.defaultPresets[1],
      ];
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
      final site3dModelUrl = _site3dModelUrlController.text.trim();
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
          site3dModelUrl: site3dModelUrl,
          culturalAttires: _selectedAttires,
          nativeAnimals: _selectedAnimals,
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
          site3dModelUrl: site3dModelUrl,
          culturalAttires: _selectedAttires,
          nativeAnimals: _selectedAnimals,
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
    _site3dModelUrlController.dispose();
    _entranceFeeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _showAddAttireDialog() {
    final nameCtrl = TextEditingController();
    final regionCtrl = TextEditingController(text: 'Ethiopia');
    final photoUrlCtrl = TextEditingController();
    String wearType = 'cape_kaba';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DefaultTabController(
              length: 2,
              child: Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.checkroom_rounded, color: Colors.deepOrange),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Add Cultural Clothes (Real-Life Photo)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const TabBar(
                      labelColor: Colors.deepOrange,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.deepOrange,
                      tabs: [
                        Tab(icon: Icon(Icons.photo_camera, size: 18), text: 'Real Photo Upload'),
                        Tab(icon: Icon(Icons.history_edu, size: 18), text: 'Authentic Presets'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tab 1: Custom Real-Life Photo Upload
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: nameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Attire Name (e.g. Royal Gold Kaba, Habesha Kemis)',
                                    prefixIcon: Icon(Icons.title),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: regionCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Region / Cultural Origin (e.g. Gondar, Oromia, Tigray)',
                                    prefixIcon: Icon(Icons.place),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: photoUrlCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Real Photo URL (http:// or https://)',
                                    hintText: 'https://.../real_clothes_cutout.png',
                                    prefixIcon: const Icon(Icons.image),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.photo_library),
                                      tooltip: 'Pick from Gallery',
                                      onPressed: () async {
                                        final picker = ImagePicker();
                                        final picked = await picker.pickImage(source: ImageSource.gallery);
                                        if (picked != null) {
                                          photoUrlCtrl.text = picked.path;
                                          setModalState(() {});
                                        }
                                      },
                                    ),
                                  ),
                                  onChanged: (_) => setModalState(() {}),
                                ),
                                const SizedBox(height: 8),
                                if (photoUrlCtrl.text.isNotEmpty)
                                  Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.deepOrange.shade200),
                                      color: Colors.grey.shade100,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: photoUrlCtrl.text.startsWith('http')
                                        ? Image.network(photoUrlCtrl.text, fit: BoxFit.contain)
                                        : const Center(child: Icon(Icons.photo, size: 48, color: Colors.deepOrange)),
                                  ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<String>(
                                  value: wearType,
                                  decoration: const InputDecoration(
                                    labelText: 'Wear Placement Type',
                                    prefixIcon: Icon(Icons.accessibility_new),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'cape_kaba', child: Text('Imperial Cape / Kaba')),
                                    DropdownMenuItem(value: 'full_body', child: Text('Full Body Dress / Kemis')),
                                    DropdownMenuItem(value: 'shawl_netela', child: Text('Shoulder Shawl / Netela')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => wearType = val);
                                  },
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepOrange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () {
                                    final name = nameCtrl.text.trim();
                                    final photo = photoUrlCtrl.text.trim();
                                    if (name.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please enter an attire name.')),
                                      );
                                      return;
                                    }
                                    final customAttire = CulturalAttire(
                                      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                                      name: name,
                                      description: 'Authentic cultural attire added by admin from real-life photo.',
                                      region: regionCtrl.text.trim().isNotEmpty ? regionCtrl.text.trim() : 'Ethiopia',
                                      previewUrl: photo.isNotEmpty ? photo : CulturalAttire.defaultPresets.first.previewUrl,
                                      overlayUrl: photo,
                                      wearType: wearType,
                                      gender: 'unisex',
                                    );
                                    setState(() {
                                      _selectedAttires.add(customAttire);
                                    });
                                    Navigator.pop(ctx);
                                  },
                                  icon: const Icon(Icons.add_photo_alternate),
                                  label: const Text('Add Real-Life Photo Attire'),
                                ),
                              ],
                            ),
                          ),

                          // Tab 2: Authentic Presets
                          ListView.separated(
                            itemCount: CulturalAttire.defaultPresets.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, index) {
                              final preset = CulturalAttire.defaultPresets[index];
                              final isAlreadyAdded = _selectedAttires.any((a) => a.id == preset.id);

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(preset.previewUrl),
                                ),
                                title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                subtitle: Text('${preset.region} • Real photo', style: const TextStyle(fontSize: 11)),
                                trailing: isAlreadyAdded
                                    ? const Chip(label: Text('Added', style: TextStyle(fontSize: 10)))
                                    : ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.deepOrange,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () {
                                          setState(() => _selectedAttires.add(preset));
                                          Navigator.pop(ctx);
                                        },
                                        child: const Text('Add'),
                                      ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddAnimalDialog() {
    final nameCtrl = TextEditingController();
    final speciesCtrl = TextEditingController(text: 'Native Fauna');
    final photoUrlCtrl = TextEditingController();
    String behaviorType = 'horse_rope';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DefaultTabController(
              length: 2,
              child: Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.pets_rounded, color: Colors.brown),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Add Native Animal (Real-Life Photo)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const TabBar(
                      labelColor: Colors.brown,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.brown,
                      tabs: [
                        Tab(icon: Icon(Icons.photo_camera, size: 18), text: 'Real Photo Upload'),
                        Tab(icon: Icon(Icons.pets, size: 18), text: 'Fauna Presets'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tab 1: Real-Life Photo Custom Animal
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: nameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Animal Name (e.g. Abyssinian Horse, Shepherd Dog)',
                                    prefixIcon: Icon(Icons.title),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: speciesCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Species / Classification',
                                    prefixIcon: Icon(Icons.science),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: photoUrlCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Real Photo URL (http:// or https://)',
                                    hintText: 'https://.../real_animal_photo.png',
                                    prefixIcon: const Icon(Icons.image),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.photo_library),
                                      tooltip: 'Pick from Gallery',
                                      onPressed: () async {
                                        final picker = ImagePicker();
                                        final picked = await picker.pickImage(source: ImageSource.gallery);
                                        if (picked != null) {
                                          photoUrlCtrl.text = picked.path;
                                          setModalState(() {});
                                        }
                                      },
                                    ),
                                  ),
                                  onChanged: (_) => setModalState(() {}),
                                ),
                                const SizedBox(height: 8),
                                if (photoUrlCtrl.text.isNotEmpty)
                                  Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.brown.shade200),
                                      color: Colors.grey.shade100,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: photoUrlCtrl.text.startsWith('http')
                                        ? Image.network(photoUrlCtrl.text, fit: BoxFit.contain)
                                        : const Center(child: Icon(Icons.pets, size: 48, color: Colors.brown)),
                                  ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<String>(
                                  value: behaviorType,
                                  decoration: const InputDecoration(
                                    labelText: 'Real-Life Character Behavior',
                                    prefixIcon: Icon(Icons.psychology),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'horse_rope',
                                      child: Text('🐎 Horse with Reins Rope (Held by User)'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'barking_dog',
                                      child: Text('🐕 Guard Dog that Barks at Camera'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'ambient_wildlife',
                                      child: Text('🏔️ Highland Wildlife (Standing/Perched)'),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => behaviorType = val);
                                  },
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.brown,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () {
                                    final name = nameCtrl.text.trim();
                                    final photo = photoUrlCtrl.text.trim();
                                    if (name.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please enter an animal name.')),
                                      );
                                      return;
                                    }
                                    final customAnimal = NativeAnimal(
                                      id: 'animal_${DateTime.now().millisecondsSinceEpoch}',
                                      name: name,
                                      species: speciesCtrl.text.trim().isNotEmpty ? speciesCtrl.text.trim() : 'Fauna',
                                      previewUrl: photo.isNotEmpty ? photo : NativeAnimal.defaultPresets.first.previewUrl,
                                      modelUrl: photo,
                                      behaviorType: behaviorType,
                                      behaviorDescription: behaviorType == 'horse_rope'
                                          ? 'Real-life horse with interactive lead rope connected to user in AR'
                                          : (behaviorType == 'barking_dog'
                                              ? 'Real-life guard dog barking at camera'
                                              : 'Highland endemic animal beside tourist'),
                                      defaultScale: behaviorType == 'horse_rope' ? 1.1 : 0.8,
                                    );
                                    setState(() {
                                      _selectedAnimals.add(customAnimal);
                                    });
                                    Navigator.pop(ctx);
                                  },
                                  icon: const Icon(Icons.add_photo_alternate),
                                  label: const Text('Add Real-Life Photo Animal'),
                                ),
                              ],
                            ),
                          ),

                          // Tab 2: Fauna Presets
                          ListView.separated(
                            itemCount: NativeAnimal.defaultPresets.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, index) {
                              final preset = NativeAnimal.defaultPresets[index];
                              final isAlreadyAdded = _selectedAnimals.any((a) => a.id == preset.id);

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(preset.previewUrl),
                                ),
                                title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                subtitle: Text('${preset.species} • Real photo', style: const TextStyle(fontSize: 11)),
                                trailing: isAlreadyAdded
                                    ? const Chip(label: Text('Added', style: TextStyle(fontSize: 10)))
                                    : ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.brown,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () {
                                          setState(() => _selectedAnimals.add(preset));
                                          Navigator.pop(ctx);
                                        },
                                        child: const Text('Add'),
                                      ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.id != null ? 'Edit Landmark' : 'Add Landmark',
      body: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            
            return ListView(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Landmark name',
                    prefixIcon: Icon(Icons.place),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                SizedBox(height: isMobile ? 10 : 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                SizedBox(height: isMobile ? 10 : 12),
                if (isMobile)
                  Column(
                    children: [
                      TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City (e.g. Gondar, Lalibela)',
                          prefixIcon: Icon(Icons.location_city),
                        ),
                      ),
                      SizedBox(height: isMobile ? 10 : 12),
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category (e.g. heritage, nature)',
                          prefixIcon: Icon(Icons.category),
                        ),
                      ),
                    ],
                  )
                else
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
                SizedBox(height: isMobile ? 10 : 12),
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
                SizedBox(height: isMobile ? 14 : 16),
                // ── Photo / Image URL section ──────────────────────────
                Text('Tourist Place Photo', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: isMobile ? 6 : 8),
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
                SizedBox(height: isMobile ? 6 : 8),
                if (_imageUrlController.text.trim().isNotEmpty)
                  Container(
                    height: isMobile ? 120 : 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      _imageUrlController.text.trim(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: Text('Invalid image URL or cannot load preview', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: isMobile ? 6 : 8),
                const Text('Or pick a sample photo:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                SizedBox(height: isMobile ? 4 : 6),
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
                SizedBox(height: isMobile ? 14 : 16),
                // ── 3D View of the Site Section ─────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.view_in_ar_rounded, color: Colors.indigo, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '3D View of the Site',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Provide a 3D model (.glb) so tourists can inspect and place the heritage site in real-world AR.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                TextFormField(
                  controller: _site3dModelUrlController,
                  decoration: InputDecoration(
                    labelText: '3D Site Model URL (.glb / .gltf)',
                    hintText: 'https://.../model.glb',
                    prefixIcon: const Icon(Icons.threed_rotation),
                    suffixIcon: _site3dModelUrlController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _site3dModelUrlController.clear()),
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                SizedBox(height: isMobile ? 4 : 6),
                const Text('Or choose a heritage 3D model preset:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                SizedBox(height: isMobile ? 4 : 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _sample3DModels.map((sample) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: const Icon(Icons.architecture, size: 16),
                          label: Text(sample['title']!, style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            setState(() {
                              _site3dModelUrlController.text = sample['url']!;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                SizedBox(height: isMobile ? 16 : 20),
                // ── Cultural Clothes & Attire Section ────────────────────────
                Row(
                  children: [
                    const Icon(Icons.checkroom_rounded, color: Colors.deepOrange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cultural Clothes (AR Dress-Up)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showAddAttireDialog,
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: const Text('Add Clothes', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const Text(
                  'When tourists take selfies/photos at this site, they can wear these cultural clothes (Snapchat-style AR lenses).',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                if (_selectedAttires.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No cultural clothes added. Tap "+ Add Clothes" to add regional attires.',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedAttires.map((attire) {
                      return Chip(
                        avatar: const CircleAvatar(
                          backgroundColor: Colors.deepOrange,
                          child: Icon(Icons.checkroom, size: 12, color: Colors.white),
                        ),
                        label: Text('${attire.name} (${attire.region})', style: const TextStyle(fontSize: 12)),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _selectedAttires.remove(attire);
                          });
                        },
                      );
                    }).toList(),
                  ),

                SizedBox(height: isMobile ? 16 : 20),
                // ── Native Animals & Character Section ───────────────────────
                Row(
                  children: [
                    const Icon(Icons.pets_rounded, color: Colors.brown, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Native Animals & Real-Life AR Companions',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showAddAnimalDialog,
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: const Text('Add Animal', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const Text(
                  'When taking photos/videos, the user can stand beside the animal in AR with its real-life behavior (e.g. horse with lead rope, barking guard dog, mountain ibex).',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                if (_selectedAnimals.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.brown.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.brown.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.brown, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No animals added. Tap "+ Add Animal" to attach native wildlife or companions.',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: _selectedAnimals.map((animal) {
                      String behaviorBadge = animal.behaviorType == 'horse_rope'
                          ? '🐎 Lead Rope Reins'
                          : (animal.behaviorType == 'barking_dog'
                              ? '🐕 Guard Dog Bark'
                              : '🏔️ High Altitude Wildlife');

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        elevation: 0.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: const CircleAvatar(
                            backgroundColor: Colors.brown,
                            child: Icon(Icons.pets, size: 14, color: Colors.white),
                          ),
                          title: Text(animal.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(
                            '$behaviorBadge • ${animal.species}\n${animal.behaviorDescription}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _selectedAnimals.remove(animal);
                              });
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                SizedBox(height: isMobile ? 14 : 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_locationPicked)
                      Container(
                        padding: EdgeInsets.all(isMobile ? 10 : 12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Selected location', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: isMobile ? 3 : 4),
                            Text('Latitude: ${_latitudeController.text}'),
                            Text('Longitude: ${_longitudeController.text}'),
                          ],
                        ),
                      )
                    else
                      const Text('No location selected yet. Tap the button below to pick a place on the map.'),
                    SizedBox(height: isMobile ? 6 : 8),
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
                SizedBox(height: isMobile ? 18 : 20),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Saving...' : 'Save Landmark'),
                ),
              ],
            );
          },
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

  String _normalizeRole(String? role) {
    if (role == null) return 'tourist';
    final validRoles = ['tourist', 'tour_guide', 'provider', 'admin'];
    if (validRoles.contains(role)) return role;
    return 'tourist'; // Default to tourist if role is invalid
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Manage Users & Roles',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                
                return ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, i) {
                    final u = _users[i];
                    final currentRole = _normalizeRole(u['role'] as String?);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: isMobile
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.teal.shade50,
                                        child: Text(
                                          ((u['name'] as String?) ?? (u['email'] as String?) ?? 'U')
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              (u['name'] as String?)?.isNotEmpty == true
                                                  ? u['name']
                                                  : (u['email'] ?? 'Unknown'),
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              u['email'] ?? '',
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    value: currentRole,
                                    decoration: InputDecoration(
                                      labelText: 'Role',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
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
                                ],
                              ),
                            )
                          : ListTile(
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
                );
              },
            ),
    );
  }
}
