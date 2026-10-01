import 'package:flutter/material.dart';
import '../../models/service_provider.dart';
import '../../services/auth_service.dart';
import '../../services/service_provider_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/snackbar_helper.dart';
import '../../widgets/notification_bell_button.dart';
import 'register_provider_page.dart';
import 'provider_reservations_page.dart';
import 'provider_payments_page.dart';
import 'provider_notifications_page.dart';
import 'provider_edit_profile_page.dart';
import '../chat/conversations_list_page.dart';

class ProviderDashboardPage extends StatefulWidget {
  final ServiceProvider? provider;
  const ProviderDashboardPage({super.key, this.provider});

  @override
  State<ProviderDashboardPage> createState() => _ProviderDashboardPageState();
}

class _ProviderDashboardPageState extends State<ProviderDashboardPage> {
  final AuthService _auth = AuthService();
  final ServiceProviderService _service = ServiceProviderService();

  ServiceProvider? _provider;
  bool _loading = true;

  Map<String, dynamic> _dashboardStats = {
    'reservationsCount': 0,
    'confirmedReservations': 0,
    'totalEarnings': 0.0,
    'unreadMessagesCount': 0,
    'rating': 0.0,
    'reviewCount': 0,
  };

  @override
  void initState() {
    super.initState();
    _provider = widget.provider;
    if (_provider != null) {
      _loading = false;
      // Load dashboard stats
      _service.getProviderDashboardStatsStream(_provider!.id).listen((stats) {
        if (mounted) {
          setState(() {
            _dashboardStats = stats;
          });
        }
      });
    } else {
      _loadProviderProfile();
    }
  }

  Future<void> _loadProviderProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final p = await _service.getProviderByUserId(user.uid);
      if (mounted) {
        setState(() {
          _provider = p;
          _loading = false;
        });
        // Load dashboard stats
        if (p != null) {
          _service.getProviderDashboardStatsStream(p.id).listen((stats) {
            if (mounted) {
              setState(() {
                _dashboardStats = stats;
              });
            }
          });
        }
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Provider Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_provider == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Provider Dashboard')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.store_mall_directory_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No Business Registered Yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Register your hotel, restaurant, or transport business to manage services and receive bookings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_business),
                  label: const Text('Register Business Now'),
                  onPressed: () async {
                    final res = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const RegisterProviderPage()),
                    );
                    if (res == true) _loadProviderProfile();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    Text(
                      _provider!.businessName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.teal.shade100,
                  child: Text(_provider!.typeIcon, style: const TextStyle(fontSize: 28)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Business Summary Header Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.business, color: Colors.teal.shade700, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _provider!.businessName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text('${_provider!.typeDisplayName} • ${_provider!.city}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.green.shade300),
                                ),
                                child: const Text('Verified & Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.blue.shade300),
                                ),
                                child: Text('${_provider!.rating} ★', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
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
            const SizedBox(height: 20),
            
            // Quick Overview Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quick Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 16, color: Colors.teal.shade700),
                      const SizedBox(width: 4),
                      Text('Today', style: TextStyle(fontSize: 12, color: Colors.teal.shade700, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Overview Cards
            Row(
              children: [
                Expanded(
                  child: _buildOverviewCard(
                    icon: Icons.book_online,
                    title: 'Reservations',
                    value: _dashboardStats['reservationsCount'].toString(),
                    subtitle: '${_dashboardStats['confirmedReservations']} confirmed',
                    color: const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOverviewCard(
                    icon: Icons.payments,
                    title: 'Earnings',
                    value: '${_dashboardStats['totalEarnings'].toStringAsFixed(0)} ETB',
                    subtitle: 'Total revenue',
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewCard(
                    icon: Icons.chat_bubble,
                    title: 'Messages',
                    value: _dashboardStats['unreadMessagesCount'].toString(),
                    subtitle: 'Unread messages',
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOverviewCard(
                    icon: Icons.star_rate,
                    title: 'Rating',
                    value: _dashboardStats['rating'].toStringAsFixed(1),
                    subtitle: '${_dashboardStats['reviewCount']} reviews',
                    color: const Color(0xFFEC4899),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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
}
