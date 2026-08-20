import 'landmark.dart';

class RecommendationResult {
  final Landmark landmark;
  final double finalScore;
  final double interestScore;
  final double weatherScore;
  final double distanceScore;
  final String primaryReason;
  final List<String> allReasons;

  RecommendationResult({
    required this.landmark,
    required this.finalScore,
    required this.interestScore,
    required this.weatherScore,
    required this.distanceScore,
    required this.primaryReason,
    required this.allReasons,
  });

  // Get human-readable reason for display
  String get displayReason {
    if (finalScore >= 80) {
      return '✨ Highly recommended for you';
    } else if (finalScore >= 60) {
      return '👍 Great match based on your interests';
    } else if (finalScore >= 40) {
      return '👀 You might like this';
    } else {
      return '📍 Worth exploring';
    }
  }

  // Get category-specific reason
  String get categoryReason {
    switch (landmark.category.toLowerCase()) {
      case 'heritage':
      case 'historical':
        return '🏛️ Historical site';
      case 'nature':
        return '🌿 Nature destination';
      case 'culture':
        return '🎭 Cultural experience';
      case 'adventure':
        return '🏔️ Adventure activity';
      case 'religious':
        return '⛪ Religious site';
      default:
        return '📍 Popular attraction';
    }
  }
}