import 'package:flutter/material.dart';
import '../../models/guide.dart';
import '../../services/guide_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/snackbar_helper.dart';

class GuideAvailabilityPage extends StatefulWidget {
  final Guide guide;

  const GuideAvailabilityPage({super.key, required this.guide});

  @override
  State<GuideAvailabilityPage> createState() => _GuideAvailabilityPageState();
}

class _GuideAvailabilityPageState extends State<GuideAvailabilityPage> {
  late Map<String, bool> _days;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _days = {
      for (final d in Guide.weekdays) d: widget.guide.availability[d] ?? true,
    };
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await GuideService().updateAvailability(widget.guide.id, _days);
      if (!mounted) return;
      SnackbarHelper.show(context, 'Availability saved');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) SnackbarHelper.show(context, 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Availability',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tell tourists which weekdays you can take bookings.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                for (final day in Guide.weekdays)
                  SwitchListTile(
                    title: Text(day),
                    subtitle: Text(_days[day] == true ? 'Available' : 'Not available'),
                    value: _days[day] ?? false,
                    onChanged: (v) => setState(() => _days[day] = v),
                  ),
              ],
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: Text(_saving ? 'Saving...' : 'Save Availability'),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
