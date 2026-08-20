import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ai_conversation.dart';

class AiChatHistoryService {
  static final AiChatHistoryService instance = AiChatHistoryService._();
  AiChatHistoryService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Local in-memory cache for offline/instant access
  final Map<String, List<AiConversation>> _localCache = {};

  CollectionReference _convCol(String userId) {
    return _db.collection('users').doc(userId).collection('ai_conversations');
  }

  /// Save or update an AI conversation in Firestore and local cache
  Future<void> saveConversation(AiConversation conversation) async {
    // 1. Update local cache
    final list = _localCache.putIfAbsent(conversation.userId, () => []);
    final idx = list.indexWhere((c) => c.id == conversation.id);
    if (idx >= 0) {
      list[idx] = conversation;
    } else {
      list.insert(0, conversation);
    }

    // 2. Persist to Firestore if user is signed in
    if (conversation.userId.isNotEmpty && conversation.userId != 'guest') {
      try {
        await _convCol(conversation.userId)
            .doc(conversation.id)
            .set(conversation.toMap(), SetOptions(merge: true));
      } catch (e) {
        // ignore: avoid_print
        print('Error saving AI conversation to Firestore: $e');
      }
    }
  }

  /// Get list of saved conversations for a user
  Future<List<AiConversation>> getSavedConversations(String userId) async {
    if (userId.isEmpty || userId == 'guest') {
      return _localCache[userId] ?? [];
    }

    try {
      final snapshot = await _convCol(userId)
          .orderBy('updatedAt', descending: true)
          .get();

      final list = snapshot.docs
          .map((doc) => AiConversation.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      _localCache[userId] = list;
      return list;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching AI conversations: $e');
      return _localCache[userId] ?? [];
    }
  }

  /// Stream of saved conversations for real-time updates
  Stream<List<AiConversation>> getSavedConversationsStream(String userId) {
    if (userId.isEmpty || userId == 'guest') {
      return Stream.value(_localCache[userId] ?? []);
    }

    return _convCol(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AiConversation.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      _localCache[userId] = list;
      return list;
    });
  }

  /// Delete a saved conversation
  Future<void> deleteConversation(String userId, String conversationId) async {
    _localCache[userId]?.removeWhere((c) => c.id == conversationId);

    if (userId.isNotEmpty && userId != 'guest') {
      try {
        await _convCol(userId).doc(conversationId).delete();
      } catch (e) {
        // ignore: avoid_print
        print('Error deleting AI conversation: $e');
      }
    }
  }

  /// Rename a conversation
  Future<void> renameConversation(String userId, String conversationId, String newTitle) async {
    final list = _localCache[userId];
    if (list != null) {
      final idx = list.indexWhere((c) => c.id == conversationId);
      if (idx >= 0) {
        final existing = list[idx];
        list[idx] = AiConversation(
          id: existing.id,
          userId: existing.userId,
          title: newTitle,
          createdAt: existing.createdAt,
          updatedAt: DateTime.now(),
          messages: existing.messages,
          history: existing.history,
          city: existing.city,
          journeyMode: existing.journeyMode,
        );
      }
    }

    if (userId.isNotEmpty && userId != 'guest') {
      try {
        await _convCol(userId).doc(conversationId).update({
          'title': newTitle,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // ignore: avoid_print
        print('Error renaming AI conversation: $e');
      }
    }
  }
}
