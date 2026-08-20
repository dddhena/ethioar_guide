import 'package:flutter/material.dart';
import '../models/landmark.dart';
import '../models/trip.dart';
import '../services/auth_service.dart';
import '../services/trip_service.dart';
import '../pages/create_trip_page.dart';
import '../theme/ethio_theme.dart';

class AddToTripSheet extends StatefulWidget {
  final Landmark landmark;

  const AddToTripSheet({super.key, required this.landmark});

  static Future<void> show(BuildContext context, Landmark landmark) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddToTripSheet(landmark: landmark),
    );
  }

  @override
  State<AddToTripSheet> createState() => _AddToTripSheetState();
}

class _AddToTripSheetState extends State<AddToTripSheet> {
  final _tripService = TripService();
  final _auth = AuthService();
  List<TouristTrip> _trips = [];
  String? _selectedTripId;
  bool _loading = true;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    _trips = await _tripService.getTrips(uid);
    if (_trips.isNotEmpty) _selectedTripId = _trips.first.id;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _add() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _selectedTripId == null) return;
    setState(() => _adding = true);
    await _tripService.addPlaceToTrip(
      touristId: uid,
      tripId: _selectedTripId!,
      placeId: widget.landmark.id,
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.landmark.name} added to trip')),
      );
    }
  }

  Future<void> _createNewTrip() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateTripPage()),
    );
    if (created == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: EthioColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Add to Trip', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(widget.landmark.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          const Text('Select a trip', style: TextStyle(color: EthioColors.muted)),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
          else if (_trips.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No trips yet. Create one to start planning.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          else
            ..._trips.map((trip) => RadioListTile<String>(
                  value: trip.id,
                  groupValue: _selectedTripId,
                  onChanged: (v) => setState(() => _selectedTripId = v),
                  title: Text(trip.name),
                  subtitle: Text(trip.dateRangeLabel),
                  contentPadding: EdgeInsets.zero,
                )),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _createNewTrip,
              icon: const Icon(Icons.add),
              label: const Text('Create New Trip'),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: (_adding || _selectedTripId == null) ? null : _add,
            child: _adding
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Add to Trip'),
          ),
        ],
      ),
    );
  }
}
