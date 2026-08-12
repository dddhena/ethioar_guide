class Landmark {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;

  Landmark({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  factory Landmark.fromMap(String id, Map<String, dynamic> data) {
    return Landmark(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
    );
  }
}
