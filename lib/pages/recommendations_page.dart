import 'package:flutter/material.dart';
import '../models/landmark.dart';
import '../models/recommendation_result.dart';
import '../models/user_interaction.dart';
import '../services/recommendation_service.dart';
import '../services/weather_service.dart';
import '../services/interaction_service.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/notification_bell_button.dart';
import '../widgets/chat_icon_button.dart';
import 'landmark_detail_page.dart';

class RecommendationsPage extends StatefulWidget {
  const RecommendationsPage({super.key});

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  final RecommendationService _recommendationService = RecommendationService();
  final InteractionService _interactionService = InteractionService();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _auth = AuthService();

  bool _loading = true;
  WeatherData? _weatherData;
  List<RecommendationResult> _personalizedRecommendations = [];
  List<RecommendationResult> _historyRecommendations = [];
  List<RecommendationResult> _weatherRecommendations = [];
  List<RecommendationResult> _nearbyRecommendations = [];
  List<RecommendationResult> _popularAttractions = [];
  
  String _selectedFilter = 'For You';
  bool _hasInteractionHistory = false;
  
  // User location (default to Addis Ababa)
  double _userLatitude = 9.0320;
  double _userLongitude = 38.7469;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      // Get user ID
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        setState(() => _loading = false);
        return;
      }

      // Check interaction history
      _hasInteractionHistory = await _interactionService.hasInteractionHistory(userId);

      // Load landmarks
      List<Landmark> landmarks = await _firestoreService.fetchLandmarks();
      
      // Enhance landmarks with additional data for demo purposes
      landmarks = _enhanceLandmarks(landmarks);

      // Get user location (try web geolocation, fallback to default)
      final position = await LocationService.getCurrentPositionWeb();
      if (position != null) {
        _userLatitude = position['latitude']!;
        _userLongitude = position['longitude']!;
      }

      // Load weather
      _weatherData = await WeatherService().getWeatherWithFallback(
        _userLatitude,
        _userLongitude,
      );

      // Generate recommendations
      if (_hasInteractionHistory) {
        _personalizedRecommendations = await _recommendationService.getPersonalizedRecommendations(
          touristId: userId,
          landmarks: landmarks,
          userLatitude: _userLatitude,
          userLongitude: _userLongitude,
        );

        // Get category-based recommendations
        _historyRecommendations = await _recommendationService.getRecommendationsByCategory(
          touristId: userId,
          landmarks: landmarks,
          category: 'heritage', // Would be dynamic based on user prefs
          userLatitude: _userLatitude,
          userLongitude: _userLongitude,
        );
      }

      // Weather-based recommendations
      _weatherRecommendations = await _recommendationService.getWeatherBasedRecommendations(
        landmarks: landmarks,
        userLatitude: _userLatitude,
        userLongitude: _userLongitude,
      );

      // Nearby recommendations
      _nearbyRecommendations = _recommendationService.getNearbyRecommendations(
        landmarks: landmarks,
        userLatitude: _userLatitude,
        userLongitude: _userLongitude,
      );

      // Popular attractions (for empty state)
      _popularAttractions = _recommendationService.getPopularAttractions(
        landmarks: landmarks,
        userLatitude: _userLatitude,
        userLongitude: _userLongitude,
      );

      setState(() => _loading = false);
    } catch (e) {
      print('Error loading recommendations: $e');
      setState(() => _loading = false);
    }
  }

  // Enhance landmarks with additional data for better recommendations
  List<Landmark> _enhanceLandmarks(List<Landmark> landmarks) {
    return landmarks.map((landmark) {
      // Add enhanced data based on existing landmark info
      String category = 'heritage';
      bool outdoorFriendly = true;
      List<String> bestWeather = ['clear', 'partly_cloudy'];
      double rating = 4.5;
      double popularity = 50.0;

      // Infer category from name/description
      final nameLower = landmark.name.toLowerCase();
      if (nameLower.contains('church') || nameLower.contains('monastery')) {
        category = 'religious';
      } else if (nameLower.contains('mountain') || nameLower.contains('park') || nameLower.contains('lake')) {
        category = 'nature';
      } else if (nameLower.contains('museum') || nameLower.contains('palace')) {
        category = 'culture';
      }

      return Landmark(
        id: landmark.id,
        name: landmark.name,
        description: landmark.description,
        latitude: landmark.latitude,
        longitude: landmark.longitude,
        city: landmark.city,
        category: category,
        rating: rating,
        reviewCount: 100,
        imageUrl: '',
        outdoorFriendly: outdoorFriendly,
        bestWeatherConditions: bestWeather,
        popularityScore: popularity,
      );
    }).toList();
  }

  Future<void> _trackInteraction(String attractionId, String interactionType) async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _interactionService.trackInteraction(
        touristId: userId,
        attractionId: attractionId,
        interactionType: interactionType,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '✨ Recommended for You',
      actions: const [
        ChatIconButton(),
        NotificationBellButton(),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Weather Widget
                  if (_weatherData != null) _buildWeatherWidget(),
                  
                  const SizedBox(height: 24),

                  // Empty State for new users
                  if (!_hasInteractionHistory) ...[
                    _buildEmptyState(),
                    const SizedBox(height: 24),
                  ],

                  // Filter Chips
                  _buildFilterChips(),
                  
                  const SizedBox(height: 24),

                  // Content based on filter
                  _buildFilteredContent(),
                ],
              ),
            ),
    );
  }

  Widget _buildWeatherWidget() {
    if (_weatherData == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade400,
            Colors.lightBlue.shade300,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getWeatherIcon(_weatherData!.condition),
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                '${_weatherData!.temperature.toStringAsFixed(0)}°C',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _weatherData!.description,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _weatherData!.city.isNotEmpty ? _weatherData!.city : 'Ethiopia',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _weatherData!.weatherDescription,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildWeatherDetail('💧', '${_weatherData!.humidity.toStringAsFixed(0)}%'),
              const SizedBox(width: 16),
              _buildWeatherDetail('💨', '${_weatherData!.windSpeed.toStringAsFixed(0)} km/h'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(String emoji, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.water_drop;
      case 'snow':
        return Icons.ac_unit;
      case 'thunderstorm':
        return Icons.flash_on;
      default:
        return Icons.wb_cloudy;
    }
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.explore,
            size: 48,
            color: Colors.amber.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            'Let\'s discover what you love ✨',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explore a few places and we\'ll learn what interests you.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.amber.shade800,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['For You', 'Nearby', 'Weather', 'History', 'Nature', 'Culture'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedFilter = filter);
              },
              selectedColor: Colors.teal.shade100,
              checkmarkColor: Colors.teal.shade800,
              labelStyle: TextStyle(
                color: isSelected ? Colors.teal.shade800 : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilteredContent() {
    switch (_selectedFilter) {
      case 'For You':
        return _buildForYouSection();
      case 'Nearby':
        return _buildRecommendationSection(
          'Near You 📍',
          _nearbyRecommendations,
          '📍 Nearby attractions',
        );
      case 'Weather':
        return _buildRecommendationSection(
          'Perfect for Today\'s Weather ☀️',
          _weatherRecommendations,
          '☀️ Great for current conditions',
        );
      case 'History':
        return _buildRecommendationSection(
          'Because You Like History 🏛️',
          _historyRecommendations,
          '🏛️ Historical sites',
        );
      case 'Nature':
        return _buildCategorySection('nature');
      case 'Culture':
        return _buildCategorySection('culture');
      default:
        return _buildForYouSection();
    }
  }

  Widget _buildForYouSection() {
    if (!_hasInteractionHistory) {
      return _buildRecommendationSection(
        'Popular Attractions 🔥',
        _popularAttractions,
        '🔥 Trending now',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Picked for You ✨',
          'Based on your interests, location and today\'s conditions',
        ),
        const SizedBox(height: 16),
        _buildRecommendationGrid(_personalizedRecommendations.take(6).toList()),
        
        if (_historyRecommendations.isNotEmpty) ...[
          const SizedBox(height: 32),
          _buildSectionHeader(
            'Because You Like History 🏛️',
            'Based on your interaction history',
          ),
          const SizedBox(height: 16),
          _buildRecommendationGrid(_historyRecommendations.take(4).toList()),
        ],
        
        if (_weatherRecommendations.isNotEmpty) ...[
          const SizedBox(height: 32),
          _buildSectionHeader(
            'Perfect for Today\'s Weather ☀️',
            'Great conditions for these places',
          ),
          const SizedBox(height: 16),
          _buildRecommendationGrid(_weatherRecommendations.take(4).toList()),
        ],
        
        if (_nearbyRecommendations.isNotEmpty) ...[
          const SizedBox(height: 32),
          _buildSectionHeader(
            'Near You 📍',
            'Close to your current location',
          ),
          const SizedBox(height: 16),
          _buildRecommendationGrid(_nearbyRecommendations.take(4).toList()),
        ],
      ],
    );
  }

  Widget _buildCategorySection(String category) {
    // In a real implementation, this would filter by category
    final categoryRecommendations = _personalizedRecommendations
        .where((r) => r.landmark.category.toLowerCase() == category)
        .toList();
    
    if (categoryRecommendations.isEmpty) {
      return _buildRecommendationSection(
        'Popular ${category.capitalize()} Places',
        _popularAttractions
            .where((r) => r.landmark.category.toLowerCase() == category)
            .toList(),
        '🔥 Trending ${category} destinations',
      );
    }

    return _buildRecommendationSection(
      '${category.capitalize()} Destinations',
      categoryRecommendations,
      '✨ Best ${category} experiences',
    );
  }

  Widget _buildRecommendationSection(
    String title,
    List<RecommendationResult> recommendations,
    String subtitle,
  ) {
    if (recommendations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No recommendations found',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title, subtitle),
        const SizedBox(height: 16),
        _buildRecommendationGrid(recommendations),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade900,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationGrid(List<RecommendationResult> recommendations) {
    // Responsive grid: 1 column on mobile, 2-3 on desktop
    final isDesktop = MediaQuery.of(context).size.width > 1200;
    final crossAxisCount = isDesktop ? 3 : (MediaQuery.of(context).size.width > 600 ? 2 : 1);
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        return _buildRecommendationCard(recommendations[index]);
      },
    );
  }

  Widget _buildRecommendationCard(RecommendationResult result) {
    final landmark = result.landmark;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          await _trackInteraction(landmark.id, UserInteraction.view);
          // Navigate to landmark details (would implement this)
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LandmarkDetailPage(landmark: landmark),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    colors: [
                      _getCategoryColor(landmark.category),
                      _getCategoryColor(landmark.category).withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(landmark.category),
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            // Content
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      landmark.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(_getCategoryIcon(landmark.category), size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          landmark.category.capitalize(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          landmark.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          _formatDistance(result.distanceScore),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        result.primaryReason,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.teal.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await _trackInteraction(landmark.id, UserInteraction.view);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LandmarkDetailPage(landmark: landmark),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Explore →'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double distanceScore) {
    // Convert score back to approximate distance
    if (distanceScore >= 90) return '<1 km';
    if (distanceScore >= 75) return '1-5 km';
    if (distanceScore >= 50) return '5-10 km';
    if (distanceScore >= 25) return '10-25 km';
    return '25+ km';
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'heritage':
      case 'historical':
        return Colors.brown.shade600;
      case 'nature':
        return Colors.green.shade600;
      case 'culture':
        return Colors.purple.shade600;
      case 'adventure':
        return Colors.orange.shade600;
      case 'religious':
        return Colors.indigo.shade600;
      default:
        return Colors.teal.shade600;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'heritage':
      case 'historical':
        return Icons.account_balance;
      case 'nature':
        return Icons.park;
      case 'culture':
        return Icons.theater_comedy;
      case 'adventure':
        return Icons.hiking;
      case 'religious':
        return Icons.church;
      default:
        return Icons.place;
    }
  }
}

// String extension for capitalization
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}