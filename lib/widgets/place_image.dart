import 'package:flutter/material.dart';
import '../models/landmark.dart';
import '../theme/ethio_theme.dart';
import 'explore_categories.dart';

class PlaceImage extends StatelessWidget {
  final Landmark landmark;
  final double height;
  final BorderRadius? borderRadius;

  const PlaceImage({
    super.key,
    required this.landmark,
    this.height = 160,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);

    if (landmark.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          landmark.imageUrl,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(radius),
        ),
      );
    }
    return _placeholder(radius);
  }

  Widget _placeholder(BorderRadius radius) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          colors: [
            _categoryColor(landmark.category),
            _categoryColor(landmark.category).withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          ExploreCategories.iconForCategory(landmark.category),
          size: height * 0.3,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'nature':
        return EthioColors.forest;
      case 'religious':
        return EthioColors.slate;
      case 'culture':
      case 'cultural':
        return EthioColors.terracotta;
      case 'adventure':
        return Colors.orange.shade700;
      default:
        return EthioColors.stone;
    }
  }
}
