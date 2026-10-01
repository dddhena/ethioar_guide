import 'package:flutter/material.dart';
import '../../models/guide.dart';
import '../../models/guide_profile.dart';
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
  final Guide? guide;
  final GuideProfile? profile;

  const GuideDetailsPage({super.key, this.guide, this.profile});

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
    if (widget.guide != null) {
      _loadTours();
    }
  }

  Future<void> _loadTours() async {
    if (widget.guide == null) return;
    final list = await _guides.fetchToursForGuide(widget.guide!.id);
    if (!mounted) return;
    setState(() {
      _tours = list.where((t) => t.isActive).toList();
      _loading = false;
    });
  }

  String get guideName {
    if (widget.profile != null) return widget.profile!.publicName;
    if (widget.guide != null) return widget.guide!.name;
    return 'Guide';
  }

  String get guideId {
    if (widget.guide != null) return widget.guide!.id;
    if (widget.profile != null) return widget.profile!.userId;
    return '';
  }

  String get guideUserId {
    if (widget.guide != null) return widget.guide!.userId;
    if (widget.profile != null) return widget.profile!.userId;
    return '';
  }

  Future<void> _messageGuide() async {
    final user = _auth.currentUser;
    if (user == null) {
      SnackbarHelper.show(context, 'Please sign in to message this guide.');
      return;
    }
    final target = guideUserId.isNotEmpty ? guideUserId : guideId;
    final conv = await ChatService().getOrCreateConversation(
      currentUserId: user.uid,
      currentUserName: user.displayName ?? 'Tourist',
      currentUserRole: 'tourist',
      otherUserId: target,
      otherUserName: guideName,
      otherUserRole: 'tour_guide',
      channelType: 'guide_tourist',
    );
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          chatId: conv.id,
          otherUserId: target,
          otherUserName: guideName,
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
          guideId: guideId,
          tourId: tour.id,
          bookingDate: DateTime.now(),
          tourDate: tourDate,
          numberOfParticipants: participants,
          totalAmount: tour.price * participants,
          status: 'pending',
          touristName: profile.name.isNotEmpty ? profile.name : (user.displayName ?? 'Tourist'),
          touristEmail: profile.email.isNotEmpty ? profile.email : (user.email ?? ''),
          touristPhone: profile.phone,
          guideName: guideName,
          tourName: tour.name,
          notes: notesCtrl.text.trim(),
        ),
      );
      if (!mounted) return;
      SnackbarHelper.show(context, 'Booking request sent to $guideName');
    } catch (e) {
      if (mounted) SnackbarHelper.show(context, 'Could not send booking: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final usingProfile = widget.profile != null;
    return AppScaffold(
      title: guideName,
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
                  if (usingProfile && widget.profile!.hasPhoto) ...[
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(widget.profile!.profileImageUrl!),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(guideName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  if (usingProfile) ...[
                    Text('${widget.profile!.experienceLabel} • ${widget.profile!.pricingLabel}'),
                    if (widget.profile!.rating > 0) 
                      Text('Rating ${widget.profile!.rating.toStringAsFixed(1)}'),
                    const SizedBox(height: 10),
                    Text(widget.profile!.bio.isEmpty ? 'This guide has not added a bio yet.' : widget.profile!.bio),
                    const SizedBox(height: 12),
                    Text('Languages: ${widget.profile!.languagesLabel}'),
                    Text('Specialties: ${widget.profile!.specialtiesLabel}'),
                    const SizedBox(height: 8),
                    Text('Services: ${widget.profile!.services.join(", ")}'),
                    const SizedBox(height: 8),
                    Text('Availability: ${widget.profile!.availabilityLabel}', style: TextStyle(color: Colors.green.shade800)),
                  ] else if (widget.guide != null) ...[
                    Text('${widget.guide!.experienceYears} years experience • ${widget.guide!.formattedPrice}'),
                    if (widget.guide!.rating > 0) Text('Rating ${widget.guide!.rating.toStringAsFixed(1)} (${widget.guide!.reviewCount} reviews)'),
                    const SizedBox(height: 10),
                    Text(widget.guide!.bio.isEmpty ? 'This guide has not added a bio yet.' : widget.guide!.bio),
                    const SizedBox(height: 12),
                    Text('Languages: ${widget.guide!.languagesLabel}'),
                    Text('Qualifications: ${widget.guide!.qualificationsLabel}'),
                    const SizedBox(height: 8),
                    Text('Availability: ${widget.guide!.availabilitySummary}', style: TextStyle(color: Colors.green.shade800)),
                  ],
                ],
              ),
            ),
          ),
          if (widget.guide != null) ...[
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
        ],
      ),
    );
  }
}
