import 'package:flutter/material.dart';

class ExploreCategory {
  final String id;
  final String label;
  final IconData icon;
  final String emoji;

  const ExploreCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.emoji,
  });
}

abstract final class ExploreCategories {
  static const base = [
    ExploreCategory(id: 'historical', label: 'History', icon: Icons.account_balance, emoji: '🏛️'),
    ExploreCategory(id: 'nature', label: 'Nature', icon: Icons.park, emoji: '🌿'),
    ExploreCategory(id: 'cultural', label: 'Culture', icon: Icons.theater_comedy, emoji: '🎭'),
    ExploreCategory(id: 'museum', label: 'Museum', icon: Icons.museum, emoji: '🏺'),
    ExploreCategory(id: 'religious', label: 'Religious', icon: Icons.church, emoji: '⛪'),
    ExploreCategory(id: 'adventure', label: 'Adventure', icon: Icons.hiking, emoji: '🧗'),
    ExploreCategory(id: 'food', label: 'Food', icon: Icons.restaurant, emoji: '🍽️'),
    ExploreCategory(id: 'hotels', label: 'Hotels', icon: Icons.hotel, emoji: '🏨'),
  ];

  static const guidedExtras = [
    ExploreCategory(id: 'guides', label: 'Tour Guides', icon: Icons.person, emoji: '👤'),
    ExploreCategory(id: 'guided_tours', label: 'Guided Tours', icon: Icons.map, emoji: '🗺️'),
  ];

  static const arExtras = [
    ExploreCategory(id: 'ar', label: 'AR Experiences', icon: Icons.view_in_ar, emoji: '📷'),
    ExploreCategory(id: 'nearby_ar', label: 'Nearby AR', icon: Icons.location_on, emoji: '📍'),
  ];

  static IconData iconForCategory(String category) {
    final id = category.toLowerCase();
    for (final c in base) {
      if (id.contains(c.id) || c.id.contains(id)) return c.icon;
    }
    if (id.contains('heritage') || id.contains('histor')) return Icons.account_balance;
    if (id.contains('culture')) return Icons.theater_comedy;
    return Icons.place;
  }

  static String emojiForCategory(String category) {
    final id = category.toLowerCase();
    for (final c in base) {
      if (id.contains(c.id) || c.id.contains(id)) return c.emoji;
    }
    return '📍';
  }

  static bool matchesCategory(String landmarkCategory, String filterId) {
    final lc = landmarkCategory.toLowerCase();
    final fid = filterId.toLowerCase();
    if (fid == 'historical') return lc.contains('herit') || lc.contains('histor');
    if (fid == 'cultural') return lc.contains('culture');
    if (fid == 'museum') return lc.contains('museum') || lc.contains('palace');
    return lc.contains(fid);
  }
}
