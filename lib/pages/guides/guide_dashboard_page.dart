import 'package:flutter/material.dart';
import '../../models/guide.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/guide_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/notification_bell_button.dart';
import '../../widgets/chat_icon_button.dart';
import '../chat/conversations_list_page.dart';
import '../notifications_page.dart';
import '../profile_page.dart';
import '../login_page.dart';
import 'guide_profile_page.dart';
import 'guide_tours_page.dart';
import 'guide_availability_page.dart';
import 'guide_bookings_page.dart';

class GuideDashboardPage extends StatefulWidget {
  const GuideDashboardPage({super.key});

  @override
  State<GuideDashboardPage> createState() => _GuideDashboardPageState();
}

class _GuideDashboardPageState extends State<GuideDashboardPage> {
  final AuthService _auth = AuthService();
  final GuideService _guides = GuideService();
  final FirestoreService _fs = FirestoreService();

  Guide? _guide;
  UserProfile? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    final profile = await _fs.getUserProfileModel(user.uid);
    final guide = await _guides.getGuideByUserId(user.uid);
    if (!mounted) return;
    setState(() {
      _user = profile;
      _guide = guide;
      _loading = false;
    });
  }

  Future<void> _openProfileEditor() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GuideProfilePage(existing: _guide, user: _user),
      ),
    );
    if (saved == true) _load();
  }

  Widget _tile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppScaffold(
        title: 'Tour Guide Dashboard',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_guide == null) {
      return AppScaffold(
        title: 'Tour Guide Dashboard',
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hiking, size: 64, color: Colors.green.shade400),
                const SizedBox(height: 16),
                const Text(
                  'Create your professional guide profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add your bio, languages, qualifications, experience, and pricing so tourists can find and book you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Create Guide Profile'),
                  onPressed: _openProfileEditor,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final g = _guide!;
    return AppScaffold(
      title: 'Tour Guide Dashboard',
      actions: const [ChatIconButton(), NotificationBellButton()],
      body: ListView(
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.green.shade700,
                    child: Text(
                      g.name.isNotEmpty ? g.name[0].toUpperCase() : 'G',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${g.experienceYears} yrs • ${g.languagesLabel}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        const SizedBox(height: 4),
                        Text(g.formattedPrice, style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<int>(
            stream: _guides.getPendingBookingCountStream(g.id),
            builder: (context, snap) {
              final pending = snap.data ?? 0;
              if (pending == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  child: ListTile(
                    leading: Icon(Icons.mark_email_unread, color: Colors.amber.shade900),
                    title: Text('$pending new booking request${pending == 1 ? '' : 's'}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GuideBookingsPage(guide: g, initialTab: 0),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.25,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              _tile(
                icon: Icons.badge,
                label: 'My Profile',
                color: Colors.green.shade800,
                onTap: _openProfileEditor,
              ),
              _tile(
                icon: Icons.tour,
                label: 'My Tours',
                color: Colors.teal.shade700,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => GuideToursPage(guide: g)),
                ),
              ),
              _tile(
                icon: Icons.event_available,
                label: 'Availability',
                color: Colors.blue.shade700,
                onTap: () async {
                  final updated = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => GuideAvailabilityPage(guide: g)),
                  );
                  if (updated == true) _load();
                },
              ),
              _tile(
                icon: Icons.calendar_month,
                label: 'Schedule',
                color: Colors.indigo.shade700,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GuideBookingsPage(guide: g, initialTab: 2),
                  ),
                ),
              ),
              _tile(
                icon: Icons.inbox,
                label: 'Booking Requests',
                color: Colors.orange.shade800,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GuideBookingsPage(guide: g, initialTab: 0),
                  ),
                ),
              ),
              _tile(
                icon: Icons.book_online,
                label: 'My Bookings',
                color: Colors.deepPurple.shade600,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GuideBookingsPage(guide: g, initialTab: 1),
                  ),
                ),
              ),
              _tile(
                icon: Icons.chat,
                label: 'Messages',
                color: Colors.teal.shade800,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ConversationsListPage()),
                ),
              ),
              _tile(
                icon: Icons.notifications,
                label: 'Notifications',
                color: Colors.amber.shade800,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                ),
              ),
              _tile(
                icon: Icons.settings,
                label: 'Settings',
                color: Colors.grey.shade700,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                ),
              ),
              _tile(
                icon: Icons.logout,
                label: 'Logout',
                color: Colors.red.shade700,
                onTap: () async {
                  await _auth.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
