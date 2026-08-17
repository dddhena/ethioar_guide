import 'package:flutter/material.dart';
import '../../models/guide.dart';
import '../../models/tour_package.dart';
import '../../models/booking.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/firestore_service.dart';
import '../../services/guide_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/snackbar_helper.dart';
import '../chat/chat_page.dart';

class GuideDetailsPage extends StatefulWidget {
  final Guide guide;

  const GuideDetailsPage({super.key, required this.guide});

  @override
  State<GuideDetailsPage> createState() => _GuideDetailsPageState();
}

class _GuideDetailsPageState extends State<GuideDetailsPage> {
  final GuideService _guides = GuideService();
  final AuthService _auth = AuthService();
  List<TourPackage> _tours = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTours();
  }

  Future<void> _loadTours() async {
    final list = await _guides.fetchToursForGuide(widget.guide.id);
    if (!mounted) return;
    setState(() {
      _tours = list.where((t) => t.isActive).toList();
      _loading = false;
    });
  }

  Future<void> _messageGuide() async {
    final user = _auth.currentUser;
    if (user == null) {
      SnackbarHelper.show(context, 'Please sign in to message this guide.');
      return;
    }
    final target = widget.guide.userId.isNotEmpty ? widget.guide.userId : widget.guide.id;
    final conv = await ChatService().getOrCreateConversation(
      currentUserId: user.uid,
      currentUserName: user.displayName ?? 'Tourist',
      currentUserRole: 'tourist',
      otherUserId: target,
      otherUserName: widget.guide.name,
      otherUserRole: 'tour_guide',
      channelType: 'guide_tourist',
    );
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          chatId: conv.id,
          otherUserId: target,
          otherUserName: widget.guide.name,
          otherUserRole: 'tour_guide',
          channelType: 'guide_tourist',
        ),
      ),
    );
  }

  Future<void> _bookTour(TourPackage tour) async {
    final user = _auth.currentUser;
    if (user == null) {
      SnackbarHelper.show(context, 'Please sign in to book a guide.');
      return;
    }

    DateTime tourDate = DateTime.now().add(const Duration(days: 1));
    int participants = 1;
    final notesCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialog) {
            return AlertDialog(
              title: Text('Book ${tour.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tour date'),
                    subtitle: Text('${tourDate.day}/${tourDate.month}/${tourDate.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: tourDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setDialog(() => tourDate = picked);
                    },
                  ),
                  Row(
                    children: [
                      const Text('Participants'),
                      const Spacer(),
                      IconButton(
                        onPressed: participants > 1 ? () => setDialog(() => participants--) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$participants'),
                      IconButton(
                        onPressed: () => setDialog(() => participants++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Meeting notes (optional)'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: ${(tour.price * participants).toStringAsFixed(0)} ETB',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send Request')),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      final profile = await FirestoreService().getUserProfileModel(user.uid);
      await _guides.createBooking(
        Booking(
          id: '',
          touristId: user.uid,
          guideId: widget.guide.id,
          tourId: tour.id,
          bookingDate: DateTime.now(),
          tourDate: tourDate,
          numberOfParticipants: participants,
          totalAmount: tour.price * participants,
          status: 'pending',
          touristName: profile.name.isNotEmpty ? profile.name : (user.displayName ?? 'Tourist'),
          touristEmail: profile.email.isNotEmpty ? profile.email : (user.email ?? ''),
          touristPhone: profile.phone,
          guideName: widget.guide.name,
          tourName: tour.name,
          notes: notesCtrl.text.trim(),
        ),
      );
      if (!mounted) return;
      SnackbarHelper.show(context, 'Booking request sent to ${widget.guide.name}');
    } catch (e) {
      if (mounted) SnackbarHelper.show(context, 'Could not send booking: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.guide;
    return AppScaffold(
      title: g.name,
      actions: [
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          tooltip: 'Message guide',
          onPressed: _messageGuide,
        ),
      ],
      body: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('${g.experienceYears} years experience • ${g.formattedPrice}'),
                  if (g.rating > 0) Text('Rating ${g.rating.toStringAsFixed(1)} (${g.reviewCount} reviews)'),
                  const SizedBox(height: 10),
                  Text(g.bio.isEmpty ? 'This guide has not added a bio yet.' : g.bio),
                  const SizedBox(height: 12),
                  Text('Languages: ${g.languagesLabel}'),
                  Text('Qualifications: ${g.qualificationsLabel}'),
                  const SizedBox(height: 8),
                  Text('Availability: ${g.availabilitySummary}', style: TextStyle(color: Colors.green.shade800)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Tour services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_tours.isEmpty)
            const Text('This guide has not listed tour services yet.')
          else
            ..._tours.map(
              (t) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('${t.durationLabel} • ${t.language} • ${t.formattedPrice}'),
                      if (t.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(t.description),
                      ],
                      const SizedBox(height: 6),
                      Text('Attractions: ${t.attractionsLabel}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () => _bookTour(t),
                          child: const Text('Request booking'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
