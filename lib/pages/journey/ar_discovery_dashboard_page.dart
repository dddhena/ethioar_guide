import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/journey_preference_service.dart';
import '../../theme/ethio_theme.dart';
import '../../widgets/chat_icon_button.dart';
import '../../widgets/journey/dashboard_widgets.dart';
import '../../widgets/notification_bell_button.dart';
import '../ar_guide.dart';
import '../camera_preview.dart';
import '../dashboard_page.dart';
import '../landmarks_page.dart';
import '../login_page.dart';
import '../nearby_landmarks_page.dart';
import '../profile_page.dart';
import '../providers/my_reservations_page.dart';
import '../providers/service_providers_list_page.dart';
import 'choose_journey_page.dart';
import 'guided_journey_dashboard_page.dart';

class ArDiscoveryDashboardPage extends StatefulWidget {
  const ArDiscoveryDashboardPage({super.key});

  @override
  State<ArDiscoveryDashboardPage> createState() => _ArDiscoveryDashboardPageState();
}

class _ArDiscoveryDashboardPageState extends State<ArDiscoveryDashboardPage> {
  final _auth = AuthService();
  final _fs = FirestoreService();
  UserProfile _profile = UserProfile(uid: '', name: 'Guest', email: '', role: 'tourist');
  bool _loading = true;
  int _navIndex = 0;

  static const _heroImage =
      'https://images.unsplash.com/photo-1609137144813-7d8bfe2a0e44?auto=format&fit=crop&w=900&q=80';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final profile = await _fs.getUserProfileModel(uid);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profile = UserProfile(
          uid: uid,
          name: _auth.currentUser?.displayName ?? 'Guest',
          email: _auth.currentUser?.email ?? '',
          role: 'tourist',
        );
        _loading = false;
      });
    }
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _switchToGuided() {
    JourneyPreferenceService.instance.setMode(JourneyMode.guided);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GuidedJourneyDashboardPage()),
    );
  }

  void _openChooseJourney() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChooseJourneyPage()),
    );
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    JourneyPreferenceService.instance.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  List<ExploreMoreItem> get _exploreMore => [
        ExploreMoreItem(icon: Icons.account_balance, label: 'Places', onTap: () => _push(const LandmarksPage())),
        ExploreMoreItem(icon: Icons.map_outlined, label: 'Map', onTap: () => _push(const NearbyLandmarksPage())),
        ExploreMoreItem(
          icon: Icons.cloud_outlined,
          label: 'Weather',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Weather forecast coming soon')),
          ),
        ),
        ExploreMoreItem(
          icon: Icons.hotel_outlined,
          label: 'Hotels',
          onTap: () => _push(const ServiceProvidersListPage()),
        ),
        ExploreMoreItem(
          icon: Icons.restaurant_outlined,
          label: 'Dining',
          onTap: () => _push(const ServiceProvidersListPage()),
        ),
        ExploreMoreItem(
          icon: Icons.directions_car_outlined,
          label: 'Transport',
          onTap: () => _push(const ServiceProvidersListPage()),
        ),
        ExploreMoreItem(
          icon: Icons.luggage_outlined,
          label: 'Trips',
          onTap: () => _push(const MyReservationsPage()),
        ),
        ExploreMoreItem(
          icon: Icons.auto_awesome,
          label: 'AI Guide',
          onTap: () => _push(const CameraPreviewPage()),
        ),
      ];

  Widget _buildHeroCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _push(const CameraPreviewPage()),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: ethioGlassCard(tint: EthioColors.slate, radius: 22),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Column(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        _heroImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                EthioColors.slate.withValues(alpha: 0.3),
                                EthioColors.sand,
                              ],
                            ),
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.45),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                          ),
                          child: const Icon(Icons.view_in_ar, color: Colors.white, size: 36),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                  child: Column(
                    children: [
                      Text(
                        'START AR EXPERIENCE',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: EthioColors.slate,
                              letterSpacing: 1.2,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Discover stories around you',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _push(const CameraPreviewPage()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EthioColors.slate,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Open Camera'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        setState(() => _navIndex = 0);
      case 1:
        _push(const CameraPreviewPage());
      case 2:
        _push(const NearbyLandmarksPage());
      case 3:
        _push(const MyReservationsPage());
      case 4:
        _push(const ProfilePage());
    }
  }

  Widget _buildHomeTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          'Discover Ethiopia differently',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Point. Explore. Discover.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: EthioColors.slate,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 22),
        _buildHeroCard(),
        const SizedBox(height: 28),
        const DashboardSectionHeader(title: 'DISCOVER'),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: DashboardFeatureCard(
                    icon: Icons.location_on_outlined,
                    title: 'Nearby AR',
                    subtitle: 'Discover nearby',
                    accent: EthioColors.slate,
                    onTap: () => _push(const NearbyLandmarksPage()),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: DashboardFeatureCard(
                    icon: Icons.document_scanner_outlined,
                    title: 'Scan Marker',
                    subtitle: 'Scan & reveal',
                    accent: EthioColors.terracotta,
                    onTap: () => _push(const CameraPreviewPage()),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: DashboardFeatureCard(
                    icon: Icons.auto_awesome,
                    title: 'AR Experiences',
                    subtitle: 'Explore history',
                    accent: EthioColors.forest,
                    onTap: () => _push(const LandmarksPage()),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: DashboardFeatureCard(
                    icon: Icons.navigation_outlined,
                    title: 'AR Navigation',
                    subtitle: 'Find your way',
                    accent: EthioColors.stone,
                    onTap: () => _push(const ARGuidePage()),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        ExploreMoreSection(items: _exploreMore),
        const SizedBox(height: 20),
        SwitchJourneyButton(label: 'Switch to Guided Journey', onTap: _switchToGuided),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _openChooseJourney,
            child: const Text('Change journey preference'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EthioColors.cream,
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: const Text('AR Discovery'),
        actions: [
          const ChatIconButton(color: EthioColors.charcoal),
          const NotificationBellButton(color: EthioColors.charcoal),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => _push(const ProfilePage()),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildHomeTab(),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: _onNavTap,
        backgroundColor: Colors.white,
        indicatorColor: EthioColors.slate.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.view_in_ar_outlined), selectedIcon: Icon(Icons.view_in_ar), label: 'AR'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.luggage_outlined), selectedIcon: Icon(Icons.luggage), label: 'Trips'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [EthioColors.slate, EthioColors.slate.withValues(alpha: 0.75)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Text(
                      _profile.initials,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: EthioColors.slate,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _profile.name.isNotEmpty ? _profile.name : 'Guest',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Classic Dashboard'),
              onTap: () {
                Navigator.pop(context);
                _push(const DashboardPage());
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: _signOut,
            ),
          ],
        ),
      ),
    );
  }
}
