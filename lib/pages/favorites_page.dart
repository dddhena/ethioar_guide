import 'package:flutter/material.dart';
import '../models/landmark.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/interaction_service.dart';
import '../theme/ethio_theme.dart';
import '../widgets/notification_bell_button.dart';
import '../widgets/place_image.dart';
import 'landmark_detail_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final _auth = AuthService();
  final _fs = FirestoreService();
  final _interaction = InteractionService();
  List<Landmark> _favorites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    final ids = await _interaction.getFavoritedAttractions(uid);
    final all = await _fs.fetchLandmarks();
    _favorites = all.where((l) => ids.contains(l.id)).toList();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EthioColors.cream,
      appBar: AppBar(
        title: const Text('Favorites ❤️'),
        actions: const [NotificationBellButton(color: EthioColors.charcoal)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _favorites.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Icon(Icons.favorite_border, size: 64, color: EthioColors.muted),
                        SizedBox(height: 16),
                        Center(child: Text('No saved places yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
                        SizedBox(height: 8),
                        Center(child: Text('Tap the heart on any place to save it here', style: TextStyle(color: EthioColors.muted))),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _favorites.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final lm = _favorites[i];
                        return _FavoriteCard(
                          landmark: lm,
                          onTap: () async {
                            await trackLandmarkView(lm);
                            if (!context.mounted) return;
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => LandmarkDetailPage(landmark: lm)),
                            );
                            _load();
                          },
                        );
                      },
                    ),
            ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final Landmark landmark;
  final VoidCallback onTap;

  const _FavoriteCard({required this.landmark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            SizedBox(width: 100, child: PlaceImage(landmark: landmark, height: 90, borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(landmark.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(landmark.city.isNotEmpty ? landmark.city : landmark.category, style: const TextStyle(color: EthioColors.muted, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(landmark.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.chevron_right, color: EthioColors.muted)),
          ],
        ),
      ),
    );
  }
}
