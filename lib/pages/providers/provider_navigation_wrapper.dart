import 'package:flutter/material.dart';
import 'provider_dashboard_page.dart';
import 'provider_reservations_page.dart';
import 'provider_payments_page.dart';
import 'provider_edit_profile_page.dart';
import 'provider_notifications_page.dart';
import '../../models/service_provider.dart';
import '../../widgets/notification_bell_button.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../chat/conversations_list_page.dart';

class ProviderNavigationWrapper extends StatefulWidget {
  final int initialIndex;
  final ServiceProvider? provider;

  const ProviderNavigationWrapper({
    super.key,
    this.initialIndex = 0,
    this.provider,
  });

  @override
  State<ProviderNavigationWrapper> createState() => _ProviderNavigationWrapperState();
}

class _ProviderNavigationWrapperState extends State<ProviderNavigationWrapper> {
  int _selectedTabIndex = 0;
  final AuthService _auth = AuthService();
  final ThemeService _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Provider Portal'),
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
      body: IndexedStack(
        index: _selectedTabIndex,
        children: [
          ProviderDashboardPage(provider: widget.provider),
          const ProviderReservationsPage(showAppBar: false),
          const ConversationsListPage(showAppBar: false),
          const ProviderPaymentsPage(showAppBar: false),
          widget.provider != null
              ? ProviderEditProfilePage(provider: widget.provider!)
              : const Center(child: CircularProgressIndicator()),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
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
                icon: Icons.event,
                label: 'Reservations',
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
                },
              ),
              _buildNavItem(
                icon: Icons.payment,
                label: 'Payments',
                isSelected: _selectedTabIndex == 3,
                onTap: () {
                  setState(() {
                    _selectedTabIndex = 3;
                  });
                },
              ),
              _buildNavItem(
                icon: Icons.person,
                label: 'Profile',
                isSelected: _selectedTabIndex == 4,
                onTap: () {
                  setState(() {
                    _selectedTabIndex = 4;
                  });
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
}