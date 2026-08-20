import 'package:flutter/material.dart';
import '../models/landmark.dart';
import '../models/user_interaction.dart';
import '../services/auth_service.dart';
import '../services/interaction_service.dart';
import '../services/location_service.dart';
import '../theme/ethio_theme.dart';
import '../widgets/add_to_trip_sheet.dart';
import '../widgets/explore_categories.dart';
import '../widgets/favorite_button.dart';
import '../widgets/place_image.dart';

class LandmarkDetailPage extends StatelessWidget {
  final Landmark landmark;

  const LandmarkDetailPage({super.key, required this.landmark});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EthioColors.cream,
      appBar: AppBar(
        title: Text(landmark.name),
        actions: [
          FavoriteButton(attractionId: landmark.id, compact: true),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlaceImage(landmark: landmark, height: 220),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '${ExploreCategories.emojiForCategory(landmark.category)} ${landmark.category.capitalize()}',
                  style: TextStyle(color: EthioColors.muted, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text('${landmark.rating.toStringAsFixed(1)} (${landmark.reviewCount})'),
              ],
            ),
            if (landmark.city.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: EthioColors.muted),
                  const SizedBox(width: 4),
                  Text(landmark.city, style: const TextStyle(color: EthioColors.muted)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text(landmark.description, style: const TextStyle(fontSize: 16, height: 1.5)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: FavoriteButton(attractionId: landmark.id)),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => AddToTripSheet.show(context, landmark),
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('Add to Trip'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension _Capitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

/// Tracks a view interaction when opening landmark details.
Future<void> trackLandmarkView(Landmark landmark) async {
  final uid = AuthService().currentUser?.uid;
  if (uid == null) return;
  await InteractionService().trackInteraction(
    touristId: uid,
    attractionId: landmark.id,
    interactionType: UserInteraction.view,
  );
}

String formatLandmarkDistance(Landmark landmark, double userLat, double userLon) {
  final km = LocationService.calculateDistanceKm(userLat, userLon, landmark.latitude, landmark.longitude);
  if (km < 1) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(1)} km';
}
