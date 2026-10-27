class CulturalAttire {
  final String id;
  final String name;
  final String description;
  final String region;
  final String previewUrl;
  final String overlayUrl;
  final String wearType; // 'cape_kaba', 'full_body', 'headwear', 'shawl_netela'
  final String gender; // 'unisex', 'female', 'male'

  const CulturalAttire({
    required this.id,
    required this.name,
    required this.description,
    this.region = 'Ethiopia',
    this.previewUrl = '',
    this.overlayUrl = '',
    this.wearType = 'cape_kaba',
    this.gender = 'unisex',
  });

  factory CulturalAttire.fromMap(Map<String, dynamic> data) {
    return CulturalAttire(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      region: data['region'] ?? 'Ethiopia',
      previewUrl: data['previewUrl'] ?? '',
      overlayUrl: data['overlayUrl'] ?? '',
      wearType: data['wearType'] ?? 'cape_kaba',
      gender: data['gender'] ?? 'unisex',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'region': region,
      'previewUrl': previewUrl,
      'overlayUrl': overlayUrl,
      'wearType': wearType,
      'gender': gender,
    };
  }

  static const List<CulturalAttire> defaultPresets = [
    CulturalAttire(
      id: 'kaba_royal_gold',
      name: 'Imperial Royal Kaba (ካባ)',
      description: 'Gold-embroidered velvet ceremonial cloak traditionally worn by Ethiopian royalty, dignitaries, and wedding couples.',
      region: 'Gondar & Shewa',
      previewUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=400&q=80',
      overlayUrl: 'assets/attire/royal_kaba.png',
      wearType: 'cape_kaba',
      gender: 'unisex',
    ),
    CulturalAttire(
      id: 'habesha_kemis_shewa',
      name: 'Habesha Kemis (የሀበሻ ቀሚስ)',
      description: 'Hand-woven chiffon cotton dress adorned with intricate colorful Tibeb border embroidery.',
      region: 'Amhara & Tigray',
      previewUrl: 'https://images.unsplash.com/photo-1578575437130-527eed3abbec?auto=format&fit=crop&w=400&q=80',
      overlayUrl: 'assets/attire/habesha_kemis.png',
      wearType: 'full_body',
      gender: 'female',
    ),
    CulturalAttire(
      id: 'oromo_traditional_attire',
      name: 'Oromo Cultural Attire (Wannyo & Kallacha)',
      description: 'Vibrant embroidered vest, head ornament (Kallacha), and traditional ceremonial sash.',
      region: 'Oromia',
      previewUrl: 'https://images.unsplash.com/photo-1516426122078-c23e76319801?auto=format&fit=crop&w=400&q=80',
      overlayUrl: 'assets/attire/oromo_attire.png',
      wearType: 'full_body',
      gender: 'unisex',
    ),
    CulturalAttire(
      id: 'netela_gabi_shawl',
      name: 'Ceremonial Netela & Gabi (ነጠላ)',
      description: 'Two-layered sheer cotton scarf worn elegantly draped over the shoulders with woven borders.',
      region: 'All Ethiopia',
      previewUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=400&q=80',
      overlayUrl: 'assets/attire/netela.png',
      wearType: 'shawl_netela',
      gender: 'unisex',
    ),
  ];
}

class NativeAnimal {
  final String id;
  final String name;
  final String species;
  final String previewUrl;
  final String modelUrl; // 3D model or sprite URL
  final String soundEffect; // 'horse_whinny', 'dog_bark', 'wolf_howl', 'ibex_call'
  final String behaviorType; // 'horse_rope', 'barking_dog', 'ambient_wildlife'
  final String behaviorDescription;
  final double defaultScale;

  const NativeAnimal({
    required this.id,
    required this.name,
    required this.species,
    this.previewUrl = '',
    this.modelUrl = '',
    this.soundEffect = 'horse_whinny',
    this.behaviorType = 'horse_rope',
    this.behaviorDescription = 'Stands beside user with interactive rope reins held by user',
    this.defaultScale = 1.0,
  });

  factory NativeAnimal.fromMap(Map<String, dynamic> data) {
    return NativeAnimal(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      species: data['species'] ?? '',
      previewUrl: data['previewUrl'] ?? '',
      modelUrl: data['modelUrl'] ?? '',
      soundEffect: data['soundEffect'] ?? 'horse_whinny',
      behaviorType: data['behaviorType'] ?? 'horse_rope',
      behaviorDescription: data['behaviorDescription'] ?? '',
      defaultScale: ((data['defaultScale'] ?? 1.0) as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'previewUrl': previewUrl,
      'modelUrl': modelUrl,
      'soundEffect': soundEffect,
      'behaviorType': behaviorType,
      'behaviorDescription': behaviorDescription,
      'defaultScale': defaultScale,
    };
  }

  static const List<NativeAnimal> defaultPresets = [
    NativeAnimal(
      id: 'abyssinian_horse',
      name: 'Abyssinian War Horse (የአበሻ ፈረስ)',
      species: 'Equus caballus',
      previewUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?auto=format&fit=crop&w=400&q=80',
      soundEffect: 'horse_whinny',
      behaviorType: 'horse_rope',
      behaviorDescription: 'Interactive reins rope connects to user hand; reacts with trot and neighing',
      defaultScale: 1.1,
    ),
    NativeAnimal(
      id: 'ethiopian_shepherd_dog',
      name: 'Ethiopian Shepherd Dog (የመንደር ውሻ)',
      species: 'Canis lupus familiaris',
      previewUrl: 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=400&q=80',
      soundEffect: 'dog_bark',
      behaviorType: 'barking_dog',
      behaviorDescription: 'Alert guard dog standing beside you that barks on tap or detection to guard the site',
      defaultScale: 0.7,
    ),
    NativeAnimal(
      id: 'walia_ibex',
      name: 'Walia Ibex (ዋልያ)',
      species: 'Capra walie',
      previewUrl: 'https://images.unsplash.com/photo-1575550959106-5a7defe28b56?auto=format&fit=crop&w=400&q=80',
      soundEffect: 'ibex_call',
      behaviorType: 'ambient_wildlife',
      behaviorDescription: 'Majestic mountain goat endemic to the Ethiopian Highlands with curved horns',
      defaultScale: 0.9,
    ),
    NativeAnimal(
      id: 'gelada_baboon',
      name: 'Gelada Baboon (ጭላዳ ዝንጀሮ)',
      species: 'Theropithecus gelada',
      previewUrl: 'https://images.unsplash.com/photo-1540573133985-87b6da6d54a9?auto=format&fit=crop&w=400&q=80',
      soundEffect: 'nature',
      behaviorType: 'ambient_wildlife',
      behaviorDescription: 'The bleeding-heart baboon native to the high grasslands of northern Ethiopia',
      defaultScale: 0.75,
    ),
  ];
}

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
  final double entranceFee; // in ETB
  final String site3dModelUrl; // 3D View model (.glb/.gltf)
  final List<CulturalAttire> culturalAttires; // Cultural clothes available at site
  final List<NativeAnimal> nativeAnimals; // Animals known to this site

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
    this.entranceFee = 0.0,
    this.site3dModelUrl = '',
    this.culturalAttires = const [],
    this.nativeAnimals = const [],
  });

  String get formattedEntranceFee {
    if (entranceFee <= 0) return 'Free Entry';
    return '${entranceFee.toStringAsFixed(entranceFee.truncateToDouble() == entranceFee ? 0 : 2)} ETB';
  }

  factory Landmark.fromMap(String id, Map<String, dynamic> data) {
    List<CulturalAttire> parsedAttires = [];
    if (data['culturalAttires'] is List) {
      parsedAttires = (data['culturalAttires'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => CulturalAttire.fromMap(item))
          .toList();
    }

    List<NativeAnimal> parsedAnimals = [];
    if (data['nativeAnimals'] is List) {
      parsedAnimals = (data['nativeAnimals'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => NativeAnimal.fromMap(item))
          .toList();
    }

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
      entranceFee: ((data['entranceFee'] ?? data['entryFee'] ?? 0) as num).toDouble(),
      site3dModelUrl: data['site3dModelUrl'] ?? '',
      culturalAttires: parsedAttires,
      nativeAnimals: parsedAnimals,
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
      'entranceFee': entranceFee,
      'site3dModelUrl': site3dModelUrl,
      'culturalAttires': culturalAttires.map((a) => a.toMap()).toList(),
      'nativeAnimals': nativeAnimals.map((a) => a.toMap()).toList(),
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
      entranceFee: ((data['entranceFee'] ?? data['entryFee'] ?? 0) as num).toDouble(),
      site3dModelUrl: data['site3dModelUrl'] ?? '',
      culturalAttires: const [],
      nativeAnimals: const [],
    );
  }

  Landmark copyWith({
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    String? city,
    String? category,
    double? rating,
    int? reviewCount,
    String? imageUrl,
    bool? outdoorFriendly,
    List<String>? bestWeatherConditions,
    double? popularityScore,
    double? entranceFee,
    String? site3dModelUrl,
    List<CulturalAttire>? culturalAttires,
    List<NativeAnimal>? nativeAnimals,
  }) {
    return Landmark(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      imageUrl: imageUrl ?? this.imageUrl,
      outdoorFriendly: outdoorFriendly ?? this.outdoorFriendly,
      bestWeatherConditions: bestWeatherConditions ?? this.bestWeatherConditions,
      popularityScore: popularityScore ?? this.popularityScore,
      entranceFee: entranceFee ?? this.entranceFee,
      site3dModelUrl: site3dModelUrl ?? this.site3dModelUrl,
      culturalAttires: culturalAttires ?? this.culturalAttires,
      nativeAnimals: nativeAnimals ?? this.nativeAnimals,
    );
  }
}
