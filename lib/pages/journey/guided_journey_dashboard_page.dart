import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/journey_preference_service.dart';
import '../../theme/ethio_theme.dart';
import '../../widgets/chat_icon_button.dart';
import '../../widgets/emergency_sos_button.dart';
import '../../widgets/journey/dashboard_widgets.dart';
import '../../widgets/journey/recommended_places_section.dart';
import '../../widgets/notification_bell_button.dart';
import '../ai_guide_page.dart';
import '../camera_preview.dart';
import '../chat/conversations_list_page.dart';
import '../dashboard_page.dart';
import '../emergency/emergency_sos_dialog.dart';
import '../explore_page.dart';
import '../favorites_page.dart';
import '../guides/guides_list_page.dart';
import '../guides/my_guide_bookings_page.dart';
import '../landmarks_page.dart';
import '../login_page.dart';
import '../nearby_landmarks_page.dart';
import '../profile_page.dart';
import '../providers/my_reservations_page.dart';
import '../providers/service_providers_list_page.dart';
import '../trips_page.dart';
import 'ar_discovery_dashboard_page.dart';
import 'choose_journey_page.dart';
import 'guided_tours_browse_page.dart';

class GuidedJourneyDashboardPage extends StatefulWidget {
  const GuidedJourneyDashboardPage({super.key});

  @override
  State<GuidedJourneyDashboardPage> createState() => _GuidedJourneyDashboardPageState();
}

class _GuidedJourneyDashboardPageState extends State<GuidedJourneyDashboardPage> {
  final _auth = AuthService();
  final _fs = FirestoreService();
  UserProfile _profile = UserProfile(uid: '', name: 'Guest', email: '', role: 'tourist');
  bool _loading = true;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _loading = false;
      });
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

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _firstName {
    final parts = _profile.name.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : 'Traveler';
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _switchToAr() {
    JourneyPreferenceService.instance.setMode(JourneyMode.ar);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ArDiscoveryDashboardPage()),
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

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        setState(() => _navIndex = 0);
      case 1:
        _push(const ExplorePage());
      case 2:
        _push(const TripsPage());
      case 3:
        _push(const AiGuidePage());
      case 4:
        _push(const ProfilePage());
    }
  }

  Widget _buildHomeTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          '$_greeting, $_firstName',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Where will your journey take you?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        PremiumSearchBar(
          hint: 'Search attractions, tours...',
          onTap: () => _push(const GuidesListPage()),
        ),
        const SizedBox(height: 28),
        const DashboardSectionHeader(title: 'YOUR GUIDED EXPERIENCE'),
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
                    icon: Icons.people_outline,
                    title: 'Tour Guides',
                    subtitle: 'Find your guide',
                    accent: EthioColors.forest,
                    onTap: () => _push(const GuidesListPage()),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: DashboardFeatureCard(
                    icon: Icons.tour,
                    title: 'Guided Tours',
                    subtitle: 'Explore tours',
                    accent: EthioColors.terracotta,
                    onTap: () => _push(const GuidedToursBrowsePage()),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: DashboardFeatureCard(
                    icon: Icons.calendar_month,
                    title: 'My Bookings',
                    subtitle: 'Your tour plans',
                    accent: EthioColors.stone,
                    onTap: () => _push(const MyGuideBookingsPage()),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: DashboardFeatureCard(
                    icon: Icons.chat_bubble_outline,
                    title: 'Messages',
                    subtitle: 'Talk to guide',
                    accent: EthioColors.slate,
                    onTap: () => _push(const ConversationsListPage()),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        const RecommendedPlacesSection(title: 'RECOMMENDED PLACES'),
        const SizedBox(height: 18),
        const EmergencyQuickCard(),
        const SizedBox(height: 16),
        SwitchJourneyButton(label: 'Switch to AR Discovery', onTap: _switchToAr),
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
        title: const Text('Guided Journey'),
        actions: [
          const EmergencySosButton(),
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
        indicatorColor: EthioColors.forest.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Trips'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'AI Guide'),
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
                  colors: [EthioColors.forest, EthioColors.forestLight],
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
                        color: EthioColors.forest,
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
              leading: const Icon(Icons.emergency_rounded, color: Colors.red),
              title: const Text(
                '🚨 Emergency SOS Help',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                EmergencySosDialog.show(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Classic Dashboard'),
              onTap: () {
                Navigator.pop(context);
                _push(const DashboardPage());
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: const Text('My Reservations'),
              onTap: () {
                Navigator.pop(context);
                _push(const MyReservationsPage());
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
