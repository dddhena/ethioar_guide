import 'package:flutter/material.dart';
import '../../models/guide.dart';
import '../../models/guide_profile.dart';
import '../../models/booking.dart';
import '../../models/tour_package.dart';
import '../../services/auth_service.dart';
import '../../services/guide_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/notification_bell_button.dart';
import '../chat/conversations_list_page.dart';
import 'guide_profile_creation_page.dart';

class GuideDashboardPage extends StatefulWidget {
  const GuideDashboardPage({super.key});

  @override
  State<GuideDashboardPage> createState() => _GuideDashboardPageState();
}

class _GuideDashboardPageState extends State<GuideDashboardPage> {
  final AuthService _auth = AuthService();
  final GuideService _guideService = GuideService();
  final ThemeService _themeService = ThemeService();

  Guide? _guide;
  GuideProfile? _guideProfile;
  bool _loading = true;
  String _selectedPeriod = 'This Month';
  int _selectedTabIndex = 0;
  
  Map<String, dynamic> _dashboardStats = {
    'todayTours': 0,
    'todayTourists': 0,
    'todayDuration': '0h 0m',
    'todayEarnings': 0.0,
    'upcomingTours': <Booking>[],
    'tourMap': <String, TourPackage>{},
    'totalTours': 0,
    'totalTourists': 0,
    'avgRating': 0.0,
    'reviewCount': 0,
    'totalEarnings': 0.0,
    'unreadMessagesCount': 0,
    'monthlyData': <int>[],
  };

  @override
  void initState() {
    super.initState();
    _checkProfileCompletion();
  }

  Future<void> _checkProfileCompletion() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    final hasCompletedProfile = await _guideService.hasCompletedGuideProfile(user.uid);
    
    if (!hasCompletedProfile && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GuideProfileCreationPage()),
      );
      return;
    }

    _loadGuideProfile();
  }

  Future<void> _loadGuideProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    // Load both old Guide model and new GuideProfile
    final g = await _guideService.getGuideByUserId(user.uid);
    final profile = await _guideService.getGuideProfile(user.uid);
    
    if (mounted) {
      setState(() {
        _guide = g;
        _guideProfile = profile;
        _loading = false;
      });
      // Load dashboard stats
      if (g != null) {
        _guideService.getGuideDashboardStatsStream(g.id).listen((stats) {
          if (mounted) {
            setState(() {
              _dashboardStats = stats;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Guide Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_guide == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Guide Dashboard')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No Guide Profile Yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please register as a tour guide to access this dashboard.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tour Guide Portal'),
        actions: [
          ListenableBuilder(
            listenable: _themeService,
            builder: (context, child) {
              return IconButton(
                icon: Icon(_themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                tooltip: _themeService.isDarkMode ? 'Light Mode' : 'Dark Mode',
                onPressed: () => _themeService.toggleTheme(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await _auth.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
          const NotificationBellButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            _buildProfileHeader(),
            const SizedBox(height: 20),

            // Today's Overview
            _buildTodayOverview(),
            const SizedBox(height: 24),

            // Upcoming Tours
            _buildUpcomingTours(),
            const SizedBox(height: 24),

            // Quick Access
            _buildQuickAccess(),
            const SizedBox(height: 24),

            // Performance Graph
            _buildPerformanceGraph(),
            const SizedBox(height: 80), // Space for bottom nav
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                _guide!.name.isNotEmpty 
                    ? _guide!.name.split(' ').map((n) => n[0]).take(2).join().toUpperCase()
                    : 'TG',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _guide!.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _guide!.email,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade300),
                    ),
                    child: const Text(
                      'Tour Guide',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _guide!.rating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Overview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.hiking,
                title: "Today's Tours",
                value: (_dashboardStats['todayTours'] ?? 0).toString(),
                subtitle: 'Scheduled tours',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.people,
                title: "Today's Tourists",
                value: (_dashboardStats['todayTourists'] ?? 0).toString(),
                subtitle: 'Total tourists',
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.access_time,
                title: 'Total Duration',
                value: _dashboardStats['todayDuration'] ?? '0h 0m',
                subtitle: 'Tour time',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.attach_money,
                title: "Today's Earnings",
                value: '${(_dashboardStats['todayEarnings'] ?? 0.0).toStringAsFixed(0)} ETB',
                subtitle: 'Revenue',
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingTours() {
    final upcomingTours = _dashboardStats['upcomingTours'] as List<Booking>? ?? [];
    final tourMap = _dashboardStats['tourMap'] as Map<String, TourPackage>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Tours',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (upcomingTours.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text('No upcoming tours', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Your scheduled tours will appear here', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
          )
        else
          ...upcomingTours.take(3).map((booking) {
            final tour = tourMap[booking.tourId];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.tour, color: Colors.blue.shade700, size: 30),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tour?.name ?? booking.tourName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${booking.formattedTourDate} • ${booking.formattedTourTime}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: booking.isConfirmed 
                                      ? Colors.green.shade50 
                                      : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: booking.isConfirmed 
                                        ? Colors.green.shade300 
                                        : Colors.orange.shade300,
                                  ),
                                ),
                                child: Text(
                                  booking.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: booking.isConfirmed 
                                        ? Colors.green.shade800 
                                        : Colors.orange.shade800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${booking.numberOfParticipants} Tourists',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildQuickAccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Access',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildQuickAccessCard(
              icon: Icons.map,
              title: 'My Tours',
              subtitle: 'Manage your scheduled tours',
              onTap: () {},
            ),
            _buildQuickAccessCard(
              icon: Icons.people,
              title: 'Tourists',
              subtitle: 'View booked tourists',
              onTap: () {},
            ),
            _buildQuickAccessCard(
              icon: Icons.chat,
              title: 'Messages',
              subtitle: 'Chat with tourists',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ConversationsListPage()),
                );
              },
            ),
            _buildQuickAccessCard(
              icon: Icons.payments,
              title: 'Earnings',
              subtitle: 'Track your earnings',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.blue.shade700, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceGraph() {
    final monthlyData = _dashboardStats['monthlyData'] as List<int>?;
    final maxValue = (monthlyData?.isEmpty ?? true) ? 10 : monthlyData!.reduce((a, b) => a > b ? a : b);
    final graphData = (monthlyData?.isEmpty ?? true) 
        ? [0, 0, 0, 0, 0, 0] 
        : monthlyData!;

    final months = _getMonthLabels();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Performance Graph',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _selectedPeriod,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'This Week', child: Text('This Week')),
                DropdownMenuItem(value: 'This Month', child: Text('This Month')),
                DropdownMenuItem(value: 'This Year', child: Text('This Year')),
                DropdownMenuItem(value: 'All Time', child: Text('All Time')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value ?? 'This Month';
                });
              },
              style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
              dropdownColor: Colors.white,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      graphData.length,
                      (index) {
                        final value = graphData[index];
                        final barHeight = maxValue > 0 
                            ? (value / maxValue) * 160 
                            : 0.0;
                        
                        return Column(
                          children: [
                            Container(
                              width: 40,
                              height: barHeight.clamp(0.0, 160.0),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              months[index],
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              value.toString(),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem(Colors.blue, 'Tours'),
                    _buildLegendItem(Colors.green, 'Tourists'),
                    _buildLegendItem(Colors.orange, 'Earnings'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<String> _getMonthLabels() {
    final now = DateTime.now();
    final months = <String>[];
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthName = _getMonthName(monthDate.month);
      months.add(monthName);
    }
    return months;
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return monthNames[month - 1];
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }


  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.dashboard,
                label: 'Dashboard',
                isSelected: _selectedTabIndex == 0,
                onTap: () {
                  setState(() {
                    _selectedTabIndex = 0;
                  });
                },
              ),
              _buildNavItem(
                icon: Icons.map,
                label: 'My Tours',
                isSelected: _selectedTabIndex == 1,
                onTap: () {
                  setState(() {
                    _selectedTabIndex = 1;
                  });
                },
              ),
              _buildNavItem(
                icon: Icons.chat,
                label: 'Messages',
                isSelected: _selectedTabIndex == 2,
                onTap: () {
                  setState(() {
                    _selectedTabIndex = 2;
                  });
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ConversationsListPage()),
                  );
                },
              ),
              _buildNavItem(
                icon: Icons.person,
                label: 'Profile',
                isSelected: _selectedTabIndex == 3,
                onTap: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GuideProfileCreationPage(
                        existingProfile: _guideProfile,
                      ),
                    ),
                  );
                  if (result == true && mounted) {
                    _loadGuideProfile();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blue : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? Colors.blue : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceRow({
    required String label,
    required String value,
    required String percentage,
    required bool isPositive,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  percentage,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}