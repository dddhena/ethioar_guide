import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/guide.dart';
import '../models/tour_package.dart';
import '../models/booking.dart';
import '../models/user_profile.dart';
import '../models/payment.dart';
import 'notification_service.dart';
import 'chat_service.dart';

class GuideService {
  static final GuideService _instance = GuideService._internal();
  factory GuideService() => _instance;
  GuideService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================================
  // GUIDES
  // ==========================================

  Future<Guide?> getGuideByUserId(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final snapshot = await _db
          .collection('guides')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return Guide.fromMap(doc.id, doc.data());
      }
    } catch (_) {}
    return null;
  }

  Future<Guide?> getGuideById(String id) async {
    try {
      final doc = await _db.collection('guides').doc(id).get();
      if (doc.exists && doc.data() != null) {
        return Guide.fromMap(doc.id, doc.data()!);
      }
    } catch (_) {}
    try {
      return _demoGuides.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<String> createGuideProfile(Guide guide) async {
    final docRef = await _db.collection('guides').add(guide.toMap());
    if (guide.userId.isNotEmpty) {
      await _db.collection('users').doc(guide.userId).set({
        'role': 'tour_guide',
        'guideId': docRef.id,
      }, SetOptions(merge: true));
    }
    return docRef.id;
  }

  Future<void> updateGuideProfile(Guide guide) async {
    await _db.collection('guides').doc(guide.id).update(guide.toMap());
  }

  Future<void> updateAvailability(String guideId, Map<String, bool> availability) async {
    await _db.collection('guides').doc(guideId).update({'availability': availability});
  }

  Future<List<Guide>> fetchActiveGuides() async {
    try {
      final snapshot = await _db.collection('guides').get();
      final list = snapshot.docs
          .map((d) => Guide.fromMap(d.id, d.data()))
          .where((g) => g.isActive)
          .toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}
    return _demoGuides;
  }

  Stream<List<Guide>> getActiveGuidesStream() {
    return _db.collection('guides').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((d) => Guide.fromMap(d.id, d.data()))
          .where((g) => g.isActive)
          .toList();
      if (list.isEmpty) return _demoGuides;
      return list;
    }).handleError((_) => _demoGuides);
  }

  // ==========================================
  // TOUR PACKAGES
  // ==========================================

  Stream<List<TourPackage>> getToursStream(String guideId) {
    if (guideId.isEmpty) return Stream.value([]);
    return _db
        .collection('tour_packages')
        .where('guideId', isEqualTo: guideId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((d) => TourPackage.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      if (list.isEmpty) {
        return _demoTours.where((t) => t.guideId == guideId).toList();
      }
      return list;
    }).handleError((_) => _demoTours.where((t) => t.guideId == guideId).toList());
  }

  Future<List<TourPackage>> fetchToursForGuide(String guideId) async {
    try {
      final snapshot = await _db
          .collection('tour_packages')
          .where('guideId', isEqualTo: guideId)
          .get();
      final list = snapshot.docs
          .map((d) => TourPackage.fromMap(d.id, d.data()))
          .toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}
    return _demoTours.where((t) => t.guideId == guideId).toList();
  }

  Future<void> addTour(TourPackage tour) async {
    await _db.collection('tour_packages').add(tour.toMap());
  }

  Future<void> updateTour(TourPackage tour) async {
    await _db.collection('tour_packages').doc(tour.id).update(tour.toMap());
  }

  Future<void> deleteTour(String tourId) async {
    await _db.collection('tour_packages').doc(tourId).delete();
  }

  // ==========================================
  // BOOKINGS
  // ==========================================

  Future<String> createBooking(Booking booking) async {
    final docRef = _db.collection('bookings').doc();
    await docRef.set(booking.toMap());

    final guide = await getGuideById(booking.guideId);
    if (guide != null && guide.userId.isNotEmpty) {
      await NotificationService().sendNotification(
        userId: guide.userId,
        title: 'New booking request',
        message:
            '${booking.touristName} requested ${booking.tourName} on ${booking.formattedTourDate} (${booking.numberOfParticipants} participants, ${booking.formattedTotal}).',
        type: 'booking_created',
        relatedId: docRef.id,
      );
    }
    return docRef.id;
  }

  Future<void> updateBookingStatus(Booking booking, String status) async {
    await _db.collection('bookings').doc(booking.id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (booking.touristId.isEmpty) return;

    final title = status == 'confirmed'
        ? 'Booking confirmed'
        : status == 'cancelled'
            ? 'Booking declined'
            : status == 'completed'
                ? 'Tour marked completed'
                : 'Booking updated';
    final message = status == 'confirmed'
        ? '${booking.guideName} accepted your request for ${booking.tourName} on ${booking.formattedTourDate}.'
        : status == 'cancelled'
            ? '${booking.guideName} declined your request for ${booking.tourName} on ${booking.formattedTourDate}.'
            : status == 'completed'
                ? 'Your tour "${booking.tourName}" was marked completed. Thank you for traveling with EthioAR Guide.'
                : 'Your booking for ${booking.tourName} is now $status.';

    await NotificationService().sendNotification(
      userId: booking.touristId,
      title: title,
      message: message,
      type: 'booking_$status',
      relatedId: booking.id,
    );
  }

  Stream<List<Booking>> getGuideBookingsStream(String guideId) {
    if (guideId.isEmpty) return Stream.value([]);
    return _db
        .collection('bookings')
        .where('guideId', isEqualTo: guideId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((d) => Booking.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.tourDate.compareTo(a.tourDate));
      return list;
    });
  }

  Stream<List<Booking>> getTouristBookingsStream(String touristId) {
    if (touristId.isEmpty) return Stream.value([]);
    return _db
        .collection('bookings')
        .where('touristId', isEqualTo: touristId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((d) => Booking.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.tourDate.compareTo(a.tourDate));
      return list;
    });
  }

  Stream<int> getPendingBookingCountStream(String guideId) {
    return getGuideBookingsStream(guideId).map(
      (list) => list.where((b) => b.isPending).length,
    );
  }

  // ==========================================
  // DASHBOARD STATISTICS
  // ==========================================

  /// Get dashboard statistics for a tour guide
  Stream<Map<String, dynamic>> getGuideDashboardStatsStream(String guideId) {
    if (guideId.isEmpty) return Stream.value({});

    return _db.collection('bookings').snapshots().asyncMap((snapshot) async {
      // Get today's date
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      // Get guide profile for rating
      double rating = 0.0;
      int reviewCount = 0;
      try {
        final guideDoc = await _db.collection('guides').doc(guideId).get();
        if (guideDoc.exists && guideDoc.data() != null) {
          final guide = Guide.fromMap(guideDoc.id, guideDoc.data()!);
          rating = guide.rating;
          reviewCount = guide.reviewCount;
        }
      } catch (_) {}

      // Get all bookings for this guide
      final bookings = snapshot.docs
          .map((d) => Booking.fromMap(d.id, d.data()))
          .where((b) => b.guideId == guideId)
          .toList();

      // Today's statistics
      final todayBookings = bookings.where((b) {
        final bookingDate = DateTime(b.tourDate.year, b.tourDate.month, b.tourDate.day);
        return bookingDate.isAtSameMomentAs(today);
      }).toList();

      final todayTours = todayBookings.length;
      final todayTourists = todayBookings.fold(0, (sum, b) => sum + b.numberOfParticipants);
      final todayDuration = todayBookings.fold(0.0, (sum, b) => sum + (b.tourDurationHours ?? 0));
      final todayEarnings = todayBookings
          .where((b) => b.isConfirmed || b.isCompleted)
          .fold(0.0, (sum, b) => sum + b.totalAmount);

      // Calculate total duration in hours and minutes
      final totalHours = todayDuration.floor();
      final totalMinutes = ((todayDuration - totalHours) * 60).round();
      final durationString = '${totalHours}h ${totalMinutes}m';

      // Upcoming tours (confirmed, starting from today onwards)
      final upcomingTours = bookings
          .where((b) => (b.isConfirmed || b.isUpcoming) && b.tourDate.isAfter(today.subtract(const Duration(days: 1))))
          .toList();
      upcomingTours.sort((a, b) => a.tourDate.compareTo(b.tourDate));

      // Get tour packages for tour details
      final tourPackages = await fetchToursForGuide(guideId);
      final tourMap = {for (var t in tourPackages) t.id: t};

      // Performance summary (this month)
      final thisMonth = DateTime(now.year, now.month, 1);
      final nextMonth = thisMonth.month == 12 
          ? DateTime(now.year + 1, 1, 1) 
          : DateTime(now.year, thisMonth.month + 1, 1);

      final monthBookings = bookings.where((b) {
        return b.tourDate.isAtSameMomentAs(thisMonth) || 
               (b.tourDate.isAfter(thisMonth) && b.tourDate.isBefore(nextMonth));
      }).toList();

      final totalTours = monthBookings.length;
      final totalTourists = monthBookings.fold(0, (sum, b) => sum + b.numberOfParticipants);
      final totalEarnings = monthBookings
          .where((b) => b.isConfirmed || b.isCompleted)
          .fold(0.0, (sum, b) => sum + b.totalAmount);

      // Generate monthly data for graph (last 6 months)
      final monthlyData = <int>[];
      for (int i = 5; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final nextMonthDate = monthDate.month == 12 
            ? DateTime(monthDate.year + 1, 1, 1) 
            : DateTime(monthDate.year, monthDate.month + 1, 1);
        
        final monthTours = bookings.where((b) {
          return b.tourDate.isAtSameMomentAs(monthDate) || 
                 (b.tourDate.isAfter(monthDate) && b.tourDate.isBefore(nextMonthDate));
        }).length;
        
        monthlyData.add(monthTours);
      }

      // Get unread messages count
      int unreadMessagesCount = 0;
      try {
        final chatService = ChatService();
        final guideUser = await getGuideById(guideId);
        if (guideUser != null && guideUser.userId.isNotEmpty) {
          final unreadStream = chatService.getTotalUnreadMessagesCountStream(guideUser.userId);
          final unread = await unreadStream.first;
          unreadMessagesCount = unread;
        }
      } catch (_) {}

      return {
        'todayTours': todayTours,
        'todayTourists': todayTourists,
        'todayDuration': durationString,
        'todayEarnings': todayEarnings,
        'upcomingTours': upcomingTours.take(5).toList(),
        'tourMap': tourMap,
        'totalTours': totalTours,
        'totalTourists': totalTourists,
        'avgRating': rating,
        'reviewCount': reviewCount,
        'totalEarnings': totalEarnings,
        'unreadMessagesCount': unreadMessagesCount,
        'monthlyData': monthlyData,
      };
    });
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(uid, doc.data()!);
      }
    } catch (_) {}
    return null;
  }

  static final List<Guide> _demoGuides = [
    Guide(
      id: 'demo-guide-abebe',
      userId: 'demo-guide-abebe',
      name: 'Abebe Kebede',
      email: 'abebe.guide@ethioar.demo',
      phone: '+251911000111',
      bio: 'Licensed Lalibela specialist with deep knowledge of rock-hewn churches and Orthodox heritage.',
      languages: const ['English', 'Amharic', 'Italian'],
      qualifications: const ['MoCT Licensed Guide', 'Heritage Interpretation Certificate'],
      experienceYears: 8,
      price: 1500,
      rating: 4.8,
      reviewCount: 42,
      availability: {
        'Monday': true,
        'Tuesday': true,
        'Wednesday': false,
        'Thursday': true,
        'Friday': true,
        'Saturday': true,
        'Sunday': false,
      },
      status: 'active',
    ),
    Guide(
      id: 'demo-guide-hiwot',
      userId: 'demo-guide-hiwot',
      name: 'Hiwot Tadesse',
      email: 'hiwot.guide@ethioar.demo',
      phone: '+251922000222',
      bio: 'Gondar and Simien Mountains guide. Castles, wildlife, and highland trekking.',
      languages: const ['English', 'Amharic', 'French'],
      qualifications: const ['Wildlife First Aid', 'Mountain Guide Level 2'],
      experienceYears: 6,
      price: 1800,
      rating: 4.9,
      reviewCount: 31,
      availability: {
        'Monday': true,
        'Tuesday': true,
        'Wednesday': true,
        'Thursday': true,
        'Friday': true,
        'Saturday': false,
        'Sunday': false,
      },
      status: 'active',
    ),
  ];

  static final List<TourPackage> _demoTours = [
    TourPackage(
      id: 'demo-tour-lalibela',
      guideId: 'demo-guide-abebe',
      name: 'Lalibela Historical Tour',
      tourType: 'cultural-heritage',
      description: 'Walk the rock-hewn churches with narration covering architecture, liturgy, and local life.',
      durationHours: 5,
      price: 1500,
      attractions: const ['Bete Medhane Alem', 'Bete Maryam', 'Bete Giyorgis'],
      language: 'English',
    ),
    TourPackage(
      id: 'demo-tour-gondar',
      guideId: 'demo-guide-hiwot',
      name: 'Fasil Ghebbi & Gondar Castles',
      tourType: 'cultural-heritage',
      description: 'Royal enclosure, Debre Berhan Selassie, and the story of the Ethiopian highland court.',
      durationHours: 4,
      price: 1800,
      attractions: const ['Fasil Ghebbi', 'Debre Berhan Selassie'],
      language: 'English',
    ),
  ];
}
