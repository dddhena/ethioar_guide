import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/ai_conversation.dart';
import '../models/landmark.dart';
import '../models/trip.dart';
import '../services/ai_chat_history_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';
import '../services/interaction_service.dart';
import '../services/journey_preference_service.dart';
import '../services/location_service.dart';
import '../services/trip_service.dart';
import '../services/weather_service.dart';
import '../theme/ethio_theme.dart';
import '../widgets/add_to_trip_sheet.dart';
import '../widgets/notification_bell_button.dart';
import '../widgets/place_image.dart';
import 'create_trip_page.dart';
import 'landmark_detail_page.dart';
import 'trips_page.dart';

class AiGuideMessage {
  final bool isUser;
  final String text;
  final List<Landmark> placeCards;
  final bool isItinerary;
  final DateTime timestamp;

  AiGuideMessage({
    required this.isUser,
    required this.text,
    this.placeCards = const [],
    this.isItinerary = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AiGuidePage extends StatefulWidget {
  const AiGuidePage({super.key});

  @override
  State<AiGuidePage> createState() => _AiGuidePageState();
}

class _AiGuidePageState extends State<AiGuidePage> {
  final _gemini = GeminiService();
  final _auth = AuthService();
  final _fs = FirestoreService();
  final _weatherService = WeatherService();
  final _tripService = TripService();
  final _interaction = InteractionService();
  final _historyService = AiChatHistoryService.instance;

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<AiGuideMessage> _messages = [];
  final List<Map<String, String>> _history = [];

  String? _currentConversationId;
  String _currentConversationTitle = '';

  bool _loadingContext = true;
  bool _sending = false;

  String _currentCity = 'Gondar';
  double _userLat = 12.601;
  double _userLon = 37.467;
  WeatherData? _currentWeather;
  List<Landmark> _allLandmarks = [];
  List<String> _favoritePlaceNames = [];
  List<String> _upcomingTripNames = [];
  List<TouristTrip> _userTrips = [];

  static const List<Map<String, dynamic>> _quickActions = [
    {
      'icon': '🏛️',
      'title': 'Places to visit',
      'prompt': 'Show me historical and cultural places to visit around here.',
    },
    {
      'icon': '🗺️',
      'title': 'Plan my trip',
      'prompt': 'Plan a 3-day trip around Gondar and Lalibela with a day-by-day itinerary.',
    },
    {
      'icon': '🌦️',
      'title': 'What should I do today?',
      'prompt': 'What should I do today based on current weather conditions?',
    },
    {
      'icon': '🏨',
      'title': 'Find a hotel',
      'prompt': 'Recommend great Ethiopian hotels and lodges nearby with good ratings.',
    },
    {
      'icon': '🚗',
      'title': 'How do I get there?',
      'prompt': 'How do I get between major Ethiopian attractions and what transport options exist?',
    },
    {
      'icon': '✨',
      'title': 'Recommend places',
      'prompt': 'What places would you recommend based on my saved favorites and top attractions?',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContext() async {
    setState(() => _loadingContext = true);
    final uid = _auth.currentUser?.uid;

    try {
      final pos = await LocationService.getCurrentPositionWeb();
      if (pos != null) {
        _userLat = pos['latitude']!;
        _userLon = pos['longitude']!;
      }

      _allLandmarks = await _fs.fetchLandmarks();

      // Find nearest city or landmark
      if (_allLandmarks.isNotEmpty) {
        final nearby = LocationService.getNearbyLandmarks(
          currentLat: _userLat,
          currentLon: _userLon,
          landmarks: _allLandmarks,
          maxRadiusKm: 150,
        );
        if (nearby.isNotEmpty && nearby.first.landmark.city.isNotEmpty) {
          _currentCity = nearby.first.landmark.city;
        }
      }

      // Fetch Weather
      try {
        _currentWeather = await _weatherService.getWeatherWithFallback(_userLat, _userLon);
      } catch (_) {}

      // Fetch user context
      if (uid != null) {
        final favIds = await _interaction.getFavoritedAttractions(uid);
        _favoritePlaceNames = _allLandmarks
            .where((l) => favIds.contains(l.id))
            .map((l) => l.name)
            .toList();

        _userTrips = await _tripService.getTrips(uid);
        _upcomingTripNames = _userTrips.where((t) => !t.isCompleted).map((t) => t.name).toList();
      }
    } catch (e) {
      print('Error loading AI context: $e');
    }

    if (mounted) setState(() => _loadingContext = false);
  }

  AiGuideContext _buildAiGuideContext() {
    final nearby = LocationService.getNearbyLandmarks(
      currentLat: _userLat,
      currentLon: _userLon,
      landmarks: _allLandmarks,
      maxRadiusKm: 100,
    ).map((nl) => nl.landmark).toList();

    return AiGuideContext(
      city: _currentCity,
      latitude: _userLat,
      longitude: _userLon,
      weather: _currentWeather,
      journeyMode: JourneyPreferenceService.instance.mode.name,
      favoritePlaceNames: _favoritePlaceNames,
      upcomingTripNames: _upcomingTripNames,
      nearbyLandmarks: nearby,
    );
  }

  Future<void> _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    _inputController.clear();
    setState(() {
      _messages.add(AiGuideMessage(isUser: true, text: query));
      _sending = true;
    });
    _scrollToBottom();

    final aiContext = _buildAiGuideContext();

    final response = await _gemini.chat(
      userMessage: query,
      context: aiContext,
      allLandmarks: _allLandmarks,
      history: _history,
    );

    _history.addAll([
      {'role': 'user', 'text': query},
      {'role': 'model', 'text': response.text},
    ]);

    if (mounted) {
      setState(() {
        _messages.add(AiGuideMessage(
          isUser: false,
          text: response.text,
          placeCards: response.placeCards,
          isItinerary: response.isItinerary,
        ));
        _sending = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startNewChat() {
    if (_messages.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start New Chat?'),
        content: const Text('Your current conversation will be cleared unless you save it first.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _saveConversation();
            },
            child: const Text('Save First'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EthioColors.forest, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _messages.clear();
                _history.clear();
                _currentConversationId = null;
                _currentConversationTitle = '';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Started a new AI conversation ✨')),
              );
            },
            child: const Text('New Chat'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveConversation() async {
    if (_messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No messages to save yet. Start chatting first!')),
      );
      return;
    }

    final defaultTitle = _currentConversationTitle.isNotEmpty
        ? _currentConversationTitle
        : (_messages.firstWhere((m) => m.isUser, orElse: () => _messages.first).text);
    final titleCtrl = TextEditingController(
      text: defaultTitle.length > 40 ? '${defaultTitle.substring(0, 40)}...' : defaultTitle,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bookmark_add, color: EthioColors.forest),
            SizedBox(width: 8),
            Text('Save Conversation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Give this conversation a title to easily find it later:'),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Conversation Title',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EthioColors.forest, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final uid = _auth.currentUser?.uid ?? 'guest';
    final convId = _currentConversationId ?? 'ai_conv_${DateTime.now().millisecondsSinceEpoch}';
    final title = titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : 'AI Guide Conversation';

    final savedMessages = _messages
        .map((m) => AiSavedMessage(
              isUser: m.isUser,
              text: m.text,
              isItinerary: m.isItinerary,
              timestamp: m.timestamp,
            ))
        .toList();

    final conv = AiConversation(
      id: convId,
      userId: uid,
      title: title,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: savedMessages,
      history: _history,
      city: _currentCity,
      journeyMode: JourneyPreferenceService.instance.mode.name,
    );

    await _historyService.saveConversation(conv);

    if (mounted) {
      setState(() {
        _currentConversationId = convId;
        _currentConversationTitle = title;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conversation "$title" saved! 💾')),
      );
    }
  }

  void _showSavedConversationsSheet() {
    final uid = _auth.currentUser?.uid ?? 'guest';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: EthioColors.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.history_rounded, color: EthioColors.forest),
                            SizedBox(width: 8),
                            Text('Saved Conversations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: FutureBuilder<List<AiConversation>>(
                      future: _historyService.getSavedConversations(uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: EthioColors.forest),
                          );
                        }

                        final list = snapshot.data ?? [];
                        if (list.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bookmark_border, size: 56, color: EthioColors.muted.withValues(alpha: 0.5)),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No Saved Conversations Yet',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: EthioColors.charcoal),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Tap the save icon (💾) during any chat to save your conversations.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: EthioColors.muted),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = list[index];
                            final isCurrent = item.id == _currentConversationId;

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isCurrent ? EthioColors.forest : EthioColors.divider,
                                  width: isCurrent ? 2 : 1,
                                ),
                              ),
                              color: Colors.white,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                title: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isCurrent ? EthioColors.forest : EthioColors.charcoal,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.messages.length} messages • ${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
                                      style: const TextStyle(fontSize: 12, color: EthioColors.muted),
                                    ),
                                    if (item.messages.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.messages.first.text,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                      tooltip: 'Delete',
                                      onPressed: () async {
                                        await _historyService.deleteConversation(uid, item.id);
                                        setSheetState(() {});
                                        if (item.id == _currentConversationId) {
                                          _currentConversationId = null;
                                        }
                                      },
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: EthioColors.forest,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        setState(() {
                                          _currentConversationId = item.id;
                                          _currentConversationTitle = item.title;
                                          _messages.clear();
                                          _history.clear();

                                          for (final m in item.messages) {
                                            final placeCards = m.isUser
                                                ? <Landmark>[]
                                                : _gemini.matchLandmarksInText(m.text, _allLandmarks);
                                            _messages.add(AiGuideMessage(
                                              isUser: m.isUser,
                                              text: m.text,
                                              placeCards: placeCards,
                                              isItinerary: m.isItinerary,
                                              timestamp: m.timestamp,
                                            ));
                                          }

                                          _history.addAll(item.history);
                                        });
                                        _scrollToBottom();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Loaded "${item.title}"')),
                                        );
                                      },
                                      child: const Text('Load', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showApiKeyDialog() {
    final keyCtrl = TextEditingController(text: ApiConfig.geminiApiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: EthioColors.forest),
            SizedBox(width: 8),
            Text('Gemini API Key', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Google Gemini API key to activate real-time AI responses:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyCtrl,
              decoration: const InputDecoration(
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EthioColors.forest, foregroundColor: Colors.white),
            onPressed: () {
              ApiConfig.customApiKey = keyCtrl.text.trim();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ApiConfig.hasGeminiKey
                      ? 'Gemini API Key connected successfully! ✨'
                      : 'Key cleared.'),
                ),
              );
              setState(() {});
            },
            child: const Text('Save Key'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EthioColors.cream,
      appBar: AppBar(
        title: const Text('AI Travel Guide'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'New Chat',
            onPressed: _startNewChat,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'Save Conversation',
            onPressed: _saveConversation,
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Saved Conversations',
            onPressed: _showSavedConversationsSheet,
          ),
          IconButton(
            icon: Icon(
              ApiConfig.hasGeminiKey ? Icons.bolt : Icons.vpn_key_outlined,
              color: ApiConfig.hasGeminiKey ? Colors.amber.shade700 : EthioColors.charcoal,
            ),
            tooltip: ApiConfig.hasGeminiKey ? 'Gemini AI Connected' : 'Configure Gemini API Key',
            onPressed: _showApiKeyDialog,
          ),
          const NotificationBellButton(color: EthioColors.charcoal),
        ],
      ),
      body: Column(
        children: [
          // ── Real-time Context Banner ─────────────────────────────
          _buildContextBanner(),

          // ── Conversation or Quick Action Hub ─────────────────────
          Expanded(
            child: _messages.isEmpty ? _buildWelcomeHub() : _buildMessageList(),
          ),

          // ── Input Bar ────────────────────────────────────────────
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildContextBanner() {
    final tempStr = _currentWeather != null
        ? '${_currentWeather!.temperature.toStringAsFixed(0)}°C'
        : '24°C';
    final descStr = _currentWeather != null
        ? _currentWeather!.description
        : 'Clear skies • Great weather for exploring';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EthioColors.forest.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: EthioColors.forest.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on, color: EthioColors.forest, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You're in $_currentCity",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '☀️ $tempStr • $descStr',
                  style: const TextStyle(fontSize: 12, color: EthioColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _showApiKeyDialog,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ApiConfig.hasGeminiKey
                    ? Colors.amber.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ApiConfig.hasGeminiKey
                      ? Colors.amber.shade400
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    ApiConfig.hasGeminiKey ? Icons.bolt : Icons.key_outlined,
                    size: 13,
                    color: ApiConfig.hasGeminiKey
                        ? Colors.amber.shade900
                        : Colors.grey.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ApiConfig.hasGeminiKey ? 'Gemini Live' : 'Set Key',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: ApiConfig.hasGeminiKey
                          ? Colors.amber.shade900
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHub() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Text('✨', style: TextStyle(fontSize: 36)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your Travel Companion',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: EthioColors.charcoal),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ask me about places, weather, hotels, routes, tours or planning your trip.',
                textAlign: TextAlign.center,
                style: TextStyle(color: EthioColors.muted, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'What can I help you with?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: EthioColors.charcoal),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
          ),
          itemCount: _quickActions.length,
          itemBuilder: (context, i) {
            final action = _quickActions[i];
            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => _sendMessage(action['prompt'] as String),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: EthioColors.divider),
                  ),
                  child: Row(
                    children: [
                      Text(action['icon'] as String, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          action['title'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: _messages.length + (_sending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _sending) {
          return _buildTypingIndicator();
        }
        final msg = _messages[index];
        return _buildMessageBubble(msg);
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EthioColors.divider),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: EthioColors.forest),
            ),
            SizedBox(width: 10),
            Text('AI Guide is thinking...', style: TextStyle(fontSize: 13, color: EthioColors.muted)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AiGuideMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          decoration: BoxDecoration(
            color: EthioColors.forest,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
          ),
          child: Text(
            msg.text,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      );
    }

    // AI Assistant response with interactive place cards
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('✨', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 6),
                const Text('AI Travel Guide', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: EthioColors.forest)),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EthioColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: const TextStyle(fontSize: 14.5, height: 1.4, color: EthioColors.charcoal),
                  ),

                  // ── Interactive Place Cards ────────────────────────
                  if (msg.placeCards.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    ...msg.placeCards.map((place) => _buildInteractivePlaceCard(place)),
                  ],

                  // ── Itinerary "Add to My Trip" Button ───────────────
                  if (msg.isItinerary) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const TripsPage()),
                          );
                        },
                        icon: const Icon(Icons.add_task),
                        label: const Text('Add to My Trips 📅'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EthioColors.forest,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractivePlaceCard(Landmark place) {
    final distanceStr = formatLandmarkDistance(place, _userLat, _userLon);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: EthioColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EthioColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            leading: SizedBox(
              width: 50,
              height: 50,
              child: PlaceImage(landmark: place, height: 50, borderRadius: BorderRadius.circular(8)),
            ),
            title: Text(place.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('⭐ ${place.rating.toStringAsFixed(1)}  •  📍 $distanceStr'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => LandmarkDetailPage(landmark: place)),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('View Place →', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.bookmark_add_outlined, size: 20, color: EthioColors.forest),
                  tooltip: 'Add to Trip',
                  onPressed: () => AddToTripSheet.show(context, place),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: EthioColors.cream,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: EthioColors.divider),
              ),
              child: TextField(
                controller: _inputController,
                decoration: const InputDecoration(
                  hintText: 'Ask your travel guide anything...',
                  hintStyle: TextStyle(fontSize: 13, color: EthioColors.muted),
                  border: InputBorder.none,
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: EthioColors.forest,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: () => _sendMessage(_inputController.text),
            ),
          ),
        ],
      ),
    );
  }
}
