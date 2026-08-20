import 'package:flutter/material.dart';
import '../models/landmark.dart';
import '../models/trip.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/trip_service.dart';
import '../theme/ethio_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/place_image.dart';
import 'landmark_detail_page.dart';
import 'landmarks_page.dart';

class TripDetailPage extends StatefulWidget {
  final TouristTrip trip;

  const TripDetailPage({super.key, required this.trip});

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  final _fs = FirestoreService();
  final _tripService = TripService();
  final _auth = AuthService();
  late TouristTrip _trip;
  List<Landmark> _places = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    setState(() => _loading = true);
    final all = await _fs.fetchLandmarks();
    _places = all.where((l) => _trip.placeIds.contains(l.id)).toList();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _markCompleted() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _tripService.markCompleted(uid, _trip.id);
    setState(() {
      _trip = _trip.copyWith(status: 'completed');
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip marked as completed! 🎓')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _trip.name,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [EthioColors.forest, EthioColors.forestLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: EthioColors.forest.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🇪🇹', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _trip.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _trip.dateRangeLabel,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _trip.status.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Places Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Places to Visit (${_places.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: EthioColors.charcoal),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LandmarksPage()),
                  );
                  _loadPlaces();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Place'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_places.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EthioColors.divider),
              ),
              child: Column(
                children: [
                  const Icon(Icons.map_outlined, size: 48, color: EthioColors.muted),
                  const SizedBox(height: 12),
                  const Text('No places added to this trip yet', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text('Explore attractions and tap "Add to Trip" to organize your itinerary.',
                      textAlign: TextAlign.center, style: TextStyle(color: EthioColors.muted, fontSize: 13)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LandmarksPage()),
                      );
                      _loadPlaces();
                    },
                    icon: const Icon(Icons.explore),
                    label: const Text('Browse Places'),
                  ),
                ],
              ),
            )
          else
            ..._places.map((place) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: SizedBox(
                      width: 60,
                      height: 60,
                      child: PlaceImage(landmark: place, height: 60, borderRadius: BorderRadius.circular(8)),
                    ),
                    title: Text(place.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${place.city.isNotEmpty ? place.city : place.category} • ⭐ ${place.rating.toStringAsFixed(1)}'),
                    trailing: const Icon(Icons.chevron_right, color: EthioColors.muted),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => LandmarkDetailPage(landmark: place)),
                      );
                    },
                  ),
                )),

          const SizedBox(height: 24),
          if (!_trip.isCompleted)
            OutlinedButton.icon(
              onPressed: _markCompleted,
              icon: const Icon(Icons.check_circle_outline, color: EthioColors.forest),
              label: const Text('Mark Trip as Completed', style: TextStyle(color: EthioColors.forest)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: EthioColors.forest),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }
}
