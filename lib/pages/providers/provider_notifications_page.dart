import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/service_provider_service.dart';
import '../../widgets/app_scaffold.dart';

class ProviderNotificationsPage extends StatelessWidget {
  const ProviderNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final user = auth.currentUser;
    if (user == null) {
      return AppScaffold(
        title: 'Notifications',
        body: const Center(child: Text('Please log in as a provider.')),
      );
    }
    // Placeholder implementation: In a real app, you would fetch notifications from a service.
    return AppScaffold(
      title: 'Provider Notifications',
      body: const Center(
        child: Text('No notifications yet.'),
      ),
    );
  }
}
