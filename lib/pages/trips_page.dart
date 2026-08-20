import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../models/landmark.dart';
import '../models/reservation.dart';
import '../models/trip.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/guide_service.dart';
import '../services/interaction_service.dart';
import '../services/service_provider_service.dart';
import '../services/trip_service.dart';
import '../theme/ethio_theme.dart';
import '../widgets/notification_bell_button.dart';
import '../widgets/place_image.dart';
import 'create_trip_page.dart';
import 'favorites_page.dart';
import 'guides/my_guide_bookings_page.dart';
import 'landmark_detail_page.dart';
import 'providers/my_reservations_page.dart';
import 'trip_detail_page.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  final _auth = AuthService();
  final _tripService = TripService();
  final _fs = FirestoreService();
  final _interaction = InteractionService();
  final _guideService = GuideService();
  final _providerService = ServiceProviderService();

  List<TouristTrip> _trips = [];
  List<Landmark> _savedLandmarks = [];
  List<Booking> _guideBookings = [];
  List<Reservation> _reservations = [];
  Map<String, Landmark> _landmarksMap = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final allLandmarks = await _fs.fetchLandmarks();
      _landmarksMap = {for (final l in allLandmarks) l.id: l};

      _trips = await _tripService.getTrips(uid);
      final favIds = await _interaction.getFavoritedAttractions(uid);
      _savedLandmarks = allLandmarks.where((l) => favIds.contains(l.id)).toList();

      final bookings = await _guideService.getTouristBookingsStream(uid).first.timeout(
        const Duration(seconds: 3),
        onTimeout: () => [],
      );
      _guideBookings = bookings;

      final resList = await _providerService.getTouristReservationsStream(uid).first.timeout(
        const Duration(seconds: 3),
        onTimeout: () => [],
      );
      _reservations = resList;
    } catch (e) {
      print('Error loading trips page data: $e');
    }

    if (mounted) setState(() => _loading = false);
  }

  void _createNewTrip() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateTripPage()),
    );
    if (created == true) {
      _loadAll();
    }
  }

  List<TouristTrip> get _activeTrips => _trips.where((t) => !t.isCompleted).toList();
  List<TouristTrip> get _completedTrips => _trips.where((t) => t.isCompleted).toList();

  String _formatTripDestinations(TouristTrip trip) {
    if (trip.placeIds.isEmpty) return 'Ethiopia';
    final names = trip.placeIds
        .map((id) => _landmarksMap[id]?.city.isNotEmpty == true
            ? _landmarksMap[id]!.city
            : _landmarksMap[id]?.name ?? '')
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    if (names.isEmpty) return 'Ethiopia';
    return names.take(3).join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EthioColors.cream,
      appBar: AppBar(
        title: const Text('My Trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: EthioColors.forest, size: 28),
            tooltip: 'Create New Trip',
            onPressed: _createNewTrip,
          ),
          const NotificationBellButton(color: EthioColors.charcoal),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Text('Plan your journey', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('Organize your places, bookings and activities', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 20),

                  // ── Active Trips Section ─────────────────────────────
                  if (_activeTrips.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: EthioColors.divider),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.luggage_outlined, size: 48, color: EthioColors.stone),
                          const SizedBox(height: 12),
                          const Text('No active trips right now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          const Text('Create a trip to organize destinations, activities and bookings.',
                              textAlign: TextAlign.center, style: TextStyle(color: EthioColors.muted, fontSize: 13)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _createNewTrip,
                            icon: const Icon(Icons.add),
                            label: const Text('Create New Trip'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: EthioColors.forest,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._activeTrips.map((trip) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _TripCard(
                            trip: trip,
                            destinationsSummary: _formatTripDestinations(trip),
                            placeCount: trip.placeIds.length,
                            bookingCount: _reservations.length,
                            activityCount: _guideBookings.length,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => TripDetailPage(trip: trip)),
                              );
                              _loadAll();
                            },
                          ),
                        )),

                  // ── Upcoming Activities ──────────────────────────────
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Upcoming Activities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: EthioColors.charcoal)),
                      if (_guideBookings.isNotEmpty)
                        TextButton(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyGuideBookingsPage())),
                          child: const Text('See all'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_guideBookings.isEmpty && _reservations.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: EthioColors.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tour_outlined, color: EthioColors.forest, size: 32),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('No upcoming bookings', style: TextStyle(fontWeight: FontWeight.w600)),
                                SizedBox(height: 2),
                                Text('Book a tour guide or hotel to see your schedule here.', style: TextStyle(fontSize: 12, color: EthioColors.muted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    ..._guideBookings.take(2).map((b) => _UpcomingActivityCard(
                          dateText: b.formattedTourDate,
                          title: b.tourName.isNotEmpty ? b.tourName : 'Guided Tour Experience',
                          subtitle: '👤 Guide: ${b.guideName.isNotEmpty ? b.guideName : "Local Guide"}',
                          status: b.status,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyGuideBookingsPage())),
                        )),
                    ..._reservations.take(2).map((r) => _UpcomingActivityCard(
                          dateText: r.formattedDates,
                          title: r.serviceName,
                          subtitle: '🏢 Provider: ${r.providerName}',
                          status: r.status,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyReservationsPage())),
                        )),
                  ],

                  // ── Saved for Later ❤️ ──────────────────────────────
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Saved for Later ❤️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: EthioColors.charcoal)),
                      TextButton(
                        onPressed: () async {
                          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesPage()));
                          _loadAll();
                        },
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_savedLandmarks.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: EthioColors.divider),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.favorite_border, color: EthioColors.terracotta, size: 28),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text('No saved places yet. Heart places on Explore to save them here!',
                                style: TextStyle(color: EthioColors.muted, fontSize: 13)),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 170,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _savedLandmarks.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final lm = _savedLandmarks[i];
                          return SizedBox(
                            width: 140,
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => LandmarkDetailPage(landmark: lm)),
                                  );
                                  _loadAll();
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    PlaceImage(landmark: lm, height: 95, borderRadius: const BorderRadius.vertical(top: Radius.circular(14))),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(lm.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          const SizedBox(height: 2),
                                          Text(lm.city.isNotEmpty ? lm.city : lm.category, style: const TextStyle(fontSize: 11, color: EthioColors.muted)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // ── Completed Trips ─────────────────────────────────
                  if (_completedTrips.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const Text('Completed Trips', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: EthioColors.charcoal)),
                    const SizedBox(height: 10),
                    ..._completedTrips.map((ct) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const Text('🎓', style: TextStyle(fontSize: 22)),
                            title: Text(ct.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${ct.country} • ${ct.dateRangeLabel}'),
                            trailing: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TripDetailPage(trip: ct))),
                          ),
                        )),
                  ],
                ],
              ),
            ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final TouristTrip trip;
  final String destinationsSummary;
  final int placeCount;
  final int bookingCount;
  final int activityCount;
  final VoidCallback onTap;

  const _TripCard({
    required this.trip,
    required this.destinationsSummary,
    required this.placeCount,
    required this.bookingCount,
    required this.activityCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: EthioColors.cardShadow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🇪🇹', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      trip.name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: EthioColors.charcoal),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: EthioColors.forest.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Active', style: TextStyle(color: EthioColors.forest, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_month, size: 16, color: EthioColors.terracotta),
                  const SizedBox(width: 6),
                  Text(trip.dateRangeLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: EthioColors.muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      destinationsSummary,
                      style: const TextStyle(fontSize: 13, color: EthioColors.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: EthioColors.cream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('$placeCount places', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const Text('•', style: TextStyle(color: EthioColors.muted)),
                    Text('$bookingCount bookings', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const Text('•', style: TextStyle(color: EthioColors.muted)),
                    Text('$activityCount activities', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EthioColors.forest,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('View Trip →'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingActivityCard extends StatelessWidget {
  final String dateText;
  final String title;
  final String subtitle;
  final String status;
  final VoidCallback onTap;

  const _UpcomingActivityCard({
    required this.dateText,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EthioColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: EthioColors.forest),
              const SizedBox(width: 6),
              Text(dateText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: EthioColors.muted, fontSize: 13)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: Size.zero,
                side: const BorderSide(color: EthioColors.forest),
              ),
              child: const Text('View Details', style: TextStyle(fontSize: 12, color: EthioColors.forest)),
            ),
          ),
        ],
      ),
    );
  }
}
