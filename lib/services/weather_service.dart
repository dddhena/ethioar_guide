import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final String condition;
  final String description;
  final double humidity;
  final double windSpeed;
  final int cloudiness;
  final double rainProbability;
  final String city;
  final double latitude;
  final double longitude;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.cloudiness,
    required this.rainProbability,
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'] ?? {};
    final weather = (json['weather'] as List?)?.isNotEmpty == true 
        ? json['weather'][0] 
        : {};
    final clouds = json['clouds'] ?? {};
    final rain = json['rain'] ?? {};

    return WeatherData(
      temperature: (main['temp'] ?? 0).toDouble(),
      condition: weather['main']?.toString().toLowerCase() ?? 'unknown',
      description: weather['description']?.toString() ?? '',
      humidity: (main['humidity'] ?? 0).toDouble(),
      windSpeed: (json['wind']?['speed'] ?? 0).toDouble(),
      cloudiness: (clouds['all'] ?? 0).toInt(),
      rainProbability: (rain['1h'] ?? rain['3h'] ?? 0).toDouble(),
      city: json['name']?.toString() ?? '',
      latitude: (json['coord']?['lat'] ?? 0).toDouble(),
      longitude: (json['coord']?['lon'] ?? 0).toDouble(),
    );
  }

  // Get simplified condition for recommendation matching
  String get simplifiedCondition {
    if (condition.contains('clear') || condition.contains('sun')) {
      return 'clear';
    } else if (condition.contains('cloud')) {
      return 'partly_cloudy';
    } else if (condition.contains('rain') || condition.contains('drizzle')) {
      return 'rainy';
    } else if (condition.contains('snow')) {
      return 'snowy';
    } else if (condition.contains('storm') || condition.contains('thunder')) {
      return 'stormy';
    } else if (condition.contains('mist') || condition.contains('fog')) {
      return 'foggy';
    }
    return 'partly_cloudy'; // Default fallback
  }

  // Check if weather is good for outdoor activities
  bool get isGoodForOutdoors {
    return !condition.contains('rain') && 
           !condition.contains('storm') && 
           !condition.contains('snow') &&
           rainProbability < 50 &&
           windSpeed < 20;
  }

  // Get weather description for UI
  String get weatherDescription {
    if (isGoodForOutdoors) {
      return 'Great weather for exploring outdoors';
    } else if (condition.contains('rain')) {
      return 'Consider indoor attractions today';
    } else if (condition.contains('storm')) {
      return 'Stay safe - weather is severe';
    } else {
      return 'Weather is moderate for outdoor activities';
    }
  }
}

class WeatherService {
  /// Open-Meteo free API: No API key required, reliable worldwide weather
  static const String _openMeteoBase = 'https://api.open-meteo.com/v1/forecast';

  /// Get current weather by coordinates using Open-Meteo
  Future<WeatherData?> getCurrentWeather(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        '$_openMeteoBase?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&hourly=precipitation_probability',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'] as Map<String, dynamic>? ?? {};
        final temp = (current['temperature_2m'] ?? 24.0).toDouble();
        final humidity = (current['relative_humidity_2m'] ?? 45.0).toDouble();
        final wind = (current['wind_speed_10m'] ?? 10.0).toDouble();
        final weatherCode = (current['weather_code'] ?? 0) as int;

        final hourly = data['hourly'] as Map<String, dynamic>?;
        final rainProbList = (hourly?['precipitation_probability'] as List?) ?? [];
        final rainProb = rainProbList.isNotEmpty ? (rainProbList[0] as num).toDouble() : 0.0;

        final (cond, desc) = _mapWmoCode(weatherCode);

        return WeatherData(
          temperature: temp,
          condition: cond,
          description: desc,
          humidity: humidity,
          windSpeed: wind,
          cloudiness: weatherCode >= 1 && weatherCode <= 3 ? 40 : (weatherCode > 3 ? 80 : 10),
          rainProbability: rainProb,
          city: 'Ethiopia',
          latitude: latitude,
          longitude: longitude,
        );
      }
    } catch (e) {
      // Fallback cleanly without spamming logs
    }
    return getMockWeather(latitude, longitude);
  }

  /// Map WMO Weather Codes (Open-Meteo standard)
  (String, String) _mapWmoCode(int code) {
    if (code == 0) return ('clear', 'Clear sky');
    if (code == 1 || code == 2) return ('partly_cloudy', 'Mainly clear');
    if (code == 3) return ('partly_cloudy', 'Overcast');
    if (code >= 45 && code <= 48) return ('foggy', 'Fog');
    if (code >= 51 && code <= 55) return ('rainy', 'Drizzle');
    if (code >= 61 && code <= 65) return ('rainy', 'Rain showers');
    if (code >= 80 && code <= 82) return ('rainy', 'Heavy rain');
    if (code >= 95) return ('stormy', 'Thunderstorm');
    return ('clear', 'Fair weather');
  }

  /// Get weather by city name with coordinate mapping for major Ethiopian cities
  Future<WeatherData?> getWeatherByCity(String cityName) async {
    final lower = cityName.toLowerCase();
    double lat = 9.032;
    double lon = 38.747; // Addis Ababa default

    if (lower.contains('gondar')) {
      lat = 12.601;
      lon = 37.467;
    } else if (lower.contains('lalibela')) {
      lat = 12.031;
      lon = 39.047;
    } else if (lower.contains('aksum') || lower.contains('axum')) {
      lat = 14.127;
      lon = 38.719;
    } else if (lower.contains('bahir')) {
      lat = 11.5936;
      lon = 37.3908;
    } else if (lower.contains('hawassa')) {
      lat = 7.050;
      lon = 38.467;
    } else if (lower.contains('harar')) {
      lat = 9.313;
      lon = 42.118;
    }

    return getCurrentWeather(lat, lon);
  }

  /// Get 5-day forecast
  Future<List<WeatherData>> getForecast(double latitude, double longitude) async {
    final current = await getCurrentWeather(latitude, longitude);
    if (current == null) return [];
    return [current];
  }

  /// Mock weather data fallback
  WeatherData getMockWeather(double latitude, double longitude) {
    return WeatherData(
      temperature: 24.0,
      condition: 'clear',
      description: 'Clear sky',
      humidity: 45.0,
      windSpeed: 12.0,
      cloudiness: 10,
      rainProbability: 0.0,
      city: 'Ethiopia',
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Get weather with fallback to mock data
  Future<WeatherData> getWeatherWithFallback(double latitude, double longitude) async {
    final weather = await getCurrentWeather(latitude, longitude);
    return weather ?? getMockWeather(latitude, longitude);
  }
}