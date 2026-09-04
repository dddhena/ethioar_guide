import 'package:flutter/material.dart';
import '../../theme/ethio_theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/emergency_service.dart';
import '../../services/payment_service.dart';
import '../../models/emergency_alert.dart';
import '../../models/payment.dart';
import 'admin_emergency_dashboard.dart';
import 'admin_payment_verification_page.dart';
import 'admin_system_config_page.dart';
import '../admin_pages.dart';
import '../providers/admin_providers_page.dart';
import '../chat/conversations_list_page.dart';
import '../landmarks_page.dart';
import '../login_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _auth = AuthService();
  final FirestoreService _fs = FirestoreService();
  final EmergencyService _emergencyService = EmergencyService();
  final PaymentService _paymentService = PaymentService();
  
  int _selectedIndex = 0;
  bool _sidebarExpanded = true;
  bool _loadingStats = true;
  
  // Statistics data - will be fetched from database
  int _totalUsers = 0;
  int _serviceProviders = 0;
  double _entrancePayments = 0;
  int _totalLandmarks = 0;
  Map<String, int> _userCounts = {};
  Map<String, int> _bookingStats = {'total': 0, 'pending': 0, 'confirmed': 0, 'completed': 0, 'cancelled': 0};
  List<Map<String, dynamic>> _recentBookings = [];
  
  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }
  
  Future<void> _loadStatistics() async {
    setState(() => _loadingStats = true);
    
    try {
      // Load user counts by role
      final userCounts = await _fs.getUserCountByRole();
      _userCounts = userCounts;
      _totalUsers = userCounts['total'] ?? 0;
      
      // Load provider count
      _serviceProviders = await _fs.getProviderCount();
      
      // Load landmark count
      _totalLandmarks = await _fs.getLandmarkCount();
      
      // Load total entrance payments
      _entrancePayments = await _fs.getTotalEntrancePayments();
      
      // Load booking statistics
      try {
        _bookingStats = await _fs.getBookingStatsByStatus();
      } catch (e) {
        print('Error loading booking stats: $e');
        _bookingStats = {'total': 0, 'pending': 0, 'confirmed': 0, 'completed': 0, 'cancelled': 0};
      }
      
      // Load recent bookings
      try {
        _recentBookings = await _fs.getRecentBookings(limit: 5);
      } catch (e) {
        print('Error loading recent bookings: $e');
        _recentBookings = [];
      }
      
      if (mounted) {
        setState(() => _loadingStats = false);
      }
    } catch (e) {
      print('Error loading statistics: $e');
      // Set default values on error
      _bookingStats = {'total': 0, 'pending': 0, 'confirmed': 0, 'completed': 0, 'cancelled': 0};
      _recentBookings = [];
      if (mounted) {
        setState(() => _loadingStats = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),
          // Main content
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: _sidebarExpanded ? 280 : 80,
      decoration: BoxDecoration(
        color: const Color(0xFF1B4D3E), // Dark green
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo section
          _buildSidebarHeader(),
          // Navigation items
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildNavItem(
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    index: 0,
                    isSelected: _selectedIndex == 0,
                  ),
                  const SizedBox(height: 8),
                  _buildSectionHeader('MANAGEMENT'),
                  _buildNavItem(
                    icon: Icons.people,
                    label: 'Users & Roles',
                    index: 1,
                  ),
                  _buildNavItem(
                    icon: Icons.business,
                    label: 'Service Providers',
                    index: 2,
                  ),
                  _buildNavItem(
                    icon: Icons.payment,
                    label: 'Entrance Payments',
                    index: 3,
                  ),
                  _buildNavItem(
                    icon: Icons.location_on,
                    label: 'Landmarks',
                    index: 4,
                  ),
                  _buildNavItem(
                    icon: Icons.book,
                    label: 'Bookings',
                    index: 5,
                  ),
                  const SizedBox(height: 8),
                  _buildSectionHeader('COMMUNICATION'),
                  _buildNavItem(
                    icon: Icons.support_agent,
                    label: 'Support Desk',
                    index: 6,
                  ),
                  _buildNavItem(
                    icon: Icons.message,
                    label: 'Messages',
                    index: 7,
                  ),
                  const SizedBox(height: 8),
                  _buildSectionHeader('SYSTEM'),
                  _buildNavItem(
                    icon: Icons.analytics,
                    label: 'Reports & Analytics',
                    index: 8,
                  ),
                  _buildNavItem(
                    icon: Icons.settings_suggest,
                    label: 'System Configuration',
                    index: 9,
                  ),
                  _buildNavItem(
                    icon: Icons.history,
                    label: 'Activity Logs',
                    index: 10,
                  ),
                ],
              ),
            ),
          ),
          // User profile section
          _buildUserProfile(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_sidebarExpanded) ...[
            const Text(
              'Ethiopia',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Smart Tourism',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ] else
            const Icon(
              Icons.map,
              color: Colors.white,
              size: 32,
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: _sidebarExpanded
          ? Text(
              title,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        _navigateToPage(index);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9CCC65) : Colors.transparent,
          border: isSelected
              ? const Border(left: BorderSide(color: Color(0xFF9CCC65), width: 4))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: 20,
            ),
            if (_sidebarExpanded) ...[
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    final user = _auth.currentUser;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: _sidebarExpanded
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'admin',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user?.email ?? 'admin@gmail.com',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: EthioColors.adminGold,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _logout,
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                IconButton(
                  icon: Icon(
                    Icons.logout,
                    color: Colors.white70,
                    size: 16,
                  ),
                  onPressed: _logout,
                  tooltip: 'Logout',
                ),
              ],
            ),
    );
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Widget _buildMainContent() {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Top navigation bar
          _buildTopNavBar(),
          // Page content
          Expanded(
            child: _buildPageContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              setState(() {
                _sidebarExpanded = !_sidebarExpanded;
              });
            },
          ),
          const SizedBox(width: 16),
          Text(
            _getPageTitle(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          // Search bar
          Container(
            width: 300,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.message_outlined),
            onPressed: () => _navigateToPage(7),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundColor: EthioColors.forest,
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0: return 'Dashboard';
      case 1: return 'Users & Roles';
      case 2: return 'Service Providers';
      case 3: return 'Entrance Payments';
      case 4: return 'Landmarks';
      case 5: return 'Bookings';
      case 6: return 'Support Desk';
      case 7: return 'Messages';
      case 8: return 'Reports & Analytics';
      case 9: return 'System Configuration';
      case 10: return 'Activity Logs';
      default: return 'Dashboard';
    }
  }

  Widget _buildPageContent() {
    switch (_selectedIndex) {
      case 0: return _buildDashboardContent();
      case 1: return _buildUsersPage();
      case 2: return _buildProvidersPage();
      case 3: return _buildPaymentsPage();
      case 4: return _buildLandmarksPage();
      case 5: return _buildBookingsPage();
      case 6: return _buildSupportDeskPage();
      case 7: return _buildMessagesPage();
      case 8: return _buildReportsPage();
      case 9: return _buildSettingsPage();
      case 10: return _buildActivityLogsPage();
      default: return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emergency SOS banner
          _buildEmergencyBanner(),
          const SizedBox(height: 24),
          
          // Summary cards
          _buildSummaryCards(),
          const SizedBox(height: 24),
          
          // Charts section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildPlatformOverviewChart(),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildBookingsStatusChart(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Alerts and quick actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildRecentAlerts(),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildQuickActions(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Recent bookings table
          _buildRecentBookingsTable(),
          const SizedBox(height: 24),
          
          // Recent activities
          _buildRecentActivities(),
        ],
      ),
    );
  }

  Widget _buildEmergencyBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade600, Colors.red.shade800],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emergency,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live Emergency SOS Monitor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  StreamBuilder<List<EmergencyAlert>>(
                    stream: _emergencyService.getEmergenciesStream(),
                    builder: (context, snapshot) {
                      final activeCount = snapshot.data?.where((e) => e.isActive).length ?? 0;
                      return Text(
                        'Active alerts: $activeCount',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => _navigateToEmergencyMonitor(),
            child: const Text('View Live Monitor'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_loadingStats) {
      return Row(
        children: [
          Expanded(child: _buildLoadingSummaryCard()),
          const SizedBox(width: 16),
          Expanded(child: _buildLoadingSummaryCard()),
          const SizedBox(width: 16),
          Expanded(child: _buildLoadingSummaryCard()),
          const SizedBox(width: 16),
          Expanded(child: _buildLoadingSummaryCard()),
        ],
      );
    }
    
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Users',
            value: '$_totalUsers',
            change: '+12.5%',
            icon: Icons.people,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Service Providers',
            value: '$_serviceProviders',
            change: '+8.2%',
            icon: Icons.business,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Entrance Payments',
            value: '${_entrancePayments.toStringAsFixed(0)} ETB',
            change: '+15.3%',
            icon: Icons.payment,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Landmarks',
            value: '$_totalLandmarks',
            change: '+5.1%',
            icon: Icons.location_on,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 80,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 60,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String change,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformOverviewChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Platform Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'This Month',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 16),
                    onPressed: _loadStatistics,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loadingStats)
            const Center(child: CircularProgressIndicator())
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Users: $_totalUsers | Bookings: ${_bookingStats['total'] ?? 0} | Payments: ${_entrancePayments.toStringAsFixed(0)} ETB',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingsStatusChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bookings by Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (_loadingStats)
            const Center(child: CircularProgressIndicator())
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    if (_bookingStats.isNotEmpty)
                      Column(
                        children: [
                          Text(
                            'Confirmed: ${_bookingStats['confirmed'] ?? 0}',
                            style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Pending: ${_bookingStats['pending'] ?? 0}',
                            style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Completed: ${_bookingStats['completed'] ?? 0}',
                            style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Cancelled: ${_bookingStats['cancelled'] ?? 0}',
                            style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    else
                      Text(
                        'No booking data available',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentAlerts() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Alerts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_loadingStats)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                StreamBuilder<List<EmergencyAlert>>(
                  stream: _emergencyService.getEmergenciesStream(),
                  builder: (context, snapshot) {
                    final activeAlerts = snapshot.data?.where((e) => e.isActive).toList() ?? [];
                    if (activeAlerts.isNotEmpty) {
                      return _buildAlertItem(
                        'SOS Alert',
                        '${activeAlerts.length} emergency response${activeAlerts.length > 1 ? 's' : ''} needed',
                        Colors.red,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                StreamBuilder<List<Payment>>(
                  stream: _paymentService.getEntrancePaymentsStream(),
                  builder: (context, snapshot) {
                    final pendingPayments = snapshot.data?.where((p) => p.isPending).toList() ?? [];
                    if (pendingPayments.isNotEmpty) {
                      return _buildAlertItem(
                        'Payment Pending',
                        '${pendingPayments.length} payment${pendingPayments.length > 1 ? 's' : ''} awaiting verification',
                        Colors.orange,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                if (_userCounts['admin'] == 1)
                  _buildAlertItem('System Status', 'Admin system operational', Colors.green),
                if (_recentBookings.isNotEmpty)
                  _buildAlertItem(
                    'Recent Activity',
                    '${_recentBookings.length} new booking${_recentBookings.length > 1 ? 's' : ''} in system',
                    Colors.blue,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickActionButton('Support Desk', Icons.support_agent, () => _navigateToPage(6)),
              _buildQuickActionButton('Manage Users', Icons.people, () => _navigateToPage(1)),
              _buildQuickActionButton('Verify Providers', Icons.verified, () => _navigateToPage(2)),
              _buildQuickActionButton('Entrance Payments', Icons.payment, () => _navigateToPage(3)),
              _buildQuickActionButton('System Configuration', Icons.settings_suggest, () => _navigateToPage(9)),
              _buildQuickActionButton('Add Landmark', Icons.add_location, () => _navigateToPage(4)),
              _buildQuickActionButton('View Reports', Icons.analytics, () => _navigateToPage(8)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: EthioColors.forest,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onPressed,
    );
  }

  Widget _buildRecentBookingsTable() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Bookings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!_loadingStats)
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  onPressed: _loadStatistics,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loadingStats)
            const Center(child: CircularProgressIndicator())
          else if (_recentBookings.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No recent bookings',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Booking ID')),
                  DataColumn(label: Text('User')),
                  DataColumn(label: Text('Service')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Amount')),
                ],
                rows: _recentBookings.map((booking) {
                  final bookingId = booking['id'] as String? ?? 'Unknown';
                  final touristName = booking['touristName'] as String? ?? 'Unknown';
                  final tourName = booking['tourName'] as String? ?? 'Service';
                  final tourDate = booking['tourDate'] is DateTime 
                      ? (booking['tourDate'] as DateTime).toString().split(' ')[0]
                      : booking['tourDate']?.toString() ?? 'Unknown';
                  final status = booking['status'] as String? ?? 'pending';
                  final amount = booking['totalAmount'] as num? ?? 0;
                  
                  return _buildDataRow(
                    bookingId.substring(0, bookingId.length > 8 ? 8 : bookingId.length),
                    touristName,
                    tourName,
                    tourDate,
                    status,
                    '${amount.toStringAsFixed(0)} ETB',
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(String id, String user, String service, String date, String status, String amount) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return DataRow(
      cells: [
        DataCell(Text(id)),
        DataCell(Text(user)),
        DataCell(Text(service)),
        DataCell(Text(date)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(Text(amount)),
      ],
    );
  }

  Widget _buildRecentActivities() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_loadingStats)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                if (_totalUsers > 0)
                  _buildActivityItem(
                    'Total users',
                    '$_totalUsers registered users in the system',
                    'Live',
                  ),
                if (_serviceProviders > 0)
                  _buildActivityItem(
                    'Service providers',
                    '$_serviceProviders active service providers',
                    'Live',
                  ),
                if (_totalLandmarks > 0)
                  _buildActivityItem(
                    'Landmarks',
                    '$_totalLandmarks landmarks in the database',
                    'Live',
                  ),
                if (_entrancePayments > 0)
                  _buildActivityItem(
                    'Revenue',
                    '${_entrancePayments.toStringAsFixed(0)} ETB in verified entrance payments',
                    'Live',
                  ),
                if (_bookingStats.isNotEmpty)
                  _buildActivityItem(
                    'Bookings',
                    '${_bookingStats['total'] ?? 0} total bookings (${_bookingStats['pending'] ?? 0} pending)',
                    'Live',
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String description, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: EthioColors.forest.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check_circle,
              color: EthioColors.forest,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // Page navigation methods
  void _navigateToPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToEmergencyMonitor() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminEmergencyDashboard()),
    );
  }

  // Individual page builders
  Widget _buildUsersPage() {
    return const AdminPage();
  }

  Widget _buildProvidersPage() {
    return const AdminProvidersPage();
  }

  Widget _buildPaymentsPage() {
    return const AdminPaymentVerificationPage();
  }

  Widget _buildLandmarksPage() {
    return const LandmarksPage();
  }

  Widget _buildBookingsPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('Bookings Management'),
        ],
      ),
    );
  }

  Widget _buildSupportDeskPage() {
    return const ConversationsListPage();
  }

  Widget _buildMessagesPage() {
    return const ConversationsListPage();
  }

  Widget _buildReportsPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('Reports & Analytics'),
        ],
      ),
    );
  }

  Widget _buildSettingsPage() {
    return const AdminSystemConfigPage(isEmbedded: true);
  }

  Widget _buildActivityLogsPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('Activity Logs'),
        ],
      ),
    );
  }
}