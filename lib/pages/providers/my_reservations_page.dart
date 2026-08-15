import 'package:flutter/material.dart';
import '../../models/reservation.dart';
import '../../services/auth_service.dart';
import '../../services/service_provider_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/snackbar_helper.dart';

class MyReservationsPage extends StatefulWidget {
  const MyReservationsPage({super.key});

  @override
  State<MyReservationsPage> createState() => _MyReservationsPageState();
}

class _MyReservationsPageState extends State<MyReservationsPage> {
  final AuthService _auth = AuthService();
  final ServiceProviderService _service = ServiceProviderService();

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return AppScaffold(
        title: 'My Reservations',
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Please log in to view your reservations.'),
            ],
          ),
        ),
      );
    }

    return AppScaffold(
      title: 'My Reservations',
      body: StreamBuilder<List<Reservation>>(
        stream: _service.getTouristReservationsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snapshot.data ?? [];

          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'No reservations yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explore top Ethiopian hotels, cultural restaurants, and transport services to book your stay!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Explore Services'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            itemBuilder: (context, i) {
              return _buildReservationCard(list[i]);
            },
          );
        },
      ),
    );
  }

  Widget _buildReservationCard(Reservation r) {
    Color statusBg;
    Color statusText;
    IconData statusIcon;

    switch (r.status.toLowerCase()) {
      case 'confirmed':
        statusBg = Colors.green.shade50;
        statusText = Colors.green.shade800;
        statusIcon = Icons.check_circle;
        break;
      case 'declined':
        statusBg = Colors.red.shade50;
        statusText = Colors.red.shade800;
        statusIcon = Icons.cancel;
        break;
      case 'cancelled':
        statusBg = Colors.grey.shade100;
        statusText = Colors.grey.shade700;
        statusIcon = Icons.remove_circle;
        break;
      default: // pending
        statusBg = Colors.amber.shade50;
        statusText = Colors.amber.shade900;
        statusIcon = Icons.hourglass_top;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.serviceName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r.providerName,
                        style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusText.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusText),
                      const SizedBox(width: 4),
                      Text(
                        r.status.toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: statusText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Icon(Icons.calendar_month, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text('Date: ${r.formattedDates}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text('Guests: ${r.numberOfGuests}', style: const TextStyle(fontSize: 13)),
                  ],
                ),
                Text(
                  'Total: ${r.formattedTotal}',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                ),
              ],
            ),
            if (r.specialRequests.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Note: "${r.specialRequests}"',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
            if (r.isPending) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Cancel Reservation'),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Cancel Reservation'),
                        content: const Text('Are you sure you want to cancel this reservation request?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Cancel Booking'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await _service.updateReservationStatus(r.id, 'cancelled');
                      if (context.mounted) {
                        SnackbarHelper.show(context, 'Reservation cancelled.');
                      }
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
