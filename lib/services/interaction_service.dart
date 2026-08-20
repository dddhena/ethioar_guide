import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_interaction.dart';

class InteractionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Track a user interaction with an attraction
  Future<void> trackInteraction({
    required String touristId,
    required String attractionId,
    required String interactionType,
    dynamic value,
  }) async {
    try {
      await _db.collection('user_interactions').add({
        'touristId': touristId,
        'attractionId': attractionId,
        'interactionType': interactionType,
        'value': value,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail to not disrupt user experience
      print('Error tracking interaction: $e');
    }
  }

  /// Get all interactions for a specific tourist
  Future<List<UserInteraction>> getUserInteractions(String touristId) async {
    try {
      final snapshot = await _db
          .collection('user_interactions')
          .where('touristId', isEqualTo: touristId)
          .get();

      final list = snapshot.docs
          .map((doc) => UserInteraction.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    } catch (e) {
      return [];
    }
  }

  /// Get interactions for a specific attraction
  Future<List<UserInteraction>> getAttractionInteractions(String attractionId) async {
    try {
      final snapshot = await _db
          .collection('user_interactions')
          .where('attractionId', isEqualTo: attractionId)
          .get();

      final list = snapshot.docs
          .map((doc) => UserInteraction.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    } catch (e) {
      return [];
    }
  }

  /// Get user's interaction history for a specific attraction
  Future<List<UserInteraction>> getUserAttractionInteractions(
    String touristId, 
    String attractionId
  ) async {
    try {
      final snapshot = await _db
          .collection('user_interactions')
          .where('touristId', isEqualTo: touristId)
          .where('attractionId', isEqualTo: attractionId)
          .get();

      final list = snapshot.docs
          .map((doc) => UserInteraction.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    } catch (e) {
      return [];
    }
  }

  /// Calculate user's preference scores for different categories
  Future<Map<String, double>> calculateUserPreferences(String touristId) async {
    final interactions = await getUserInteractions(touristId);
    final categoryScores = <String, double>{};

    // Group interactions by attraction and calculate total weight
    final attractionWeights = <String, double>{};
    for (final interaction in interactions) {
      final currentWeight = attractionWeights[interaction.attractionId] ?? 0.0;
      attractionWeights[interaction.attractionId] = currentWeight + interaction.weight;
    }

    // Fetch attraction details to get categories
    for (final entry in attractionWeights.entries) {
      try {
        final attractionDoc = await _db.collection('landmarks').doc(entry.key).get();
        if (attractionDoc.exists) {
          final category = attractionDoc.data()?['category'] ?? 'heritage';
          final currentScore = categoryScores[category] ?? 0.0;
          categoryScores[category] = currentScore + entry.value;
        }
      } catch (e) {
        // Skip if attraction not found
      }
    }

    return categoryScores;
  }

  /// Check if user has any interaction history
  Future<bool> hasInteractionHistory(String touristId) async {
    final interactions = await getUserInteractions(touristId);
    return interactions.isNotEmpty;
  }

  /// Get recently viewed attractions (for "Because you like" section)
  Future<List<String>> getRecentlyViewedAttractions(String touristId, {int limit = 10}) async {
    try {
      final snapshot = await _db
          .collection('user_interactions')
          .where('touristId', isEqualTo: touristId)
          .where('interactionType', isEqualTo: UserInteraction.view)
          .get();

      final list = snapshot.docs
          .map((doc) => UserInteraction.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list.take(limit).map((i) => i.attractionId).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get favorited attractions
  Future<List<String>> getFavoritedAttractions(String touristId) async {
    try {
      final snapshot = await _db
          .collection('user_interactions')
          .where('touristId', isEqualTo: touristId)
          .where('interactionType', isEqualTo: UserInteraction.favorite)
          .get();

      return snapshot.docs.map((doc) => doc.data()['attractionId'] as String).toList();
    } catch (e) {
      print('Error fetching favorited attractions: $e');
      return [];
    }
  }

  /// Check if an attraction is favorited
  Future<bool> isFavorited(String touristId, String attractionId) async {
    try {
      final snapshot = await _db
          .collection('user_interactions')
          .where('touristId', isEqualTo: touristId)
          .where('attractionId', isEqualTo: attractionId)
          .where('interactionType', isEqualTo: UserInteraction.favorite)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Toggle favorite status — returns new state (true = favorited)
  Future<bool> toggleFavorite(String touristId, String attractionId) async {
    try {
      final snapshot = await _db
          .collection('user_interactions')
          .where('touristId', isEqualTo: touristId)
          .where('attractionId', isEqualTo: attractionId)
          .where('interactionType', isEqualTo: UserInteraction.favorite)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.delete();
        return false;
      }

      await trackInteraction(
        touristId: touristId,
        attractionId: attractionId,
        interactionType: UserInteraction.favorite,
      );
      return true;
    } catch (e) {
      print('Error toggling favorite: $e');
      return false;
    }
  }
}