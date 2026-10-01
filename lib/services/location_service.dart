import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/landmark.dart';


class CityLocation {
  final String name;
  final double latitude;
  final double longitude;
  final String description;

  const CityLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.description,
  });
}

class NearbyLandmark {
  final Landmark landmark;
  final double distanceKm;
  final double bearingDegrees;
  final String direction;

  NearbyLandmark({
    required this.landmark,
    required this.distanceKm,
    required this.bearingDegrees,
    required this.direction,
  });

  String get formattedDistance {
    if (distanceKm < 1.0) {
      final meters = (distanceKm * 1000).round();
      return '$meters m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }
}

class LocationService {
  // Preset locations in Ethiopia for testing and simulation
  static const List<CityLocation> ethiopianCities = [
    CityLocation(
      name: 'Ambo',
      latitude: 8.9833,
      longitude: 37.8500,
      description: 'Famous for mineral springs, Mount Wonchi crater lake, and Oromo heritage',
    ),
    CityLocation(
      name: 'Bishoftu',
      latitude: 8.7522,
      longitude: 38.9785,
      description: 'Resort town with seven volcanic crater lakes (Debre Zeyit)',
    ),
    CityLocation(
      name: 'Addis Ababa',
      latitude: 9.0320,
      longitude: 38.7469,
      description: 'Capital city of Ethiopia',
    ),
    CityLocation(
      name: 'Adama',
      latitude: 8.5400,
      longitude: 39.2700,
      description: 'Major commercial crossroads and Great Rift Valley hub (Nazret)',
    ),
    CityLocation(
      name: 'Lalibela',
      latitude: 12.0319,
      longitude: 39.0476,
      description: 'Home of the historic rock-hewn churches',
    ),
    CityLocation(
      name: 'Gondar',
      latitude: 12.6010,
      longitude: 37.4670,
      description: 'Camelot of Africa with historic castles',
    ),
    CityLocation(
      name: 'Aksum',
      latitude: 14.1270,
      longitude: 38.7190,
      description: 'Ancient kingdom and towering obelisks',
    ),
    CityLocation(
      name: 'Bahir Dar',
      latitude: 11.5936,
      longitude: 37.3908,
      description: 'Lake Tana and Blue Nile Falls',
    ),
    CityLocation(
      name: 'Harar',
      latitude: 9.3126,
      longitude: 42.1288,
      description: 'Historic walled city (Jugol)',
    ),
    CityLocation(
      name: 'Hawassa',
      latitude: 7.0504,
      longitude: 38.4716,
      description: 'Rift Valley lakeside city',
    ),
    CityLocation(
      name: 'Dire Dawa',
      latitude: 9.6009,
      longitude: 41.8661,
      description: 'Commercial and cultural crossroads',
    ),
    CityLocation(
      name: 'Arba Minch',
      latitude: 6.0333,
      longitude: 37.5500,
      description: 'Gateway to Nechisar National Park and crocodile market',
    ),
    CityLocation(
      name: 'Jimma',
      latitude: 7.6733,
      longitude: 36.8344,
      description: 'Historic coffee kingdom of southwestern Ethiopia',
    ),
  ];

  /// Haversine formula to compute great-circle distance between two GPS coordinates in kilometers.
  static double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371.0; // Earth radius in km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            (math.sin(dLon / 2) * math.sin(dLon / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  /// Calculates initial compass bearing in degrees (0° to 360°) from point 1 to point 2.
  static double calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final y = math.sin(_deg2rad(lon2 - lon1)) * math.cos(_deg2rad(lat2));
    final x = math.cos(_deg2rad(lat1)) * math.sin(_deg2rad(lat2)) -
        math.sin(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) * math.cos(_deg2rad(lon2 - lon1));
    final brng = math.atan2(y, x);
    return (_rad2deg(brng) + 360) % 360;
  }

  /// Converts bearing degrees into cardinal directions with arrows.
  static String bearingToDirection(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return 'North ⬆️';
    if (bearing >= 22.5 && bearing < 67.5) return 'North-East ↗️';
    if (bearing >= 67.5 && bearing < 112.5) return 'East ➡️';
    if (bearing >= 112.5 && bearing < 157.5) return 'South-East ↘️';
    if (bearing >= 157.5 && bearing < 202.5) return 'South ⬇️';
    if (bearing >= 202.5 && bearing < 247.5) return 'South-West ↙️';
    if (bearing >= 247.5 && bearing < 292.5) return 'West ⬅️';
    return 'North-West ↖️';
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180.0);
  static double _rad2deg(double rad) => rad * (180.0 / math.pi);

  /// Sorts and filters landmarks by distance from a given point.
  static List<NearbyLandmark> getNearbyLandmarks({
    required double currentLat,
    required double currentLon,
    required List<Landmark> landmarks,
    double? maxRadiusKm,
  }) {
    final list = <NearbyLandmark>[];

    for (final lm in landmarks) {
      final distance = calculateDistanceKm(currentLat, currentLon, lm.latitude, lm.longitude);
      if (maxRadiusKm == null || distance <= maxRadiusKm) {
        final bearing = calculateBearing(currentLat, currentLon, lm.latitude, lm.longitude);
        final direction = bearingToDirection(bearing);
        list.add(NearbyLandmark(
          landmark: lm,
          distanceKm: distance,
          bearingDegrees: bearing,
          direction: direction,
        ));
      }
    }

    // Sort by nearest first
    list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return list;
  }

  // --- Centralized Flexible Location State ---
  static LatLng? _manualLocation;
  static String? _manualLocationName;
  static LatLng? _realGpsLocation;
  static String? _realGpsCityName;
  static bool _hasRealGps = false;

  static Map<String, double>? _cachedPosition;
  static DateTime? _lastFetchTime;
  static String? _cachedCityName;
  static bool _isFetching = false;
  static final StreamController<Map<String, double>> _locationStreamController =
      StreamController<Map<String, double>>.broadcast();

  /// Stream of location updates for reactive UI updates across all pages.
  static Stream<Map<String, double>> get onLocationChanged => _locationStreamController.stream;

  /// Returns the cached position immediately if available (0ms latency).
  static Map<String, double>? get cachedPosition => _cachedPosition;

  /// Active reference coordinate across all pages (flexible manual or live GPS).
  static LatLng get currentLatLng {
    if (_manualLocation != null) return _manualLocation!;
    if (_realGpsLocation != null) return _realGpsLocation!;
    if (_cachedPosition != null) {
      return LatLng(_cachedPosition!['latitude']!, _cachedPosition!['longitude']!);
    }
    return const LatLng(8.9833, 37.8500); // Default to Ambo area
  }

  /// Name of the current active location.
  static String get currentLocationName {
    if (_manualLocationName != null) return _manualLocationName!;
    if (_realGpsCityName != null) return _realGpsCityName!;
    if (_cachedCityName != null) return _cachedCityName!;
    return 'Ambo';
  }

  /// Whether the user has chosen a manual reference location instead of live GPS.
  static bool get isUsingCustomLocation => _manualLocation != null;

  /// Set a flexible custom departure/reference location globally across the entire app.
  static void setFlexibleLocation(LatLng coords, String name) {
    _manualLocation = coords;
    _manualLocationName = name;
    _cachedPosition = {'latitude': coords.latitude, 'longitude': coords.longitude};
    _cachedCityName = name;
    _locationStreamController.add(_cachedPosition!);
  }

  /// Reset to use device live GPS location.
  static void resetToLiveGps() {
    _manualLocation = null;
    _manualLocationName = null;
    if (_realGpsLocation != null) {
      _cachedPosition = {'latitude': _realGpsLocation!.latitude, 'longitude': _realGpsLocation!.longitude};
      _cachedCityName = _realGpsCityName;
      _locationStreamController.add(_cachedPosition!);
    }
    _fetchFreshPosition();
  }

  /// Returns the current city name (e.g., Ambo, Bishoftu, Addis Ababa, etc.).
  static String get currentCityName => currentLocationName;

  /// Calculates the nearest Ethiopian city from preset list based on GPS coordinates.
  static CityLocation getNearestCity(double lat, double lon) {
    CityLocation nearest = ethiopianCities.first;
    double minDistance = double.infinity;

    for (final city in ethiopianCities) {
      final dist = calculateDistanceKm(lat, lon, city.latitude, city.longitude);
      if (dist < minDistance) {
        minDistance = dist;
        nearest = city;
      }
    }
    return nearest;
  }

  /// Attempt to fetch user position from browser/device geolocation with caching & fallback.
  /// When cached, returns in 0ms so every page instantly knows the user's correct position.
  static Future<Map<String, double>?> getCurrentPositionWeb({bool forceRefresh = false}) async {
    // If user explicitly chose a manual location, respect it
    if (!forceRefresh && _manualLocation != null) {
      return {'latitude': _manualLocation!.latitude, 'longitude': _manualLocation!.longitude};
    }

    // Return cached position instantly if recent and real GPS was acquired
    if (!forceRefresh && _cachedPosition != null && _hasRealGps) {
      if (_lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!).inMinutes < 3) {
        return _cachedPosition;
      }
      _refreshInBackground();
      return _cachedPosition;
    }

    return await _fetchFreshPosition();
  }

  static void _refreshInBackground() {
    if (_isFetching) return;
    _fetchFreshPosition().catchError((_) => null);
  }

  static Future<Map<String, double>?> _fetchFreshPosition() async {
    if (_isFetching && _cachedPosition != null) {
      return _cachedPosition;
    }
    _isFetching = true;

    try {
      // Verify/request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      final result = {'latitude': pos.latitude, 'longitude': pos.longitude};
      _realGpsLocation = LatLng(pos.latitude, pos.longitude);
      _realGpsCityName = getNearestCity(pos.latitude, pos.longitude).name;
      _hasRealGps = true;
      _cachedPosition = result;
      _lastFetchTime = DateTime.now();
      _cachedCityName = _realGpsCityName;
      _locationStreamController.add(result);
      return result;
    } catch (_) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          final result = {'latitude': last.latitude, 'longitude': last.longitude};
          _realGpsLocation = LatLng(last.latitude, last.longitude);
          _realGpsCityName = getNearestCity(last.latitude, last.longitude).name;
          _hasRealGps = true;
          _cachedPosition = result;
          _lastFetchTime = DateTime.now();
          _cachedCityName = _realGpsCityName;
          _locationStreamController.add(result);
          return result;
        }
      } catch (_) {}

      if (_cachedPosition != null) {
        return _cachedPosition;
      }

      // Default fallback to Ambo coordinates
      final defaultPos = {'latitude': 8.9833, 'longitude': 37.8500};
      _cachedPosition = defaultPos;
      _cachedCityName = 'Ambo';
      return defaultPos;
    } finally {
      _isFetching = false;
    }
  }

  /// Safely resolves the user's current live GPS / Geolocation coordinate across platforms.
  static Future<LatLng?> getCurrentUserLocation({bool forceRefresh = false}) async {
    final pos = await getCurrentPositionWeb(forceRefresh: forceRefresh);
    if (pos != null) {
      return LatLng(pos['latitude']!, pos['longitude']!);
    }
    return currentLatLng;
  }
}
