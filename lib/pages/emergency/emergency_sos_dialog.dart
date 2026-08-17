import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/emergency_service.dart';
import '../../services/location_service.dart';
import '../../widgets/snackbar_helper.dart';

class EmergencySosDialog extends StatefulWidget {
  const EmergencySosDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const EmergencySosDialog(),
    );
  }

  @override
  State<EmergencySosDialog> createState() => _EmergencySosDialogState();
}

class _EmergencySosDialogState extends State<EmergencySosDialog> {
  final EmergencyService _emergencyService = EmergencyService();
  final AuthService _auth = AuthService();

  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  String _selectedType = 'medical'; // 'medical', 'security', 'lost', 'general'
  bool _fetchingLocation = true;
  double _lat = 9.0320; // Default Addis Ababa
  double _lng = 38.7483;
  String _locationStatus = 'Detecting current GPS coordinates...';
  bool _submitting = false;
  bool _submitted = false;
  String _alertId = '';

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    try {
      final loc = await LocationService.getCurrentPositionWeb();
      if (loc != null && mounted) {
        setState(() {
          _lat = loc['latitude']!;
          _lng = loc['longitude']!;
          _locationStatus = 'GPS Acquired: ${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)}';
          _fetchingLocation = false;
        });
      } else if (mounted) {
        setState(() {
          _locationStatus = 'GPS approximate (${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)})';
          _fetchingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationStatus = 'GPS approximate (${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)})';
          _fetchingLocation = false;
        });
      }
    }
  }

  Future<void> _sendSos() async {
    final user = _auth.currentUser;
    setState(() => _submitting = true);

    try {
      final id = await _emergencyService.triggerEmergency(
        touristId: user?.uid ?? 'tourist-guest',
        touristName: user?.displayName ?? 'Tourist',
        touristPhone: _phoneCtrl.text.trim(),
        touristEmail: user?.email ?? '',
        latitude: _lat,
        longitude: _lng,
        locationName: 'Ethiopia GPS (${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)})',
        emergencyType: _selectedType,
        message: _noteCtrl.text.trim().isEmpty ? 'Immediate SOS assistance needed!' : _noteCtrl.text.trim(),
      );

      if (mounted) {
        setState(() {
          _submitting = false;
          _submitted = true;
          _alertId = id;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        SnackbarHelper.show(context, 'Failed to broadcast SOS: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
              child: Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('SOS Broadcast Sent!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🚨 Admin Emergency Team Alerted', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 4),
                  Text('Your GPS location (${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)}) has been transmitted to the response team.', style: TextStyle(fontSize: 12, color: Colors.red.shade900)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text('Ethiopian Emergency Helplines:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            const Text('• 991 - Federal Police Emergency', style: TextStyle(fontSize: 12)),
            const Text('• 907 - Red Cross Ambulance', style: TextStyle(fontSize: 12)),
            const Text('• 997 - Tourist Security Police', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I Understand'),
          ),
        ],
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.red.shade100, shape: BoxShape.circle),
            child: Icon(Icons.warning, color: Colors.red.shade800, size: 28),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Emergency SOS Alert',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select emergency nature to notify Admin response team:',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            // Emergency category tiles
            _typeOption('medical', '🚑 Medical Assistance', Colors.red),
            _typeOption('security', '👮 Security / Threat', Colors.orange.shade900),
            _typeOption('lost', '📍 Lost / Stranded', Colors.blue.shade800),
            _typeOption('general', '⚠️ Urgent General Help', Colors.purple.shade800),

            const SizedBox(height: 12),

            // GPS coordinates status
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(_fetchingLocation ? Icons.hourglass_top : Icons.location_on, size: 18, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_locationStatus, style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Contact Phone Number (Optional)',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Brief Emergency Note (Optional)',
                hintText: 'e.g. Near church gate, need medical aid...',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          icon: _submitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.send),
          label: Text(_submitting ? 'Transmitting...' : 'TRANSMIT SOS NOW 🚨'),
          onPressed: _submitting ? null : _sendSos,
        ),
      ],
    );
  }

  Widget _typeOption(String type, String label, Color color) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 13, color: isSelected ? color : Colors.black87)),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
