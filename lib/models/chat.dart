import 'package:cloud_firestore/cloud_firestore.dart';

class ChatConversation {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String> participantRoles;
  final String channelType; // 'provider_tourist', 'guide_tourist', 'admin_support', 'emergency_sos'
  final String lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCounts;

  ChatConversation({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.participantRoles,
    this.channelType = 'provider_tourist',
    this.lastMessage = '',
    this.lastMessageAt,
    this.unreadCounts = const {},
  });

  String getOtherUserName(String currentUserId) {
    for (final entry in participantNames.entries) {
      if (entry.key != currentUserId) return entry.value;
    }
    return 'Chat User';
  }

  String getOtherUserRole(String currentUserId) {
    for (final entry in participantRoles.entries) {
      if (entry.key != currentUserId) return entry.value;
    }
    return 'tourist';
  }

  String getOtherUserId(String currentUserId) {
    for (final id in participantIds) {
      if (id != currentUserId) return id;
    }
    return '';
  }

  int getUnreadCount(String currentUserId) {
    return unreadCounts[currentUserId] ?? 0;
  }

  factory ChatConversation.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final pNames = <String, String>{};
    if (map['participantNames'] is Map) {
      (map['participantNames'] as Map).forEach((k, v) => pNames[k.toString()] = v.toString());
    }

    final pRoles = <String, String>{};
    if (map['participantRoles'] is Map) {
      (map['participantRoles'] as Map).forEach((k, v) => pRoles[k.toString()] = v.toString());
    }

    final unread = <String, int>{};
    if (map['unreadCounts'] is Map) {
      (map['unreadCounts'] as Map).forEach((k, v) => unread[k.toString()] = (v ?? 0) as int);
    }

    final pIds = <String>[];
    if (map['participantIds'] is List) {
      pIds.addAll((map['participantIds'] as List).map((e) => e.toString()));
    }

    return ChatConversation(
      id: id,
      participantIds: pIds,
      participantNames: pNames,
      participantRoles: pRoles,
      channelType: map['channelType'] as String? ?? 'provider_tourist',
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageAt: parseDate(map['lastMessageAt']),
      unreadCounts: unread,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantRoles': participantRoles,
      'channelType': channelType,
      'lastMessage': lastMessage,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCounts': unreadCounts,
    };
  }

  String get timeAgo {
    if (lastMessageAt == null) return '';
    final diff = DateTime.now().difference(lastMessageAt!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${lastMessageAt!.day}/${lastMessageAt!.month}';
  }
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String text;
  final double? latitude;
  final double? longitude;
  final bool isEmergency;
  final DateTime? createdAt;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderRole = 'tourist',
    required this.text,
    this.latitude,
    this.longitude,
    this.isEmergency = false,
    this.createdAt,
  });

  bool get hasLocation => latitude != null && longitude != null;

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return ChatMessage(
      id: id,
      chatId: map['chatId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      senderRole: map['senderRole'] as String? ?? 'tourist',
      text: map['text'] as String? ?? '',
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      isEmergency: map['isEmergency'] as bool? ?? false,
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'text': text,
      'latitude': latitude,
      'longitude': longitude,
      'isEmergency': isEmergency,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  String get formattedTime {
    if (createdAt == null) return '';
    final hour = createdAt!.hour.toString().padLeft(2, '0');
    final minute = createdAt!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
