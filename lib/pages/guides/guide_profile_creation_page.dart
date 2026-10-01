import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/guide_profile.dart';
import '../../services/auth_service.dart';
import '../../services/guide_service.dart';
import '../../theme/ethio_theme.dart';

class GuideProfileCreationPage extends StatefulWidget {
  final GuideProfile? existingProfile;
  const GuideProfileCreationPage({super.key, this.existingProfile});

  @override
  State<GuideProfileCreationPage> createState() => _GuideProfileCreationPageState();
}

class _GuideProfileCreationPageState extends State<GuideProfileCreationPage> {
  final _auth = AuthService();
  final _guideService = GuideService();
  final _formKey = GlobalKey<FormState>();
  
  int _currentStep = 0;
  bool _isLoading = false;
  String? _profileImageUrl;
  
  // Step 1: Personal Information
  final _fullNameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  
  // Step 2: Guide Information
  int _yearsOfExperience = 1;
  final Set<String> _selectedLanguages = {};
  final Set<String> _selectedSpecialties = {};
  final _bioController = TextEditingController();
  
  // Step 3: Services & Pricing
  final Set<String> _selectedServices = {};
  final _priceController = TextEditingController();
  String _pricingType = 'Per Tour';
  
  // Step 4: Availability
  final Set<String> _selectedDays = {};
  final _startTimeController = TextEditingController(text: '09:00 AM');
  final _endTimeController = TextEditingController(text: '05:00 PM');
  
  // Available options
  static const List<String> _languageOptions = [
    'English', 'Amharic', 'Afaan Oromo', 'Tigrinya', 'Arabic', 'French', 'Italian', 'German', 'Spanish'
  ];
  
  static const List<String> _specialtyOptions = [
    'Historical Tours', 'Cultural Tours', 'Religious & Heritage', 
    'Nature', 'Photography', 'Adventure', 'City Tours', 'Food & Culinary'
  ];
  
  static const List<String> _serviceOptions = [
    'Historical Tour', 'Cultural Tour', 'City Walking Tour', 
    'Heritage Tour', 'Nature Tour', 'Customized Tour'
  ];
  
  static const List<String> _dayOptions = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  
  static const List<String> _pricingTypeOptions = [
    'Per Person', 'Per Tour', 'Per Hour'
  ];

  @override
  void initState() {
    super.initState();
    _initializeEmail();
    _loadExistingProfile();
  }

  void _initializeEmail() {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      // Email is auto-loaded from Firebase Auth
    }
  }

  Future<void> _loadExistingProfile() async {
    if (widget.existingProfile != null) {
      final profile = widget.existingProfile!;
      setState(() {
        _profileImageUrl = profile.profileImageUrl;
        _fullNameController.text = profile.fullName;
        _displayNameController.text = profile.displayName;
        _phoneController.text = profile.phoneNumber ?? '';
        _cityController.text = profile.city;
        _yearsOfExperience = profile.yearsOfExperience;
        _selectedLanguages.addAll(profile.languages);
        _selectedSpecialties.addAll(profile.specialties);
        _bioController.text = profile.bio;
        _selectedServices.addAll(profile.services);
        _priceController.text = (profile.pricing['amount'] ?? 0).toString();
        _pricingType = profile.pricing['type'] ?? 'Per Tour';
        _selectedDays.addAll((profile.availability['days'] as List<String>?) ?? []);
        _startTimeController.text = profile.availability['startTime'] ?? '09:00 AM';
        _endTimeController.text = profile.availability['endTime'] ?? '05:00 PM';
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _displayNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _priceController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    
    if (pickedFile != null) {
      setState(() => _isLoading = true);
      try {
        final user = _auth.currentUser;
        if (user != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('guide_profiles')
              .child(user.uid)
              .child('profile.jpg');
          
          final bytes = await pickedFile.readAsBytes();
          await storageRef.putData(bytes);
          final downloadUrl = await storageRef.getDownloadURL();
          
          setState(() {
            _profileImageUrl = downloadUrl;
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload image: $e')),
          );
        }
      }
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _fullNameController.text.isNotEmpty &&
               _displayNameController.text.isNotEmpty &&
               _cityController.text.isNotEmpty;
      case 1:
        return _selectedLanguages.isNotEmpty &&
               _selectedSpecialties.isNotEmpty &&
               _bioController.text.isNotEmpty;
      case 2:
        return _selectedServices.isNotEmpty &&
               _priceController.text.isNotEmpty;
      case 3:
        return _selectedDays.isNotEmpty;
      case 4:
        return true; // Preview step
      default:
        return false;
    }
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final profile = GuideProfile(
        userId: user.uid,
        fullName: _fullNameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        email: user.email ?? '',
        phoneNumber: _phoneController.text.trim(),
        profileImageUrl: _profileImageUrl,
        city: _cityController.text.trim(),
        yearsOfExperience: _yearsOfExperience,
        languages: _selectedLanguages.toList(),
        specialties: _selectedSpecialties.toList(),
        bio: _bioController.text.trim(),
        services: _selectedServices.toList(),
        pricing: {
          'amount': double.tryParse(_priceController.text) ?? 0,
          'type': _pricingType,
        },
        availability: {
          'days': _selectedDays.toList(),
          'startTime': _startTimeController.text,
          'endTime': _endTimeController.text,
        },
        profileCompleted: true,
        createdAt: widget.existingProfile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.existingProfile != null) {
        await _guideService.updateGuideProfileDocument(profile);
      } else {
        await _guideService.createGuideProfileDocument(profile);
      }
      
      if (mounted) {
        if (widget.existingProfile == null) {
          // First-time profile creation, navigate to dashboard
          Navigator.of(context).pushReplacementNamed('/guide-dashboard');
        } else {
          // Editing existing profile, pop back
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    }
  }

  Widget _buildStepIndicator() {
    return Column(
      children: [
        Row(
          children: List.generate(5, (index) {
            final isCompleted = index < _currentStep;
            final isCurrent = index == _currentStep;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? EthioColors.forest
                      : isCurrent
                          ? EthioColors.forestLight
                          : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Text(
          'Step ${_currentStep + 1} of 5',
          style: TextStyle(
            color: EthioColors.muted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildGuideInfoStep();
      case 2:
        return _buildServicesStep();
      case 3:
        return _buildAvailabilityStep();
      case 4:
        return _buildPreviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Photo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: _showImagePicker,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                  image: _profileImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(_profileImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _profileImageUrl == null
                    ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _profileImageUrl != null ? 'Tap to change' : 'Add Profile Photo',
              style: TextStyle(color: EthioColors.forest, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter your full name',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _displayNameController,
            decoration: const InputDecoration(
              labelText: 'Display Name',
              hintText: 'How tourists will see you',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '+251...',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cityController,
            decoration: const InputDecoration(
              labelText: 'City / Location',
              hintText: 'e.g., Addis Ababa, Lalibela',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          Text(
            'Email: ${_auth.currentUser?.email ?? ""}',
            style: TextStyle(color: EthioColors.muted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideInfoStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Years of Experience',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _yearsOfExperience > 1
                    ? () => setState(() => _yearsOfExperience--)
                    : null,
              ),
              Text(
                '$_yearsOfExperience',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => setState(() => _yearsOfExperience++),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Languages Spoken',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _languageOptions.map((lang) {
              final isSelected = _selectedLanguages.contains(lang);
              return FilterChip(
                label: Text(lang),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedLanguages.add(lang);
                    } else {
                      _selectedLanguages.remove(lang);
                    }
                  });
                },
                selectedColor: EthioColors.forest.withValues(alpha: 0.2),
                checkmarkColor: EthioColors.forest,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Areas of Expertise',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _specialtyOptions.map((specialty) {
              final isSelected = _selectedSpecialties.contains(specialty);
              return FilterChip(
                label: Text(specialty),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSpecialties.add(specialty);
                    } else {
                      _selectedSpecialties.remove(specialty);
                    }
                  });
                },
                selectedColor: EthioColors.forest.withValues(alpha: 0.2),
                checkmarkColor: EthioColors.forest,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'About You',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _bioController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Tell tourists about your experience, knowledge, languages, and the type of tours you provide...',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildServicesStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tour Services',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _serviceOptions.map((service) {
              final isSelected = _selectedServices.contains(service);
              return FilterChip(
                label: Text(service),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedServices.add(service);
                    } else {
                      _selectedServices.remove(service);
                    }
                  });
                },
                selectedColor: EthioColors.forest.withValues(alpha: 0.2),
                checkmarkColor: EthioColors.forest,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Pricing',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Guide Fee (ETB)',
              hintText: 'e.g., 1500',
              border: OutlineInputBorder(),
              prefixText: 'ETB ',
            ),
            keyboardType: TextInputType.number,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          const Text(
            'Pricing Type',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _pricingTypeOptions.map((type) {
              final isSelected = _pricingType == type;
              return ChoiceChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _pricingType = type);
                  }
                },
                selectedColor: EthioColors.forest.withValues(alpha: 0.2),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Days',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _dayOptions.map((day) {
              final isSelected = _selectedDays.contains(day);
              return FilterChip(
                label: Text(day),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDays.add(day);
                    } else {
                      _selectedDays.remove(day);
                    }
                  });
                },
                selectedColor: EthioColors.forest.withValues(alpha: 0.2),
                checkmarkColor: EthioColors.forest,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Availability Time',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _startTimeController,
                  decoration: const InputDecoration(
                    labelText: 'From',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 9, minute: 0),
                    );
                    if (time != null) {
                      setState(() {
                        _startTimeController.text = time.format(context);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _endTimeController,
                  decoration: const InputDecoration(
                    labelText: 'To',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 17, minute: 0),
                    );
                    if (time != null) {
                      setState(() {
                        _endTimeController.text = time.format(context);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Preview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : null,
                  child: _profileImageUrl == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  _displayNameController.text.isNotEmpty
                      ? _displayNameController.text
                      : _fullNameController.text,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'New Guide',
                      style: TextStyle(color: EthioColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 4),
                    Text(_cityController.text),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _buildPreviewRow('Languages:', _selectedLanguages.join(' • ')),
                const SizedBox(height: 12),
                _buildPreviewRow('Experience:', '$_yearsOfExperience Years'),
                const SizedBox(height: 12),
                _buildPreviewRow('Specialties:', _selectedSpecialties.join(' • ')),
                const SizedBox(height: 12),
                _buildPreviewRow('About:', _bioController.text, maxLines: 3),
                const SizedBox(height: 12),
                _buildPreviewRow('Services:', _selectedServices.join(', ')),
                const SizedBox(height: 12),
                _buildPreviewRow('Pricing:', 'ETB ${_priceController.text} / $_pricingType'),
                const SizedBox(height: 12),
                _buildPreviewRow('Availability:', _selectedDays.join(', ')),
                const SizedBox(height: 12),
                _buildPreviewRow('Time:', '${_startTimeController.text} - ${_endTimeController.text}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: EthioColors.muted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Guide Profile'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildStepIndicator(),
              const SizedBox(height: 24),
              Expanded(
                child: _buildStepContent(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _currentStep--);
                    },
                    child: const Text('Back'),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_validateCurrentStep()) {
                            if (_currentStep < 4) {
                              setState(() => _currentStep++);
                            } else {
                              _completeProfile();
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill in all required fields')),
                            );
                          }
                        },
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_currentStep < 4 ? 'Continue' : 'Complete Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
