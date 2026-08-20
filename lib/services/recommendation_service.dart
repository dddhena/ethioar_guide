import '../models/landmark.dart';
import '../models/recommendation_result.dart';
import '../services/weather_service.dart';
import '../services/interaction_service.dart';
import '../services/location_service.dart';

class RecommendationService {
  final WeatherService _weatherService = WeatherService();
  final InteractionService _interactionService = InteractionService();

  /// Main recommendation algorithm - combines all signals
  Future<List<RecommendationResult>> getPersonalizedRecommendations({
    required String touristId,
    required List<Landmark> landmarks,
    required double userLatitude,
    required double userLongitude,
    String? selectedCategory,
  }) async {
    // Get current weather
    final weather = await _weatherService.getWeatherWithFallback(
      userLatitude, 
      userLongitude
    );

    // Get user preferences from interaction history
    final userPreferences = await _interactionService.calculateUserPreferences(touristId);
    final hasHistory = await _interactionService.hasInteractionHistory(touristId);

    final results = <RecommendationResult>[];

    for (final landmark in landmarks) {
      // Skip if category filter is set and doesn't match
      if (selectedCategory != null && 
          landmark.category.toLowerCase() != selectedCategory.toLowerCase()) {
        continue;
      }

      // Calculate individual scores
      final interestScore = _calculateInterestScore(
        landmark, 
        userPreferences, 
        hasHistory
      );
      
      final weatherScore = _calculateWeatherScore(landmark, weather);
      
      final distanceScore = _calculateDistanceScore(
        landmark, 
        userLatitude, 
        userLongitude
      );

      // Calculate final weighted score
      final finalScore = _calculateFinalScore(
        interestScore: interestScore,
        weatherScore: weatherScore,
        distanceScore: distanceScore,
        hasHistory: hasHistory,
      );

      // Generate reasons
      final reasons = _generateReasons(
        landmark,
        interestScore,
        weatherScore,
        distanceScore,
        weather,
        hasHistory,
      );

      results.add(RecommendationResult(
        landmark: landmark,
        finalScore: finalScore,
        interestScore: interestScore,
        weatherScore: weatherScore,
        distanceScore: distanceScore,
        primaryReason: reasons.first,
        allReasons: reasons,
      ));
    }

    // Sort by final score (descending)
    results.sort((a, b) => b.finalScore.compareTo(a.finalScore));

    return results;
  }

  /// Calculate interest score based on user's interaction history
  double _calculateInterestScore(
    Landmark landmark, 
    Map<String, double> userPreferences,
    bool hasHistory,
  ) {
    if (!hasHistory) {
      // No history - give neutral score
      return 50.0;
    }

    final categoryScore = userPreferences[landmark.category.toLowerCase()] ?? 0.0;
    
    // Normalize to 0-100 range
    // Assume max reasonable score is around 20 (multiple interactions)
    final normalizedScore = (categoryScore / 20.0) * 100;
    
    return normalizedScore.clamp(0.0, 100.0);
  }

  /// Calculate weather score based on current conditions
  double _calculateWeatherScore(Landmark landmark, WeatherData weather) {
    if (!landmark.outdoorFriendly) {
      // Indoor attractions - always good weather
      return 85.0;
    }

    final currentCondition = weather.simplifiedCondition;
    final bestConditions = landmark.bestWeatherConditions;

    // Check if current weather matches any of the best conditions
    if (bestConditions.contains(currentCondition)) {
      return 95.0; // Perfect match
    }

    // Partial matches
    if (currentCondition == 'clear' && bestConditions.contains('partly_cloudy')) {
      return 85.0;
    }
    
    if (currentCondition == 'partly_cloudy' && bestConditions.contains('clear')) {
      return 80.0;
    }

    // Bad weather for outdoor activities
    if (!weather.isGoodForOutdoors) {
      return 30.0;
    }

    // Moderate weather
    return 60.0;
  }

  /// Calculate distance score (closer is better)
  double _calculateDistanceScore(
    Landmark landmark,
    double userLatitude,
    double userLongitude,
  ) {
    final distanceKm = LocationService.calculateDistanceKm(
      userLatitude,
      userLongitude,
      landmark.latitude,
      landmark.longitude,
    );

    // Distance scoring: 100 at 0km, 0 at 50km+
    if (distanceKm <= 1.0) {
      return 100.0;
    } else if (distanceKm <= 5.0) {
      return 90.0;
    } else if (distanceKm <= 10.0) {
      return 75.0;
    } else if (distanceKm <= 25.0) {
      return 50.0;
    } else if (distanceKm <= 50.0) {
      return 25.0;
    } else {
      return 10.0;
    }
  }

  /// Calculate final weighted score
  double _calculateFinalScore({
    required double interestScore,
    required double weatherScore,
    required double distanceScore,
    required bool hasHistory,
  }) {
    if (hasHistory) {
      // Weighted average for users with history
      // Interest: 40%, Weather: 35%, Distance: 25%
      return (interestScore * 0.4) + 
             (weatherScore * 0.35) + 
             (distanceScore * 0.25);
    } else {
      // For new users, emphasize weather and distance more
      // Weather: 45%, Distance: 35%, Interest (popularity): 20%
      return (weatherScore * 0.45) + 
             (distanceScore * 0.35) + 
             (interestScore * 0.20);
    }
  }

  /// Generate human-readable reasons
  List<String> _generateReasons(
    Landmark landmark,
    double interestScore,
    double weatherScore,
    double distanceScore,
    WeatherData weather,
    bool hasHistory,
  ) {
    final reasons = <String>[];

    // Interest-based reasons
    if (hasHistory && interestScore >= 70) {
      reasons.add('✨ Because you frequently explore ${landmark.category} places');
    } else if (hasHistory && interestScore >= 50) {
      reasons.add('❤️ Similar to places you\'ve enjoyed');
    }

    // Weather-based reasons
    if (weatherScore >= 85) {
      reasons.add('☀️ Perfect for today\'s weather');
    } else if (weatherScore >= 70) {
      reasons.add('🌤️ Great weather for this activity');
    } else if (weatherScore <= 40 && landmark.outdoorFriendly) {
      reasons.add('🏠 Better suited for current weather');
    }

    // Distance-based reasons
    if (distanceScore >= 90) {
      final distance = LocationService.calculateDistanceKm(
        weather.latitude, weather.longitude,
        landmark.latitude, landmark.longitude,
      );
      reasons.add('📍 Only ${distance.toStringAsFixed(1)} km from you');
    } else if (distanceScore >= 70) {
      reasons.add('📍 Nearby and convenient');
    }

    // Fallback reasons
    if (reasons.isEmpty) {
      if (landmark.rating >= 4.5) {
        reasons.add('⭐ Highly rated by visitors');
      } else if (landmark.popularityScore > 50) {
        reasons.add('🔥 Popular among tourists');
      } else {
        reasons.add('👀 Worth exploring');
      }
    }

    return reasons;
  }

  /// Get recommendations by category (for "Because you like" sections)
  Future<List<RecommendationResult>> getRecommendationsByCategory({
    required String touristId,
    required List<Landmark> landmarks,
    required String category,
    required double userLatitude,
    required double userLongitude,
  }) async {
    return getPersonalizedRecommendations(
      touristId: touristId,
      landmarks: landmarks,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
      selectedCategory: category,
    );
  }

  /// Get weather-based recommendations (for "Perfect for today's weather")
  Future<List<RecommendationResult>> getWeatherBasedRecommendations({
    required List<Landmark> landmarks,
    required double userLatitude,
    required double userLongitude,
  }) async {
    final weather = await _weatherService.getWeatherWithFallback(
      userLatitude, 
      userLongitude
    );

    final results = <RecommendationResult>[];

    for (final landmark in landmarks) {
      final weatherScore = _calculateWeatherScore(landmark, weather);
      
      if (weatherScore >= 70) { // Only include good weather matches
        final distanceScore = _calculateDistanceScore(
          landmark, 
          userLatitude, 
          userLongitude
        );

        results.add(RecommendationResult(
          landmark: landmark,
          finalScore: (weatherScore * 0.6) + (distanceScore * 0.4),
          interestScore: 0,
          weatherScore: weatherScore,
          distanceScore: distanceScore,
          primaryReason: '☀️ Perfect for today\'s weather',
          allReasons: ['☀️ Perfect for today\'s weather'],
        ));
      }
    }

    results.sort((a, b) => b.finalScore.compareTo(a.finalScore));
    return results;
  }

  /// Get nearby recommendations (for "Near You" section)
  List<RecommendationResult> getNearbyRecommendations({
    required List<Landmark> landmarks,
    required double userLatitude,
    required double userLongitude,
    double maxRadiusKm = 25.0,
  }) {
    final results = <RecommendationResult>[];

    for (final landmark in landmarks) {
      final distance = LocationService.calculateDistanceKm(
        userLatitude,
        userLongitude,
        landmark.latitude,
        landmark.longitude,
      );

      if (distance <= maxRadiusKm) {
        final distanceScore = _calculateDistanceScore(
          landmark, 
          userLatitude, 
          userLongitude
        );

        results.add(RecommendationResult(
          landmark: landmark,
          finalScore: distanceScore,
          interestScore: 0,
          weatherScore: 0,
          distanceScore: distanceScore,
          primaryReason: '📍 Nearby attraction',
          allReasons: ['📍 Nearby attraction'],
        ));
      }
    }

    results.sort((a, b) => b.finalScore.compareTo(a.finalScore));
    return results;
  }

  /// Get popular attractions for empty state
  List<RecommendationResult> getPopularAttractions({
    required List<Landmark> landmarks,
    required double userLatitude,
    required double userLongitude,
  }) {
    // Sort by rating and popularity score
    final sortedLandmarks = List<Landmark>.from(landmarks);
    sortedLandmarks.sort((a, b) {
      final scoreA = (a.rating * 0.6) + (a.popularityScore * 0.4);
      final scoreB = (b.rating * 0.6) + (b.popularityScore * 0.4);
      return scoreB.compareTo(scoreA);
    });

    return sortedLandmarks.take(10).map((landmark) {
      final distanceScore = _calculateDistanceScore(
        landmark, 
        userLatitude, 
        userLongitude
      );

      return RecommendationResult(
        landmark: landmark,
        finalScore: distanceScore,
        interestScore: 0,
        weatherScore: 0,
        distanceScore: distanceScore,
        primaryReason: '🔥 Popular attraction',
        allReasons: ['🔥 Popular attraction'],
      );
    }).toList();
  }
}