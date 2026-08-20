class AiSavedMessage {
  final bool isUser;
  final String text;
  final bool isItinerary;
  final DateTime timestamp;

  AiSavedMessage({
    required this.isUser,
    required this.text,
    this.isItinerary = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'isUser': isUser,
      'text': text,
      'isItinerary': isItinerary,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AiSavedMessage.fromMap(Map<String, dynamic> map) {
    return AiSavedMessage(
      isUser: map['isUser'] ?? false,
      text: map['text'] ?? '',
      isItinerary: map['isItinerary'] ?? false,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AiConversation {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AiSavedMessage> messages;
  final List<Map<String, String>> history;
  final String city;
  final String journeyMode;

  AiConversation({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    this.history = const [],
    this.city = '',
    this.journeyMode = 'guided',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages.map((m) => m.toMap()).toList(),
      'history': history,
      'city': city,
      'journeyMode': journeyMode,
      'messageCount': messages.length,
      'preview': messages.isNotEmpty ? messages.first.text : '',
    };
  }

  factory AiConversation.fromMap(String id, Map<String, dynamic> map) {
    final rawMessages = map['messages'] as List? ?? [];
    final parsedMessages = rawMessages
        .whereType<Map>()
        .map((m) => AiSavedMessage.fromMap(Map<String, dynamic>.from(m)))
        .toList();

    final rawHistory = map['history'] as List? ?? [];
    final parsedHistory = rawHistory
        .whereType<Map>()
        .map((h) => Map<String, String>.from(h.map((k, v) => MapEntry(k.toString(), v.toString()))))
        .toList();

    return AiConversation(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? 'AI Conversation',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
      messages: parsedMessages,
      history: parsedHistory,
      city: map['city'] ?? '',
      journeyMode: map['journeyMode'] ?? 'guided',
    );
  }
}
