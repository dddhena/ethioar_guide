class Landmark {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String city;
  final String category;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final bool outdoorFriendly;
  final List<String> bestWeatherConditions;
  final double popularityScore;

  Landmark({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.city = '',
    this.category = 'heritage',
    this.rating = 4.0,
    this.reviewCount = 0,
    this.imageUrl = '',
    this.outdoorFriendly = true,
    this.bestWeatherConditions = const ['clear', 'partly_cloudy'],
    this.popularityScore = 0.0,
  });

  factory Landmark.fromMap(String id, Map<String, dynamic> data) {
    return Landmark(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      city: data['city'] ?? '',
      category: data['category'] ?? 'heritage',
      rating: (data['rating'] ?? 4.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      outdoorFriendly: data['outdoorFriendly'] ?? true,
      bestWeatherConditions: data['bestWeatherConditions'] != null 
          ? List<String>.from(data['bestWeatherConditions']) 
          : ['clear', 'partly_cloudy'],
      popularityScore: (data['popularityScore'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'category': category,
      'rating': rating,
      'reviewCount': reviewCount,
      'imageUrl': imageUrl,
      'outdoorFriendly': outdoorFriendly,
      'bestWeatherConditions': bestWeatherConditions,
      'popularityScore': popularityScore,
    };
  }

  // Create a basic landmark from the old model for backward compatibility
  static Landmark fromLegacyModel(String id, Map<String, dynamic> data) {
    return Landmark(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      city: data['city'] ?? '',
      category: data['category'] ?? 'heritage',
    );
  }
}
