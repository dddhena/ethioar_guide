import 'package:flutter/material.dart';
import '../../models/landmark.dart';
import '../../models/recommendation_result.dart';
import '../../pages/landmark_detail_page.dart';
import '../../pages/recommendations_page.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../services/recommendation_service.dart';
import '../../services/weather_service.dart';
import '../../theme/ethio_theme.dart';
import '../place_image.dart';

class RecommendedPlacesSection extends StatefulWidget {
  final String title;
  final bool showHeader;

  const RecommendedPlacesSection({
    super.key,
    this.title = 'RECOMMENDED PLACES',
    this.showHeader = true,
  });

  @override
  State<RecommendedPlacesSection> createState() => _RecommendedPlacesSectionState();
}

class _RecommendedPlacesSectionState extends State<RecommendedPlacesSection> {
  final _fs = FirestoreService();
  final _auth = AuthService();
  final _recService = RecommendationService();
  final _weatherService = WeatherService();

  bool _loading = true;
  List<RecommendationResult> _recommendations = [];
  final Map<String, WeatherData> _weatherCache = {};

  double _userLat = 9.032;
  double _userLon = 38.747;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      final pos = await LocationService.getCurrentPositionWeb();
      if (pos != null) {
        _userLat = pos['latitude']!;
        _userLon = pos['longitude']!;
      }

      final landmarks = await _fs.fetchLandmarks();
      if (landmarks.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final uid = _auth.currentUser?.uid;
      List<RecommendationResult> results;
      if (uid != null) {
        results = await _recService.getPersonalizedRecommendations(
          touristId: uid,
          landmarks: landmarks,
          userLatitude: _userLat,
          userLongitude: _userLon,
        );
      } else {
        results = _recService.getPopularAttractions(
          landmarks: landmarks,
          userLatitude: _userLat,
          userLongitude: _userLon,
        );
      }

      if (results.isEmpty) {
        results = _recService.getPopularAttractions(
          landmarks: landmarks,
          userLatitude: _userLat,
          userLongitude: _userLon,
        );
      }

      // Take top 6 recommendations
      _recommendations = results.take(6).toList();

      // Fetch weather for each unique city/coordinate in parallel
      for (final rec in _recommendations) {
        final lm = rec.landmark;
        final key = '${lm.latitude.toStringAsFixed(2)},${lm.longitude.toStringAsFixed(2)}';
        if (!_weatherCache.containsKey(key)) {
          _weatherService.getWeatherWithFallback(lm.latitude, lm.longitude).then((w) {
            if (mounted) {
              setState(() {
                _weatherCache[key] = w;
              });
            }
          });
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading recommended places: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _getWeatherIcon(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('sun') || c.contains('clear')) return '☀️';
    if (c.contains('rain') || c.contains('drizzle')) return '🌧️';
    if (c.contains('storm') || c.contains('thunder')) return '⛈️';
    if (c.contains('snow')) return '❄️';
    if (c.contains('fog') || c.contains('mist')) return '🌫️';
    return '⛅';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader) _buildHeader(),
          const SizedBox(height: 12),
          const SizedBox(
            height: 220,
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2, color: EthioColors.forest),
              ),
            ),
          ),
        ],
      );
    }

    if (_recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) _buildHeader(),
        const SizedBox(height: 12),
        SizedBox(
          height: 236,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: _recommendations.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final rec = _recommendations[index];
              final lm = rec.landmark;
              final key = '${lm.latitude.toStringAsFixed(2)},${lm.longitude.toStringAsFixed(2)}';
              final weather = _weatherCache[key];

              return _RecommendedCard(
                recommendation: rec,
                weather: weather,
                weatherIcon: weather != null ? _getWeatherIcon(weather.condition) : '☀️',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => LandmarkDetailPage(landmark: lm)),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, size: 16, color: EthioColors.forest),
            const SizedBox(width: 6),
            Text(
              widget.title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecommendationsPage()),
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: EthioColors.forest,
          ),
          child: const Row(
            children: [
              Text('See All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              SizedBox(width: 2),
              Icon(Icons.arrow_forward_ios, size: 11),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  final RecommendationResult recommendation;
  final WeatherData? weather;
  final String weatherIcon;
  final VoidCallback onTap;

  const _RecommendedCard({
    required this.recommendation,
    required this.weather,
    required this.weatherIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lm = recommendation.landmark;

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EthioColors.divider.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(
            color: EthioColors.cardShadow,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image container with temperature overlay
              Stack(
                children: [
                  PlaceImage(
                    landmark: lm,
                    height: 115,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  // Weather / Temperature badge at top right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(weatherIcon, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            weather != null ? '${weather!.temperature.round()}°C' : '22°C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Category tag at top left
                  if (lm.category.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: EthioColors.forest.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          lm.category.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Content details
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lm.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: EthioColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: EthioColors.muted),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            lm.city.isNotEmpty ? lm.city : 'Ethiopia',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: EthioColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Recommendation reason
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: EthioColors.sand.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars, size: 11, color: EthioColors.terracotta),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              recommendation.primaryReason,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: EthioColors.earth,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
