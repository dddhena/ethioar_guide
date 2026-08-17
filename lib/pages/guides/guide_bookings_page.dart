import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../models/guide.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/guide_service.dart';
import '../../widgets/snackbar_helper.dart';
import '../chat/chat_page.dart';

class GuideBookingsPage extends StatefulWidget {
  final Guide guide;
  final int initialTab;

  const GuideBookingsPage({super.key, required this.guide, this.initialTab = 0});

  @override
  State<GuideBookingsPage> createState() => _GuideBookingsPageState();
}

class _GuideBookingsPageState extends State<GuideBookingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final GuideService _guides = GuideService();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this, initialIndex: widget.initialTab.clamp(0, 2));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Color _statusColor(Booking b) {
    if (b.isConfirmed) return Colors.green.shade800;
    if (b.isCancelled) return Colors.red.shade800;
    if (b.isCompleted) return Colors.blue.shade800;
    return Colors.amber.shade900;
  }

  Color _statusBg(Booking b) {
    if (b.isConfirmed) return Colors.green.shade50;
    if (b.isCancelled) return Colors.red.shade50;
    if (b.isCompleted) return Colors.blue.shade50;
    return Colors.amber.shade50;
  }

  Future<void> _messageTourist(Booking b) async {
    final user = AuthService().currentUser;
    if (user == null || b.touristId.isEmpty) return;
    final conv = await ChatService().getOrCreateConversation(
      currentUserId: user.uid,
      currentUserName: widget.guide.name,
      currentUserRole: 'tour_guide',
      otherUserId: b.touristId,
      otherUserName: b.touristName.isEmpty ? 'Tourist' : b.touristName,
      otherUserRole: 'tourist',
      channelType: 'guide_tourist',
    );
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          chatId: conv.id,
          otherUserId: b.touristId,
          otherUserName: b.touristName.isEmpty ? 'Tourist' : b.touristName,
          otherUserRole: 'tourist',
          channelType: 'guide_tourist',
        ),
      ),
    );
  }

  Widget _bookingCard(Booking b, {required bool showActions}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(b.tourName.isEmpty ? 'Tour booking' : b.tourName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: _statusBg(b), borderRadius: BorderRadius.circular(8)),
                  child: Text(b.status.toUpperCase(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _statusColor(b))),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Tourist: ${b.touristName.isEmpty ? b.touristEmail : b.touristName}'),
            Text('Date: ${b.formattedTourDate}  •  ${b.numberOfParticipants} participants  •  ${b.formattedTotal}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            if (b.notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Note: "${b.notes}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.chat, size: 16),
                  label: const Text('Message'),
                  onPressed: () => _messageTourist(b),
                ),
                if (showActions && b.isPending) ...[
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () async {
                      await _guides.updateBookingStatus(b, 'cancelled');
                      if (mounted) SnackbarHelper.show(context, 'Booking declined');
                    },
                    child: const Text('Decline'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await _guides.updateBookingStatus(b, 'confirmed');
                      if (mounted) SnackbarHelper.show(context, 'Booking accepted');
                    },
                    child: const Text('Accept'),
                  ),
                ],
                if (showActions && b.isConfirmed)
                  ElevatedButton(
                    onPressed: () async {
                      await _guides.updateBookingStatus(b, 'completed');
                      if (mounted) SnackbarHelper.show(context, 'Tour marked completed');
                    },
                    child: const Text('Mark completed'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _list({required List<Booking> Function(List<Booking>) filter, required bool showActions, String empty = 'No bookings'}) {
    return StreamBuilder<List<Booking>>(
      stream: _guides.getGuideBookingsStream(widget.guide.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = filter(snapshot.data ?? []);
        if (list.isEmpty) {
          return Center(child: Text(empty, style: const TextStyle(color: Colors.grey)));
        }
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) => _bookingCard(list[i], showActions: showActions),
        );
      },
    );
  }

  Widget _summary() {
    return StreamBuilder<List<Booking>>(
      stream: _guides.getGuideBookingsStream(widget.guide.id),
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];
        final pending = all.where((b) => b.isPending).length;
        final confirmed = all.where((b) => b.isConfirmed).length;
        final completed = all.where((b) => b.isCompleted).length;
        final cancelled = all.where((b) => b.isCancelled).length;
        Widget chip(String label, int count, Color color) => Expanded(
              child: Card(
                color: color.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                      Text(label, style: TextStyle(fontSize: 11, color: color)),
                    ],
                  ),
                ),
              ),
            );
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              chip('Pending', pending, Colors.amber.shade900),
              chip('Confirmed', confirmed, Colors.green.shade800),
              chip('Completed', completed, Colors.blue.shade800),
              chip('Cancelled', cancelled, Colors.red.shade800),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Guide Bookings'),
          bottom: TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Requests'),
              Tab(text: 'My Bookings'),
              Tab(text: 'Schedule'),
            ],
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _summary(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _list(
                            filter: (l) => l.where((b) => b.isPending).toList(),
                            showActions: true,
                            empty: 'No pending booking requests',
                          ),
                          _list(
                            filter: (l) => l,
                            showActions: true,
                            empty: 'No bookings yet',
                          ),
                          _list(
                            filter: (l) {
                              final upcoming = l.where((b) => !b.isCancelled).toList();
                              upcoming.sort((a, b) => a.tourDate.compareTo(b.tourDate));
                              return upcoming;
                            },
                            showActions: false,
                            empty: 'No upcoming tours on your schedule',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }
}
