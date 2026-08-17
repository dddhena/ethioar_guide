import 'package:flutter/material.dart';
import '../../models/guide.dart';
import '../../services/guide_service.dart';
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
  List<Guide> _guides = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _service.fetchActiveGuides();
    if (!mounted) return;
    setState(() {
      _guides = list;
      _loading = false;
    });
  }

  List<Guide> get _filtered {
    if (_query.trim().isEmpty) return _guides;
    final q = _query.toLowerCase();
    return _guides.where((g) {
      return g.name.toLowerCase().contains(q) ||
          g.bio.toLowerCase().contains(q) ||
          g.languagesLabel.toLowerCase().contains(q) ||
          g.qualificationsLabel.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
            decoration: const InputDecoration(
              hintText: 'Search by name, language, or specialty',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Center(child: Text('No tour guides found yet.')),
                            ],
                          )
                        : ListView.builder(
                            itemCount: _filtered.length,
                            itemBuilder: (context, i) {
                              final g = _filtered[i];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green.shade700,
                                    child: Text(
                                      g.name.isNotEmpty ? g.name[0].toUpperCase() : 'G',
                                      style: const TextStyle(color: Colors.white),
                                    ),
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
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
