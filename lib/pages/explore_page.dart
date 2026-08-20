import 'package:flutter/material.dart';
import '../models/landmark.dart';
import '../models/recommendation_result.dart';
import '../models/user_interaction.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/interaction_service.dart';
import '../services/journey_preference_service.dart';
import '../services/location_service.dart';
import '../services/recommendation_service.dart';
import '../theme/ethio_theme.dart';
import '../widgets/explore_categories.dart';
import '../widgets/journey/dashboard_widgets.dart';
import '../widgets/notification_bell_button.dart';
import '../widgets/place_image.dart';
import 'camera_preview.dart';
import 'guides/guides_list_page.dart';
import 'journey/guided_tours_browse_page.dart';
import 'landmark_detail_page.dart';
import 'nearby_landmarks_page.dart';
import 'providers/service_providers_list_page.dart';
import 'recommendations_page.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _fs = FirestoreService();
  final _auth = AuthService();
  final _interaction = InteractionService();
  final _recService = RecommendationService();

  bool _loading = true;
  List<Landmark> _landmarks = [];
  List<RecommendationResult> _recommended = [];
  List<NearbyLandmark> _nearby = [];
  List<Landmark> _popular = [];
  String? _selectedCategory;
  double _userLat = 9.032;
  double _userLon = 38.747;
  final _searchController = TextEditingController();

  bool get _isArMode => JourneyPreferenceService.instance.mode == JourneyMode.ar;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final pos = await LocationService.getCurrentPositionWeb();
    if (pos != null) {
      _userLat = pos['latitude']!;
      _userLon = pos['longitude']!;
    }

    _landmarks = await _fs.fetchLandmarks();
    _nearby = LocationService.getNearbyLandmarks(
      currentLat: _userLat,
      currentLon: _userLon,
      landmarks: _landmarks,
      maxRadiusKm: 50,
    );
    _popular = List<Landmark>.from(_landmarks)
      ..sort((a, b) => b.popularityScore.compareTo(a.popularityScore));

    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _recommended = await _recService.getPersonalizedRecommendations(
        touristId: uid,
        landmarks: _landmarks,
        userLatitude: _userLat,
        userLongitude: _userLon,
        selectedCategory: _selectedCategory,
      );
      if (_recommended.isEmpty) {
        _recommended = _recService.getPopularAttractions(
          landmarks: _landmarks,
          userLatitude: _userLat,
          userLongitude: _userLon,
        );
      }
    } else {
      _recommended = _recService.getPopularAttractions(
        landmarks: _landmarks,
        userLatitude: _userLat,
        userLongitude: _userLon,
      );
    }

    if (mounted) setState(() => _loading = false);
  }

  List<ExploreCategory> get _categories {
    final extras = _isArMode ? ExploreCategories.arExtras : ExploreCategories.guidedExtras;
    return [...ExploreCategories.base, ...extras];
  }

  List<Landmark> get _filteredLandmarks {
    final q = _searchController.text.trim().toLowerCase();
    var list = _landmarks;
    if (_selectedCategory != null) {
      if (_selectedCategory == 'hotels' || _selectedCategory == 'food') return list;
      list = list.where((l) => ExploreCategories.matchesCategory(l.category, _selectedCategory!)).toList();
    }
    if (q.isNotEmpty) {
      list = list.where((l) =>
          l.name.toLowerCase().contains(q) ||
          l.city.toLowerCase().contains(q) ||
          l.description.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  void _onCategoryTap(ExploreCategory cat) {
    if (cat.id == 'guides') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GuidesListPage()));
      return;
    }
    if (cat.id == 'guided_tours') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GuidedToursBrowsePage()));
      return;
    }
    if (cat.id == 'ar') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CameraPreviewPage()));
      return;
    }
    if (cat.id == 'nearby_ar') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NearbyLandmarksPage()));
      return;
    }
    if (cat.id == 'hotels' || cat.id == 'food') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ServiceProvidersListPage()));
      return;
    }
    setState(() => _selectedCategory = _selectedCategory == cat.id ? null : cat.id);
  }

  Future<void> _openLandmark(Landmark lm) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _interaction.trackInteraction(
        touristId: uid,
        attractionId: lm.id,
        interactionType: UserInteraction.view,
      );
    }
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => LandmarkDetailPage(landmark: lm)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EthioColors.cream,
      appBar: AppBar(
        title: const Text('Explore'),
        actions: const [NotificationBellButton(color: EthioColors.charcoal)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Text('Discover Ethiopia 🇪🇹', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('Find places, experiences and services around you', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 20),
                  PremiumSearchBar(
                    hint: 'Search places, attractions, services...',
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  const Text('Categories', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final cat = _categories[i];
                        final selected = _selectedCategory == cat.id;
                        return _CategoryChip(cat: cat, selected: selected, onTap: () => _onCategoryTap(cat));
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty || _selectedCategory != null) ...[
                    const SizedBox(height: 28),
                    Text('Results (${_filteredLandmarks.length})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 12),
                    ..._filteredLandmarks.take(10).map((lm) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PlaceListTile(landmark: lm, distance: formatLandmarkDistance(lm, _userLat, _userLon), onTap: () => _openLandmark(lm)),
                        )),
                  ] else ...[
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recommended for You ✨', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecommendationsPage())),
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_recommended.isNotEmpty)
                      _FeaturedCard(
                        result: _recommended.first,
                        distance: formatLandmarkDistance(_recommended.first.landmark, _userLat, _userLon),
                        onTap: () => _openLandmark(_recommended.first.landmark),
                      ),
                    const SizedBox(height: 28),
                    const Text('Near You 📍', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _nearby.take(6).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final nl = _nearby[i];
                          return _HorizontalPlaceCard(
                            landmark: nl.landmark,
                            distance: nl.formattedDistance,
                            onTap: () => _openLandmark(nl.landmark),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text('Popular Destinations', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _popular.take(6).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final lm = _popular[i];
                          return _HorizontalPlaceCard(
                            landmark: lm,
                            distance: formatLandmarkDistance(lm, _userLat, _userLon),
                            onTap: () => _openLandmark(lm),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final ExploreCategory cat;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({required this.cat, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? EthioColors.forest.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? EthioColors.forest : EthioColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(cat.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(cat.label, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w600 : FontWeight.normal), textAlign: TextAlign.center, maxLines: 2),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final RecommendationResult result;
  final String distance;
  final VoidCallback onTap;

  const _FeaturedCard({required this.result, required this.distance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lm = result.landmark;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlaceImage(landmark: lm, height: 160, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lm.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('${ExploreCategories.emojiForCategory(lm.category)} ${lm.category}'),
                      const SizedBox(width: 12),
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      Text(' ${lm.rating.toStringAsFixed(1)}'),
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on_outlined, size: 14),
                      Text(' $distance'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: EthioColors.forest.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('✨ ${result.primaryReason}', style: const TextStyle(fontSize: 13, color: EthioColors.forest)),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(onPressed: onTap, child: const Text('Explore →')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalPlaceCard extends StatelessWidget {
  final Landmark landmark;
  final String distance;
  final VoidCallback onTap;

  const _HorizontalPlaceCard({required this.landmark, required this.distance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlaceImage(landmark: landmark, height: 100, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(landmark.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('📍 $distance', style: const TextStyle(fontSize: 11, color: EthioColors.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceListTile extends StatelessWidget {
  final Landmark landmark;
  final String distance;
  final VoidCallback onTap;

  const _PlaceListTile({required this.landmark, required this.distance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: SizedBox(width: 56, height: 56, child: PlaceImage(landmark: landmark, height: 56, borderRadius: BorderRadius.circular(8))),
      title: Text(landmark.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('$distance • ${landmark.category}'),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
