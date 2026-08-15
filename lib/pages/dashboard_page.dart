import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_scaffold.dart';
import 'camera_preview.dart';
import 'landmarks_page.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'nearby_landmarks_page.dart';
import 'providers/service_providers_list_page.dart';
import 'providers/my_reservations_page.dart';
import 'providers/provider_dashboard_page.dart';
import 'providers/admin_providers_page.dart';
import 'admin_pages.dart';
import 'providers/service_providers_list_page.dart';
import 'providers/my_reservations_page.dart';
import 'providers/provider_dashboard_page.dart';
import 'providers/admin_providers_page.dart';
import 'admin_pages.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthService _auth = AuthService();
  final FirestoreService _fs = FirestoreService();
  UserProfile _profile = UserProfile(uid: '', name: 'Guest', email: '', role: 'tourist');
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _profile = UserProfile(uid: '', name: 'Guest', email: '', role: 'tourist');
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

  Future<void> _navigateToProfile() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
    if (mounted) _loadProfile();
  }

  // ── Badge helpers ──────────────────────────────────────────────────────────
  String get _roleBadgeLabel {
    if (_profile.isAdmin)     return '👑 Admin';
    if (_profile.isProvider)  return '🏢 Service Provider';
    if (_profile.isTourGuide) return '🗺️ Tour Guide';
    return '🧭 Tourist';
  }

  Color get _roleBadgeColor {
    if (_profile.isAdmin)     return Colors.amber.shade800;
    if (_profile.isProvider)  return Colors.blue.shade700;
    if (_profile.isTourGuide) return Colors.green.shade700;
    return Colors.teal.shade700;
  }

  // ── Reusable button builders ───────────────────────────────────────────────
  Widget _sectionHeader(String title, {Color? color}) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color ?? Colors.teal.shade900,
              ),
        ),
      );

  Widget _primaryBtn({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: color ?? Colors.teal.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: Icon(icon),
          label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          onPressed: onPressed,
        ),
      );

  Widget _outlineBtn({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            foregroundColor: Colors.teal.shade800,
            side: BorderSide(color: Colors.teal.shade400),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: Icon(icon),
          label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          onPressed: onPressed,
        ),
      );

  // ── Role-gated content sections ────────────────────────────────────────────

  /// 🧭 Tourist: AR guide, nearby, hotels/dining/transport, reservations, catalog
  List<Widget> get _touristSection => [
        _sectionHeader('Explore & Experience Ethiopia'),
        _primaryBtn(
          icon: Icons.explore,
          label: 'AR Tourist Guide',
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const CameraPreviewPage())),
        ),
        _primaryBtn(
          icon: Icons.near_me,
          label: '📍 Nearby Landmarks',
          color: Colors.teal.shade800,
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const NearbyLandmarksPage())),
        ),
        _primaryBtn(
          icon: Icons.hotel,
          label: '🏨 Hotels, Dining & Transport',
          color: Colors.blue.shade800,
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const ServiceProvidersListPage())),
        ),
        _outlineBtn(
          icon: Icons.bookmark_border,
          label: '📅 My Reservations',
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const MyReservationsPage())),
        ),
        _outlineBtn(
          icon: Icons.list,
          label: 'View Landmarks Catalog',
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const LandmarksPage())),
        ),
      ];

  /// 🗺️ Tour Guide: AR guide, nearby landmarks, landmarks catalog
  List<Widget> get _tourGuideSection => [
        _sectionHeader('Tour Guide Toolkit'),
        _primaryBtn(
          icon: Icons.explore,
          label: 'AR Tourist Guide',
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const CameraPreviewPage())),
        ),
        _primaryBtn(
          icon: Icons.near_me,
          label: '📍 Nearby Landmarks',
          color: Colors.teal.shade800,
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const NearbyLandmarksPage())),
        ),
        _outlineBtn(
          icon: Icons.list,
          label: 'View Landmarks Catalog',
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const LandmarksPage())),
        ),
      ];

  /// 🏢 Service Provider: business dashboard only
  List<Widget> get _providerSection => [
        _sectionHeader('Service Provider Portal'),
        _primaryBtn(
          icon: Icons.store_mall_directory,
          label: '🏢 My Business Dashboard',
          color: Colors.blue.shade800,
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const ProviderDashboardPage())),
        ),
      ];

  /// 👑 Admin: user management, verify providers, add landmarks
  List<Widget> get _adminSection => [
        _sectionHeader('Administration', color: Colors.amber.shade900),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.amber.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.admin_panel_settings),
            label: const Text('Manage Users & Roles',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminPage())),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.amber.shade900,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.verified),
            label: const Text('Verify Service Providers',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AdminProvidersPage())),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.teal.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.location_on),
            label: const Text('Add / Manage Landmarks',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AddLandmarkPage())),
          ),
        ),
      ];

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Dashboard',
      actions: [
        IconButton(
          icon: const Icon(Icons.account_circle),
          tooltip: 'My Profile',
          onPressed: _navigateToProfile,
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Sign Out',
          onPressed: () async {
            await _auth.signOut();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            }
          },
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // ── Profile card ──────────────────────────────────────────
                InkWell(
                  onTap: _navigateToProfile,
                  borderRadius: BorderRadius.circular(16),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: _roleBadgeColor,
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.white,
                              child: Text(
                                _profile.initials,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _roleBadgeColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _profile.name.isNotEmpty ? _profile.name : 'Welcome!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                if (_profile.email.isNotEmpty)
                                  Text(
                                    _profile.email,
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                  ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _roleBadgeColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: _roleBadgeColor.withValues(alpha: 0.5)),
                                      ),
                                      child: Text(
                                        _roleBadgeLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _roleBadgeColor,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Manage Profile →',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.teal.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Role-gated feature sections ───────────────────────────
                if (_profile.isAdmin)
                  ..._adminSection
                else if (_profile.isProvider)
                  ..._providerSection
                else if (_profile.isTourGuide)
                  ..._tourGuideSection
                else
                  ..._touristSection,
              ],
            ),
    );
  }
}
