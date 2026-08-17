import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat.dart';
import 'notification_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get or create a 1-on-1 chat conversation between two users
  Future<ChatConversation> getOrCreateConversation({
    required String currentUserId,
    required String currentUserName,
    required String currentUserRole,
    required String otherUserId,
    required String otherUserName,
    required String otherUserRole,
    String channelType = 'provider_tourist',
  }) async {
    // Generate deterministic conversation ID
    final sortedIds = [currentUserId, otherUserId]..sort();
    final conversationId = 'chat_${sortedIds[0]}_${sortedIds[1]}';

    final docRef = _db.collection('chats').doc(conversationId);
    final doc = await docRef.get();

    if (doc.exists && doc.data() != null) {
      return ChatConversation.fromMap(doc.id, doc.data()!);
    }

    final newConversation = ChatConversation(
      id: conversationId,
      participantIds: [currentUserId, otherUserId],
      participantNames: {
        currentUserId: currentUserName,
        otherUserId: otherUserName,
      },
      participantRoles: {
        currentUserId: currentUserRole,
        otherUserId: otherUserRole,
      },
      channelType: channelType,
      lastMessage: 'Conversation started',
      lastMessageAt: DateTime.now(),
      unreadCounts: {
        currentUserId: 0,
        otherUserId: 0,
      },
    );

    await docRef.set(newConversation.toMap());
    return newConversation;
  }

  /// Stream of conversations for a user
  Stream<List<ChatConversation>> getUserConversationsStream(String userId) {
    if (userId.isEmpty) return Stream.value([]);

    return _db
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ChatConversation.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => (b.lastMessageAt ?? DateTime.now()).compareTo(a.lastMessageAt ?? DateTime.now()));
      return list;
    });
  }

  /// Stream of total unread messages count for a user across all chats
  Stream<int> getTotalUnreadMessagesCountStream(String userId) {
    return getUserConversationsStream(userId).map((list) {
      int sum = 0;
      for (final c in list) {
        sum += c.getUnreadCount(userId);
      }
      return sum;
    });
  }

  /// Stream of messages in a conversation
  Stream<List<ChatMessage>> getChatMessagesStream(String chatId) {
    if (chatId.isEmpty) return Stream.value([]);

    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Send a message in a conversation and update last message & unread counters
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String recipientId,
    required String text,
    double? latitude,
    double? longitude,
    bool isEmergency = false,
  }) async {
    final chatDoc = _db.collection('chats').doc(chatId);
    final msgDoc = chatDoc.collection('messages').doc();

    final message = ChatMessage(
      id: msgDoc.id,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      text: text,
      latitude: latitude,
      longitude: longitude,
      isEmergency: isEmergency,
      createdAt: DateTime.now(),
    );

    final batch = _db.batch();
    batch.set(msgDoc, message.toMap());

    // Update conversation metadata
    batch.update(chatDoc, {
      'lastMessage': isEmergency ? '🚨 SOS: $text' : text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCounts.$recipientId': FieldValue.increment(1),
    });

    await batch.commit();

    // Trigger in-app notification to recipient
    if (recipientId.isNotEmpty) {
      final title = isEmergency
          ? '🚨 EMERGENCY ALERT from $senderName'
          : 'New message from $senderName';
      await NotificationService().sendNotification(
        userId: recipientId,
        title: title,
        message: text,
        type: isEmergency ? 'emergency_sos' : 'chat_message',
        relatedId: chatId,
      );
    }
  }

  /// Mark chat as read for the current user
  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      await _db.collection('chats').doc(chatId).update({
        'unreadCounts.$userId': 0,
      });
    } catch (_) {}
  }
}
