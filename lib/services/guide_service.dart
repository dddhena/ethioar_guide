import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/guide.dart';
import '../models/tour_package.dart';
import '../models/booking.dart';
import '../models/user_profile.dart';
import 'notification_service.dart';

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
