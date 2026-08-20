import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/landmark.dart';
import '../services/weather_service.dart';

class AiGuideContext {
  final String? city;
  final double latitude;
  final double longitude;
  final WeatherData? weather;
  final String journeyMode;
  final List<String> favoritePlaceNames;
  final List<String> upcomingTripNames;
  final List<Landmark> nearbyLandmarks;

  AiGuideContext({
    this.city,
    required this.latitude,
    required this.longitude,
    this.weather,
    this.journeyMode = 'guided',
    this.favoritePlaceNames = const [],
    this.upcomingTripNames = const [],
    this.nearbyLandmarks = const [],
  });

  String toPromptBlock() {
    final buffer = StringBuffer();
    buffer.writeln('Tourist context:');
    if (city != null && city!.isNotEmpty) buffer.writeln('- Current area: $city');
    buffer.writeln('- Coordinates: $latitude, $longitude');
    buffer.writeln('- Journey mode: $journeyMode');
    if (weather != null) {
      buffer.writeln('- Weather: ${weather!.temperature.toStringAsFixed(0)}°C, ${weather!.description}');
      buffer.writeln('- Outdoor suitable: ${weather!.isGoodForOutdoors}');
    }
    if (favoritePlaceNames.isNotEmpty) {
      buffer.writeln('- Saved favorites: ${favoritePlaceNames.join(", ")}');
    }
    if (upcomingTripNames.isNotEmpty) {
      buffer.writeln('- Upcoming trips: ${upcomingTripNames.join(", ")}');
    }
    if (nearbyLandmarks.isNotEmpty) {
      buffer.writeln('- Nearby places: ${nearbyLandmarks.take(5).map((l) => l.name).join(", ")}');
    }
    return buffer.toString();
  }
}

class AiGuideResponse {
  final String text;
  final List<Landmark> placeCards;
  final bool isItinerary;
  final bool isFromGemini;
  final String? errorMessage;

  AiGuideResponse({
    required this.text,
    this.placeCards = const [],
    this.isItinerary = false,
    this.isFromGemini = true,
    this.errorMessage,
  });
}

class GeminiService {
  static const _systemPrompt = '''
You are the AI Travel Guide for EthioAR Guide, an Ethiopian tourism application.
You are a warm, highly knowledgeable, and conversational travel assistant.
Keep responses concise, clear, and structured. Use the tourist's current context (location, weather, favorites, trips).
When recommending places, hotels, or transport, mention specific Ethiopian sites and attractions (e.g., Fasil Ghebbi, Lalibela Rock-Hewn Churches, Simien Mountains, Lake Tana monasteries, Aksum Obelisk, Harar Jugol, Blue Nile Falls).
When answering itinerary/trip questions, provide structured day-by-day plans with timings and place names.
Suggest indoor/museum activities if weather is rainy or stormy.
''';

  static const List<String> _models = [
    'gemini-3.6-flash',
    'gemini-3.6-pro',
  ];

  String _activeModel = 'gemini-3.6-flash';

  Future<AiGuideResponse> chat({
    required String userMessage,
    required AiGuideContext context,
    required List<Landmark> allLandmarks,
    List<Map<String, String>> history = const [],
  }) async {
    final apiKey = ApiConfig.geminiApiKey;

    if (!ApiConfig.hasGeminiKey) {
      print('[GeminiService] No API key configured. Using offline travel guide knowledge.');
      return _fallbackResponse(
        userMessage,
        context,
        allLandmarks,
        note: '💡 Tip: Tap the 🔑 icon at the top to add your Gemini API Key for live AI answers!',
      );
    }

    final promptText = '${context.toPromptBlock()}\n\nUser Question: $userMessage';

    // Try models in sequence
    final modelsToTry = [
      _activeModel,
      ..._models.where((m) => m != _activeModel),
    ];

    String? lastError;

    for (final modelName in modelsToTry) {
      try {
        print('[GeminiService] Calling Gemini API ($modelName)...');
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
        );

        final contents = <Map<String, dynamic>>[];

        for (final h in history) {
          contents.add({
            'role': h['role'] == 'user' ? 'user' : 'model',
            'parts': [
              {'text': h['text'] ?? ''}
            ],
          });
        }

        contents.add({
          'role': 'user',
          'parts': [
            {'text': 'System: $_systemPrompt\n\n$promptText'}
          ],
        });

        final body = json.encode({
          'contents': contents,
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1000,
          },
        });

        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(const Duration(seconds: 30));

        print('[GeminiService] HTTP ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final rawText = parts[0]['text'] as String?;
              if (rawText != null && rawText.trim().isNotEmpty) {
                _activeModel = modelName; // remember the successful model
                print('[GeminiService] Successfully received response from $modelName');

                final placeCards = _matchLandmarksInText(rawText, allLandmarks);
                final isItinerary = userMessage.toLowerCase().contains('plan') ||
                    userMessage.toLowerCase().contains('itinerary') ||
                    rawText.toLowerCase().contains('day 1');

                return AiGuideResponse(
                  text: rawText.trim(),
                  placeCards: placeCards,
                  isItinerary: isItinerary,
                  isFromGemini: true,
                );
              }
            }
          }
        } else {
          final errBody = response.body;
          print('[GeminiService] API Error ($modelName): ${response.statusCode} - $errBody');
          lastError = 'HTTP ${response.statusCode}';
          if (response.statusCode == 400 || response.statusCode == 403) {
            // Likely invalid API key or permission
            try {
              final errJson = json.decode(errBody);
              final msg = errJson['error']?['message'];
              if (msg != null) lastError = msg.toString();
            } catch (_) {}
            break;
          }
        }
      } catch (e) {
        print('[GeminiService] Request failed for $modelName: $e');
        lastError = e.toString();
      }
    }

    print('[GeminiService] Falling back to structured responses. Last error: $lastError');
    return _fallbackResponse(
      userMessage,
      context,
      allLandmarks,
      errorMessage: lastError,
    );
  }

  AiGuideResponse _fallbackResponse(
    String message,
    AiGuideContext context,
    List<Landmark> landmarks, {
    String? note,
    String? errorMessage,
  }) {
    final lower = message.toLowerCase();
    final nearby = context.nearbyLandmarks.isNotEmpty
        ? context.nearbyLandmarks
        : landmarks.take(3).toList();

    String extraNote = '';
    if (note != null) {
      extraNote = '\n\n$note';
    } else if (errorMessage != null) {
      extraNote = '\n\n*(Note: Gemini connection issue ($errorMessage). Showing curated travel knowledge.)*';
    }

    if (lower.contains('weather') || lower.contains('today')) {
      final w = context.weather;
      final weatherNote = w != null
          ? 'It is ${w.temperature.toStringAsFixed(0)}°C with ${w.description}. ${w.weatherDescription}.'
          : 'The weather is currently clear and pleasant in ${context.city ?? "Ethiopia"}.';
      final suggestions = w != null && !w.isGoodForOutdoors
          ? landmarks.where((l) => !l.outdoorFriendly).take(3).toList()
          : nearby.take(3).toList();
      return AiGuideResponse(
        text: '$weatherNote\n\nHere are places that fit today\'s conditions:$extraNote',
        placeCards: suggestions,
        isFromGemini: false,
        errorMessage: errorMessage,
      );
    }

    if (lower.contains('plan') || lower.contains('itinerary')) {
      final names = nearby.take(3).map((l) => l.name).toList();
      return AiGuideResponse(
        text: '''Suggested 3-Day Ethiopian Itinerary:

DAY 1: Historical Wonders
09:00  ${names.isNotEmpty ? names[0] : 'Morning historical landmark visit'}
11:30  ${names.length > 1 ? names[1] : 'Cultural heritage site'}
14:00  Traditional Ethiopian lunch (Injera with Tibs)
15:30  ${names.length > 2 ? names[2] : 'Evening exploration'}

DAY 2: Nature & Culture
09:00  Scenic viewpoints and local craft markets
11:00  Museum or religious landmark
14:00  Coffee ceremony and local gastronomy

DAY 3: Exploration & Leisure
09:00  Excursion to nearby natural reserve
14:00  Farewell cultural dinner and music

Tap "Add to My Trips" below to save this plan!$extraNote''',
        placeCards: nearby.take(3).toList(),
        isItinerary: true,
        isFromGemini: false,
        errorMessage: errorMessage,
      );
    }

    if (lower.contains('hotel') || lower.contains('lodge')) {
      return AiGuideResponse(
        text: '''Here are highly rated accommodations in ${context.city ?? "Ethiopia"}:
• Heritage Lodges (Authentic stone architecture & scenic views)
• City Hotels (Modern amenities, central location & airport shuttle)
• Boutique Guesthouses (Warm Ethiopian hospitality & traditional breakfast)$extraNote''',
        placeCards: nearby.take(2).toList(),
        isFromGemini: false,
        errorMessage: errorMessage,
      );
    }

    if (lower.contains('transport') || lower.contains('get there') || lower.contains('route')) {
      return AiGuideResponse(
        text: '''Transportation options around ${context.city ?? "Ethiopia"}:
• Domestic Flights: Ethiopian Airlines connects major tourist hubs (Gondar, Lalibela, Axum, Bahir Dar) daily.
• Private Tourist Vans & 4x4s: Ideal for exploring historical circuits and Simien Mountains.
• Local Taxis & Bajajes: Perfect for moving within the city.$extraNote''',
        placeCards: nearby.take(2).toList(),
        isFromGemini: false,
        errorMessage: errorMessage,
      );
    }

    if (lower.contains('recommend') || lower.contains('like')) {
      return AiGuideResponse(
        text: context.favoritePlaceNames.isNotEmpty
            ? 'Based on your saved favorites (${context.favoritePlaceNames.take(2).join(", ")}), here are top recommendations:$extraNote'
            : 'Here are hand-picked must-visit attractions in Ethiopia:$extraNote',
        placeCards: nearby.take(4).toList(),
        isFromGemini: false,
        errorMessage: errorMessage,
      );
    }

    return AiGuideResponse(
      text: '''I'm your AI Travel Guide for Ethiopia! 🇪🇹
I can assist you with:
• 🏛️ Exploring historical and cultural landmarks
• 🗺️ Planning custom itineraries
• 🌦️ Weather-aware daily recommendations
• 🏨 Hotels, transport routes, and tour guides

${context.city != null ? "You're currently exploring around ${context.city}." : ''}$extraNote''',
      placeCards: nearby.take(3).toList(),
      isFromGemini: false,
      errorMessage: errorMessage,
    );
  }

  List<Landmark> _matchLandmarksInText(String text, List<Landmark> landmarks) {
    final lower = text.toLowerCase();
    final matched = <Landmark>[];
    for (final lm in landmarks) {
      if (lower.contains(lm.name.toLowerCase()) ||
          (lm.city.isNotEmpty && lower.contains(lm.city.toLowerCase()))) {
        if (!matched.contains(lm)) {
          matched.add(lm);
        }
      }
    }
    if (matched.isEmpty && landmarks.isNotEmpty) {
      return landmarks.take(2).toList();
    }
    return matched.take(4).toList();
  }
}
