import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/landmark.dart';

// Conditional import for web geolocation without breaking native builds
import 'dart:html' as html;

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
      name: 'Addis Ababa',
      latitude: 9.0320,
      longitude: 38.7469,
      description: 'Capital city of Ethiopia',
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

  /// Attempt to fetch user position from browser geolocation with timeout.
  static Future<Map<String, double>?> getCurrentPositionWeb() async {
    if (!kIsWeb) return null;

    try {
      final geo = html.window.navigator.geolocation;
      final pos = await geo.getCurrentPosition();
      final lat = (pos.coords?.latitude ?? 0.0).toDouble();
      final lon = (pos.coords?.longitude ?? 0.0).toDouble();
      if (lat != 0.0 || lon != 0.0) {
        return {'latitude': lat, 'longitude': lon};
      }
    } catch (_) {
      // Browser geolocation denied or timed out
    }
    return null;
  }
}
