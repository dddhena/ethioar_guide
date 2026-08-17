import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/guide_service.dart';
import '../../widgets/app_scaffold.dart';
import '../chat/chat_page.dart';

class MyGuideBookingsPage extends StatelessWidget {
  const MyGuideBookingsPage({super.key});

  Color _statusColor(Booking b) {
    if (b.isConfirmed) return Colors.green.shade800;
    if (b.isCancelled) return Colors.red.shade800;
    if (b.isCompleted) return Colors.blue.shade800;
    return Colors.amber.shade900;
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) {
      return const AppScaffold(
        title: 'My Guide Bookings',
        body: Center(child: Text('Please sign in to view your bookings.')),
      );
    }

    return AppScaffold(
      title: 'My Guide Bookings',
      body: StreamBuilder<List<Booking>>(
        stream: GuideService().getTouristBookingsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('You have not booked a tour guide yet.'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final b = list[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(b.tourName.isEmpty ? 'Guide booking' : b.tourName),
                  subtitle: Text(
                    '${b.guideName} • ${b.formattedTourDate}\n${b.numberOfParticipants} participants • ${b.formattedTotal} • ${b.status.toUpperCase()}',
                  ),
                  isThreeLine: true,
                  trailing: Icon(Icons.circle, size: 12, color: _statusColor(b)),
                  onTap: () async {
                    if (b.guideId.isEmpty) return;
                    final guide = await GuideService().getGuideById(b.guideId);
                    final otherId = guide?.userId.isNotEmpty == true ? guide!.userId : b.guideId;
                    final conv = await ChatService().getOrCreateConversation(
                      currentUserId: user.uid,
                      currentUserName: user.displayName ?? 'Tourist',
                      currentUserRole: 'tourist',
                      otherUserId: otherId,
                      otherUserName: b.guideName.isEmpty ? 'Guide' : b.guideName,
                      otherUserRole: 'tour_guide',
                      channelType: 'guide_tourist',
                    );
                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          chatId: conv.id,
                          otherUserId: otherId,
                          otherUserName: b.guideName.isEmpty ? 'Guide' : b.guideName,
                          otherUserRole: 'tour_guide',
                          channelType: 'guide_tourist',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
