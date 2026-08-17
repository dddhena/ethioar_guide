import 'package:flutter/material.dart';
import '../../models/guide.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/guide_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/snackbar_helper.dart';

class GuideProfilePage extends StatefulWidget {
  final Guide? existing;
  final UserProfile? user;

  const GuideProfilePage({super.key, this.existing, this.user});

  @override
  State<GuideProfilePage> createState() => _GuideProfilePageState();
}

class _GuideProfilePageState extends State<GuideProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final GuideService _guides = GuideService();
  final AuthService _auth = AuthService();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _languagesCtrl;
  late final TextEditingController _qualificationsCtrl;
  late final TextEditingController _experienceCtrl;
  late final TextEditingController _priceCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    final u = widget.user;
    _nameCtrl = TextEditingController(text: g?.name ?? u?.name ?? '');
    _bioCtrl = TextEditingController(text: g?.bio ?? u?.bio ?? '');
    _phoneCtrl = TextEditingController(text: g?.phone ?? u?.phone ?? '');
    _languagesCtrl = TextEditingController(text: g?.languages.join(', ') ?? 'English, Amharic');
    _qualificationsCtrl = TextEditingController(text: g?.qualifications.join(', ') ?? '');
    _experienceCtrl = TextEditingController(text: '${g?.experienceYears ?? 1}');
    _priceCtrl = TextEditingController(text: g != null ? g.price.toStringAsFixed(0) : '1500');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    _languagesCtrl.dispose();
    _qualificationsCtrl.dispose();
    _experienceCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  List<String> _splitCsv(String raw) => raw
      .split(RegExp(r'[,•|]'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _auth.currentUser;
    if (user == null) {
      SnackbarHelper.show(context, 'Please sign in first.');
      return;
    }

    setState(() => _saving = true);
    try {
      final availability = widget.existing?.availability ??
          {for (final d in Guide.weekdays) d: d != 'Sunday'};

      final guide = Guide(
        id: widget.existing?.id ?? '',
        userId: user.uid,
        name: _nameCtrl.text.trim(),
        email: user.email ?? widget.user?.email ?? '',
        phone: _phoneCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        languages: _splitCsv(_languagesCtrl.text),
        qualifications: _splitCsv(_qualificationsCtrl.text),
        experienceYears: int.tryParse(_experienceCtrl.text) ?? 1,
        price: double.tryParse(_priceCtrl.text) ?? 0,
        rating: widget.existing?.rating ?? 0,
        reviewCount: widget.existing?.reviewCount ?? 0,
        availability: availability,
        status: 'active',
        createdAt: widget.existing?.createdAt,
      );

      if (widget.existing == null) {
        await _guides.createGuideProfile(guide);
      } else {
        await _guides.updateGuideProfile(guide.copyWith(id: widget.existing!.id));
      }

      if (!mounted) return;
      SnackbarHelper.show(context, 'Guide profile saved');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) SnackbarHelper.show(context, 'Could not save profile: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.existing == null ? 'Create Guide Profile' : 'My Profile',
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bioCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Bio',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _languagesCtrl,
              decoration: const InputDecoration(
                labelText: 'Languages (comma separated)',
                prefixIcon: Icon(Icons.translate),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _qualificationsCtrl,
              decoration: const InputDecoration(
                labelText: 'Qualifications (comma separated)',
                prefixIcon: Icon(Icons.workspace_premium),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _experienceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Experience (years)',
                      prefixIcon: Icon(Icons.timeline),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Day rate (ETB)',
                      prefixText: 'ETB ',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : 'Save Changes'),
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
