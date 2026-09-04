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

  static const _defaultModels = [
    'gemini-3.6-flash',
    'gemini-3.7-flash',
    'gemini-3.8-flash',
    'gemini-2.5-flash',
    'gemini-flash',
  ];

  static List<String> _cachedModels = [];
  static DateTime? _lastModelFetchTime;
  String _activeModel = 'gemini-3.6-flash';

  /// Dynamically queries Google Generative Language API for models supporting generateContent.
  /// This ensures any new Gemini models released by Google in the future are discovered automatically.
  static Future<List<String>> listAvailableModels({String? apiKey}) async {
    final key = apiKey ?? ApiConfig.geminiApiKey;
    if (key.trim().isEmpty) return [];

    if (_cachedModels.isNotEmpty &&
        _lastModelFetchTime != null &&
        DateTime.now().difference(_lastModelFetchTime!).inMinutes < 60) {
      return _cachedModels;
    }

    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$key');
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final rawList = data['models'] as List?;
        if (rawList != null) {
          final found = <String>[];
          for (final item in rawList) {
            final name = (item['name'] as String? ?? '').replaceFirst('models/', '');
            final methods = (item['supportedGenerationMethods'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
            if (methods.contains('generateContent') && name.contains('gemini')) {
              found.add(name);
            }
          }
          if (found.isNotEmpty) {
            // Sort: prioritize 'flash' and newer version numbers
            found.sort((a, b) {
              final aFlash = a.contains('flash');
              final bFlash = b.contains('flash');
              if (aFlash && !bFlash) return -1;
              if (!aFlash && bFlash) return 1;
              return b.compareTo(a);
            });
            _cachedModels = found;
            _lastModelFetchTime = DateTime.now();
            return found;
          }
        }
      }
    } catch (e) {
      print('[GeminiService] Dynamic model list notice: $e');
    }
    return _cachedModels.isNotEmpty ? _cachedModels : _defaultModels;
  }

  /// Tests Gemini connection with the current or provided API key.
  Future<Map<String, dynamic>> testConnection({String? apiKey}) async {
    final key = (apiKey != null && apiKey.trim().isNotEmpty) ? apiKey.trim() : ApiConfig.geminiApiKey;
    if (key.isEmpty) {
      return {'success': false, 'message': 'API Key is empty. Please enter a valid Gemini API key.'};
    }

    // 1. Discover live available models from Google API
    final available = await listAvailableModels(apiKey: key);
    final primaryModel = ApiConfig.selectedGeminiModel.isNotEmpty
        ? ApiConfig.selectedGeminiModel
        : (available.isNotEmpty ? available.first : 'gemini-3.6-flash');

    final testModels = [
      primaryModel,
      ...available.where((m) => m != primaryModel),
      ..._defaultModels.where((m) => m != primaryModel && !available.contains(m)),
    ];

    for (final model in testModels.take(4)) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key',
        );
        final body = json.encode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': 'Hello from EthioAR Guide! Reply with a 5-word warm greeting.'}
              ]
            }
          ],
          'generationConfig': {'maxOutputTokens': 50, 'temperature': 0.7}
        });

        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        ).timeout(const Duration(seconds: 15));

        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          String reply = 'Connected';
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final firstCandidate = candidates[0];
            if (firstCandidate is Map) {
              final content = firstCandidate['content'];
              if (content is Map) {
                final parts = content['parts'];
                if (parts is List && parts.isNotEmpty) {
                  final firstPart = parts[0];
                  if (firstPart is Map && firstPart['text'] != null) {
                    reply = firstPart['text'].toString();
                  }
                }
              }
            }
          }

          _activeModel = model;
          ApiConfig.selectedGeminiModel = model;
          return {
            'success': true,
            'model': model,
            'reply': reply.trim(),
            'message': 'Connected to Gemini ($model)! AI Guide is live.',
            'availableModels': available,
          };
        } else if (res.statusCode == 404) {
          // Check if Google returned a recommended model in the error message
          final match = RegExp(r'models/([a-zA-Z0-9\.\-_]+)').firstMatch(res.body);
          if (match != null) {
            final suggested = match.group(1);
            if (suggested != null && !testModels.contains(suggested)) {
              testModels.add(suggested);
            }
          }
        }
      } catch (e) {
        // Try next model in sequence
      }
    }

    return {
      'success': false,
      'message': 'Could not connect to Gemini models. Check your internet connection and API key.',
      'availableModels': available,
    };
  }

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
        note: '💡 Offline Travel Guide Mode active.',
      );
    }

    final promptText = '${context.toPromptBlock()}\n\nUser Question: $userMessage';

    // 1. Gather candidate models: preference -> discovered -> defaults
    final preferred = ApiConfig.selectedGeminiModel.isNotEmpty
        ? ApiConfig.selectedGeminiModel
        : _activeModel;

    final candidateSet = <String>{preferred, _activeModel};
    if (_cachedModels.isNotEmpty) {
      candidateSet.addAll(_cachedModels);
    } else {
      candidateSet.addAll(_defaultModels);
    }

    final modelsToTry = candidateSet.toList();
    String? lastError;

    for (int i = 0; i < modelsToTry.length; i++) {
      final modelName = modelsToTry[i];
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
            {'text': promptText}
          ],
        });

        final body = json.encode({
          'systemInstruction': {
            'parts': [
              {'text': _systemPrompt}
            ]
          },
          'contents': contents,
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1200,
          },
        });

        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(const Duration(seconds: 20));

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
                _activeModel = modelName;
                ApiConfig.selectedGeminiModel = modelName;
                print('[GeminiService] Successfully received response from $modelName');

                final placeCards = matchLandmarksInText(rawText, allLandmarks);
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

          // Auto-discover model recommendations from API response
          final recMatch = RegExp(r'use models/([a-zA-Z0-9\.\-_]+)').firstMatch(errBody) ??
              RegExp(r'models/([a-zA-Z0-9\.\-_]+)').firstMatch(errBody);
          if (recMatch != null) {
            final recModel = recMatch.group(1);
            if (recModel != null && !modelsToTry.contains(recModel)) {
              print('[GeminiService] Auto-discovered newer Gemini model from API: $recModel');
              modelsToTry.insert(i + 1, recModel);
            }
          }

          if (response.statusCode == 400 || response.statusCode == 403) {
            try {
              final errJson = json.decode(errBody);
              final msg = errJson['error']?['message'];
              if (msg != null) lastError = msg.toString();
            } catch (_) {}
            // If it's a key permission/invalid key issue, stop trying
            if (response.statusCode == 403) break;
          }
        }
      } catch (e) {
        print('[GeminiService] Request failed for $modelName: $e');
        lastError = e.toString();
      }
    }

    // Trigger background refresh of models for next time if failed
    listAvailableModels(apiKey: apiKey).then((models) {
      if (models.isNotEmpty) _cachedModels = models;
    }).catchError((_) {});

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

  List<Landmark> matchLandmarksInText(String text, List<Landmark> landmarks) {
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
