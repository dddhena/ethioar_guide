import 'package:flutter/material.dart';
import '../../models/guide.dart';
import '../../models/guide_profile.dart';
import '../../services/guide_service.dart';
import '../../theme/ethio_theme.dart';
import '../../widgets/app_scaffold.dart';
import 'guide_details_page.dart';
import 'my_guide_bookings_page.dart';

class GuidesListPage extends StatefulWidget {
  const GuidesListPage({super.key});

  @override
  State<GuidesListPage> createState() => _GuidesListPageState();
}

class _GuidesListPageState extends State<GuidesListPage> {
  final GuideService _service = GuideService();
  String _query = '';
  bool _loading = true;
  List<GuideProfile> _profiles = [];
  List<Guide> _legacyGuides = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final profiles = await _service.fetchCompletedGuideProfiles();
    List<Guide> legacy = [];
    if (profiles.isEmpty) {
      legacy = await _service.fetchActiveGuides();
    }
    if (!mounted) return;
    setState(() {
      _profiles = profiles;
      _legacyGuides = legacy;
      _loading = false;
    });
  }

  List<GuideProfile> get _filteredProfiles {
    if (_query.trim().isEmpty) return _profiles;
    final q = _query.toLowerCase();
    return _profiles.where((p) {
      return p.publicName.toLowerCase().contains(q) ||
          p.bio.toLowerCase().contains(q) ||
          p.city.toLowerCase().contains(q) ||
          p.languagesLabel.toLowerCase().contains(q) ||
          p.specialtiesLabel.toLowerCase().contains(q) ||
          p.services.any((s) => s.toLowerCase().contains(q));
    }).toList();
  }

  List<Guide> get _filteredLegacy {
    if (_query.trim().isEmpty) return _legacyGuides;
    final q = _query.toLowerCase();
    return _legacyGuides.where((g) {
      return g.name.toLowerCase().contains(q) ||
          g.bio.toLowerCase().contains(q) ||
          g.languagesLabel.toLowerCase().contains(q) ||
          g.qualificationsLabel.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final usingProfiles = _profiles.isNotEmpty;

    return AppScaffold(
      title: 'Tour Guides',
      actions: [
        IconButton(
          icon: const Icon(Icons.book_online),
          tooltip: 'My guide bookings',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MyGuideBookingsPage()),
          ),
        ),
      ],
      body: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by name, language, or specialty',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: EthioColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: EthioColors.divider),
              ),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: usingProfiles
                        ? _buildProfileList()
                        : _buildLegacyList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileList() {
    final items = _filteredProfiles;
    if (items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Center(child: Text('No tour guides found yet.')),
        ],
      );
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final p = items[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: EthioColors.forest.withValues(alpha: 0.12),
                      backgroundImage: p.profileImageUrl != null
                          ? NetworkImage(p.profileImageUrl!)
                          : null,
                      child: p.hasPhoto
                          ? null
                          : Text(
                              p.publicName.isNotEmpty
                                  ? p.publicName[0].toUpperCase()
                                  : 'G',
                              style: const TextStyle(
                                color: EthioColors.forest,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.publicName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 16, color: EthioColors.adminGold),
                              const SizedBox(width: 2),
                              Text(
                                p.ratingLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: EthioColors.adminGold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.location_on,
                                  size: 14, color: Colors.grey.shade600),
                              Flexible(
                                child: Text(
                                  p.city.isEmpty ? 'Ethiopia' : p.city,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${p.experienceLabel} · ${p.languagesLabel}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                if (p.specialties.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    p.specialties.take(3).join(' • '),
                    style: const TextStyle(
                      fontSize: 13,
                      color: EthioColors.forest,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  p.pricingFormatted,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GuideDetailsPage(profile: p),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EthioColors.forest,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('View Profile'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegacyList() {
    final items = _filteredLegacy;
    if (items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Center(child: Text('No tour guides found yet.')),
        ],
      );
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final g = items[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: EthioColors.forest,
              backgroundImage: g.profileImageUrl.isNotEmpty
                  ? NetworkImage(g.profileImageUrl)
                  : null,
              child: g.profileImageUrl.isEmpty
                  ? Text(
                      g.name.isNotEmpty ? g.name[0].toUpperCase() : 'G',
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
            title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${g.experienceYears} yrs • ${g.languagesLabel}\n${g.formattedPrice}',
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => GuideDetailsPage(guide: g)),
            ),
          ),
        );
      },
    );
  }
}
