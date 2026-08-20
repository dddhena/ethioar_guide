import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/interaction_service.dart';
import '../theme/ethio_theme.dart';

class FavoriteButton extends StatefulWidget {
  final String attractionId;
  final bool compact;

  const FavoriteButton({
    super.key,
    required this.attractionId,
    this.compact = false,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  final _interaction = InteractionService();
  final _auth = AuthService();
  bool _favorited = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    final fav = await _interaction.isFavorited(uid, widget.attractionId);
    if (mounted) setState(() { _favorited = fav; _loading = false; });
  }

  Future<void> _toggle() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save favorites')),
      );
      return;
    }
    setState(() => _loading = true);
    final nowFav = await _interaction.toggleFavorite(uid, widget.attractionId);
    if (mounted) {
      setState(() { _favorited = nowFav; _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(nowFav ? 'Added to favorites ❤️' : 'Removed from favorites')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return IconButton(
        onPressed: _loading ? null : _toggle,
        icon: _loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(_favorited ? Icons.favorite : Icons.favorite_border, color: _favorited ? Colors.red : null),
      );
    }
    return OutlinedButton.icon(
      onPressed: _loading ? null : _toggle,
      icon: Icon(_favorited ? Icons.favorite : Icons.favorite_border, color: _favorited ? Colors.red : EthioColors.forest),
      label: Text(_favorited ? 'Saved' : 'Save'),
      style: OutlinedButton.styleFrom(
        foregroundColor: EthioColors.forest,
        side: BorderSide(color: _favorited ? Colors.red.shade300 : EthioColors.divider),
      ),
    );
  }
}
