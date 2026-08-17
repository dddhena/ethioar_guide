import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/app_scaffold.dart';
import 'providers/my_reservations_page.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final user = auth.currentUser;
    final service = NotificationService();

    if (user == null) {
      return AppScaffold(
        title: 'Notifications',
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Please sign in to view your notifications.', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return AppScaffold(
      title: 'Notifications',
      actions: [
        IconButton(
          icon: const Icon(Icons.done_all),
          tooltip: 'Mark all as read',
          onPressed: () async {
            await service.markAllAsRead(user.uid);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read')),
              );
            }
          },
        ),
      ],
      body: StreamBuilder<List<AppNotification>>(
        stream: service.getUserNotificationsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snapshot.data ?? [];

          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.notifications_none, size: 64, color: Colors.teal.shade600),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'No Notifications Yet',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'When you book services, receive payments, or get status updates, they will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final n = list[index];

              IconData icon;
              Color iconColor;
              Color bgColor;

              switch (n.type) {
                case 'payment_success':
                  icon = Icons.account_balance_wallet;
                  iconColor = Colors.green.shade700;
                  bgColor = Colors.green.shade50;
                  break;
                case 'booking_created':
                  icon = Icons.event_available;
                  iconColor = Colors.blue.shade700;
                  bgColor = Colors.blue.shade50;
                  break;
                case 'reservation_confirmed':
                  icon = Icons.check_circle;
                  iconColor = Colors.teal.shade700;
                  bgColor = Colors.teal.shade50;
                  break;
                case 'reservation_declined':
                  icon = Icons.cancel;
                  iconColor = Colors.red.shade700;
                  bgColor = Colors.red.shade50;
                  break;
                default:
                  icon = Icons.notifications;
                  iconColor = Colors.orange.shade700;
                  bgColor = Colors.orange.shade50;
              }

              return InkWell(
                onTap: () {
                  if (!n.isRead) {
                    service.markAsRead(n.id);
                  }
                  if (n.type.contains('reservation') || n.type.contains('booking')) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyReservationsPage()),
                    );
                  }
                },
                child: Container(
                  color: n.isRead ? Colors.transparent : Colors.teal.withValues(alpha: 0.05),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: iconColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    n.title,
                                    style: TextStyle(
                                      fontWeight: n.isRead ? FontWeight.w600 : FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Text(
                                  n.timeAgo,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              n.message,
                              style: TextStyle(
                                fontSize: 13,
                                color: n.isRead ? Colors.grey.shade700 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!n.isRead) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade700,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
