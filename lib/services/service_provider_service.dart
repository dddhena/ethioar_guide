import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_provider.dart';
import '../models/provider_service.dart';
import '../models/reservation.dart';
import '../models/payment.dart';
import 'notification_service.dart';

class ServiceProviderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================================
  // SERVICE PROVIDER BUSINESS PROFILE
  // ==========================================

  /// Register a new service provider business (starts in 'approved' or 'pending' state).
  Future<String> registerServiceProvider(ServiceProvider provider) async {
    final docRef = await _db.collection('service_providers').add(provider.toMap());
    // Also update the user's role to 'provider' in Firestore
    if (provider.userId.isNotEmpty) {
      await _db.collection('users').doc(provider.userId).set({
        'role': 'provider',
        'providerId': docRef.id,
      }, SetOptions(merge: true));
    }
    return docRef.id;
  }

  /// Update existing service provider information.
  Future<void> updateServiceProvider(ServiceProvider provider) async {
    await _db.collection('service_providers').doc(provider.id).update(provider.toMap());
  }

  /// Fetch provider profile for a specific authenticated user.
  Future<ServiceProvider?> getProviderByUserId(String uid) async {
    try {
      final snapshot = await _db
          .collection('service_providers')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return ServiceProvider.fromMap(doc.id, doc.data());
      }
    } catch (_) {}
    return null;
  }

  /// Fetch a single provider by document ID.
  Future<ServiceProvider?> getProviderById(String id) async {
    try {
      final doc = await _db.collection('service_providers').doc(id).get();
      if (doc.exists && doc.data() != null) {
        return ServiceProvider.fromMap(doc.id, doc.data()!);
      }
    } catch (_) {}

    // Check demo providers fallback
    try {
      return _demoProviders.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Fetch all approved service providers for tourists, with optional category/city filtering.
  Future<List<ServiceProvider>> fetchApprovedProviders({
    String? businessType,
    String? city,
  }) async {
    try {
      Query query = _db.collection('service_providers');

      if (businessType != null && businessType.isNotEmpty && businessType.toLowerCase() != 'all') {
        query = query.where('businessType', isEqualTo: businessType.toLowerCase());
      }

      final snapshot = await query.get();
      final list = snapshot.docs
          .map((d) => ServiceProvider.fromMap(d.id, d.data() as Map<String, dynamic>))
          .where((p) => p.isApproved)
          .toList();

      if (list.isNotEmpty) return list;
    } catch (_) {
      // Fall through to demo data
    }

    // Return filtered sample providers for browser testing/offline
    var sample = _demoProviders;
    if (businessType != null && businessType.isNotEmpty && businessType.toLowerCase() != 'all') {
      sample = sample.where((p) => p.businessType.toLowerCase() == businessType.toLowerCase()).toList();
    }
    if (city != null && city.isNotEmpty) {
      sample = sample.where((p) => p.city.toLowerCase().contains(city.toLowerCase())).toList();
    }
    return sample;
  }

  /// Admin: Fetch all providers (pending & approved).
  Future<List<ServiceProvider>> fetchAllProvidersAdmin() async {
    try {
      final snapshot = await _db.collection('service_providers').get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((d) => ServiceProvider.fromMap(d.id, d.data()))
            .toList();
      }
    } catch (_) {}
    return _demoProviders;
  }

  /// Admin: Approve or Reject a service provider.
  Future<void> updateProviderApprovalStatus(String providerId, String status) async {
    await _db.collection('service_providers').doc(providerId).update({
      'approvalStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==========================================
  // SERVICES (Rooms, Dining, Vehicles)
  // ==========================================

  /// Add a service offered by a provider.
  Future<String> addService(ProviderService service) async {
    final docRef = await _db.collection('services').add(service.toMap());
    return docRef.id;
  }

  /// Update an existing service.
  Future<void> updateService(ProviderService service) async {
    await _db.collection('services').doc(service.id).update(service.toMap());
  }

  /// Delete a service.
  Future<void> deleteService(String serviceId) async {
    await _db.collection('services').doc(serviceId).delete();
  }

  /// Fetch all services for a specific provider.
  Future<List<ProviderService>> fetchServicesForProvider(String providerId) async {
    try {
      final snapshot = await _db
          .collection('services')
          .where('providerId', isEqualTo: providerId)
          .get();

      final list = snapshot.docs
          .map((d) => ProviderService.fromMap(d.id, d.data()))
          .toList();

      if (list.isNotEmpty) return list;
    } catch (_) {}

    // Fallback sample services
    return _demoServices.where((s) => s.providerId == providerId).toList();
  }

  /// Stream of services for a provider.
  Stream<List<ProviderService>> getServicesStream(String providerId) {
    return _db
        .collection('services')
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _demoServices.where((s) => s.providerId == providerId).toList();
      }
      return snapshot.docs
          .map((d) => ProviderService.fromMap(d.id, d.data()))
          .toList();
    });
  }

  // ==========================================
  // RESERVATIONS & BOOKINGS
  // ==========================================

  /// Tourist creates a service reservation and optionally links a payment.
  Future<String> createReservation(Reservation reservation) async {
    final docRef = await _db.collection('reservations').add(reservation.toMap());
    final resId = docRef.id;

    // Send in-app notification to the Tourist
    try {
      if (reservation.touristId.isNotEmpty) {
        await NotificationService().sendNotification(
          userId: reservation.touristId,
          title: 'Reservation Placed 🛎️',
          message: 'Your booking request for ${reservation.serviceName.isNotEmpty ? reservation.serviceName : 'Service'} at ${reservation.providerName.isNotEmpty ? reservation.providerName : 'Provider'} has been submitted.',
          type: 'booking_created',
          relatedId: resId,
        );
      }

      // Send in-app notification to the Service Provider
      if (reservation.providerId.isNotEmpty) {
        // Find provider's user account ID if different from providerId
        final provDoc = await _db.collection('service_providers').doc(reservation.providerId).get();
        final provUserId = provDoc.data()?['userId'] as String? ?? reservation.providerId;
        
        await NotificationService().sendNotification(
          userId: provUserId,
          title: 'New Reservation Request! 📅',
          message: '${reservation.touristName.isNotEmpty ? reservation.touristName : 'A tourist'} requested a booking for ${reservation.serviceName.isNotEmpty ? reservation.serviceName : 'Service'}.',
          type: 'booking_created',
          relatedId: resId,
        );
      }
    } catch (_) {}

    return resId;
  }

  /// Record a payment in Firestore and trigger notifications.
  Future<String> createPayment(Payment payment) async {
    final docRef = await _db.collection('payments').add(payment.toMap());
    final paymentId = docRef.id;

    // Notify user of successful payment
    try {
      if (payment.userId.isNotEmpty) {
        await NotificationService().sendNotification(
          userId: payment.userId,
          title: 'Payment Successful 💳',
          message: 'Payment of ${payment.formattedAmount} via ${payment.formattedMethod} (Tx: ${payment.transactionId}) was successful.',
          type: 'payment_success',
          relatedId: payment.bookingId,
        );
      }
    } catch (_) {}

    return paymentId;
  }

  /// Provider confirms, declines, or completes a reservation.
  Future<void> updateReservationStatus(String reservationId, String status) async {
    await _db.collection('reservations').doc(reservationId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Notify the tourist about status change
    try {
      final doc = await _db.collection('reservations').doc(reservationId).get();
      if (doc.exists && doc.data() != null) {
        final r = Reservation.fromMap(doc.id, doc.data()!);
        if (r.touristId.isNotEmpty) {
          final isConf = status == 'confirmed';
          final isDecl = status == 'declined';
          final title = isConf
              ? '🎉 Reservation Confirmed!'
              : isDecl
                  ? '⚠️ Reservation Update'
                  : 'Reservation Status: ${status.toUpperCase()}';
          final msg = isConf
              ? 'Great news! ${r.providerName.isNotEmpty ? r.providerName : 'The provider'} has confirmed your reservation for ${r.serviceName}.'
              : isDecl
                  ? 'Your reservation request for ${r.serviceName} was declined by the provider.'
                  : 'Your reservation is now $status.';
          
          await NotificationService().sendNotification(
            userId: r.touristId,
            title: title,
            message: msg,
            type: isConf ? 'reservation_confirmed' : isDecl ? 'reservation_declined' : 'reservation_update',
            relatedId: reservationId,
          );
        }
      }
    } catch (_) {}
  }

  /// Stream of reservations for a specific provider business or provider user account.
  Stream<List<Reservation>> getProviderReservationsStream(String providerIdOrUserId) {
    if (providerIdOrUserId.isEmpty) return Stream.value([]);

    return _db.collection('reservations').snapshots().asyncMap((snapshot) async {
      final Set<String> targetIds = {providerIdOrUserId};
      try {
        final provDocs = await _db
            .collection('service_providers')
            .where('userId', isEqualTo: providerIdOrUserId)
            .get();
        for (final doc in provDocs.docs) {
          targetIds.add(doc.id);
        }
      } catch (_) {}

      final list = snapshot.docs
          .map((d) => Reservation.fromMap(d.id, d.data()))
          .where((r) => targetIds.contains(r.providerId))
          .toList();

      list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }

  /// Stream of payments for a specific provider business or provider user account.
  Stream<List<Payment>> getProviderPaymentsStream(String providerIdOrUserId) {
    if (providerIdOrUserId.isEmpty) return Stream.value([]);

    return _db.collection('payments').snapshots().asyncMap((snapshot) async {
      final Set<String> targetIds = {providerIdOrUserId};
      try {
        final provDocs = await _db
            .collection('service_providers')
            .where('userId', isEqualTo: providerIdOrUserId)
            .get();
        for (final doc in provDocs.docs) {
          targetIds.add(doc.id);
        }
      } catch (_) {}

      final list = snapshot.docs
          .map((d) => Payment.fromMap(d.id, d.data()))
          .where((p) => targetIds.contains(p.providerId))
          .toList();

      list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }

  /// Stream of payments made by a tourist user.
  Stream<List<Payment>> getTouristPaymentsStream(String userId) {
    return _db
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((d) => Payment.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }

  /// Stream of reservations made by a tourist.
  Stream<List<Reservation>> getTouristReservationsStream(String touristId) {
    return _db
        .collection('reservations')
        .where('touristId', isEqualTo: touristId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((d) => Reservation.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }

  // ==========================================
  // SAMPLE ETHIOPIAN DEMO DATA FOR WEB / OFFLINE
  // ==========================================

  static final List<ServiceProvider> _demoProviders = [
    ServiceProvider(
      id: 'demo-kuriftu-bishoftu',
      userId: 'demo-user-1',
      businessName: 'Kuriftu Resort & Spa',
      businessType: 'hotel',
      description: 'Luxury lakeside resort with private cottages, swimming pool, organic dining, and wellness spa.',
      address: 'Lake Kuriftu, Bishoftu',
      city: 'Bishoftu / Addis Ababa',
      region: 'Oromia',
      latitude: 8.7522,
      longitude: 38.9785,
      phone: '+251 11 433 9000',
      facilities: ['Free WiFi', 'Swimming Pool', 'Spa & Massage', 'Lake View', 'Breakfast Included', 'Airport Transfer'],
      priceRange: r'$$$',
      openingHours: '24/7 Front Desk',
      rating: 4.8,
      reviewCount: 142,
      approvalStatus: 'approved',
    ),
    ServiceProvider(
      id: 'demo-maribela-lalibela',
      userId: 'demo-user-2',
      businessName: 'Maribela Hotel Lalibela',
      businessType: 'hotel',
      description: 'Breathtaking mountain-view hotel located 5 minutes from the UNESCO Lalibela Rock-Hewn Churches.',
      address: 'Lalibela Mountain Ridge',
      city: 'Lalibela',
      region: 'Amhara',
      latitude: 12.0345,
      longitude: 39.0490,
      phone: '+251 33 336 0038',
      facilities: ['Free WiFi', 'Mountain View', 'Restaurant & Bar', 'Tour Guides', 'Airport Shuttle', 'Free Breakfast'],
      priceRange: r'$$',
      openingHours: '24/7',
      rating: 4.9,
      reviewCount: 98,
      approvalStatus: 'approved',
    ),
    ServiceProvider(
      id: 'demo-yod-abyssinia',
      userId: 'demo-user-3',
      businessName: 'Yod Abyssinia Cultural Restaurant',
      businessType: 'restaurant',
      description: 'Authentic Ethiopian cultural dining with live traditional music, dance shows, and traditional coffee ceremonies.',
      address: 'Bole Medhanialem, Addis Ababa',
      city: 'Addis Ababa',
      region: 'Addis Ababa',
      latitude: 8.9986,
      longitude: 38.7892,
      phone: '+251 11 661 2179',
      facilities: ['Live Cultural Music', 'Vegetarian/Fasting Menu', 'Traditional Coffee', 'Group Seating', 'Parking'],
      priceRange: r'$$',
      openingHours: '12:00 PM - 11:30 PM',
      rating: 4.7,
      reviewCount: 310,
      approvalStatus: 'approved',
    ),
    ServiceProvider(
      id: 'demo-ethiotour-transport',
      userId: 'demo-user-4',
      businessName: 'EthioTour Transport & Van Hire',
      businessType: 'transport',
      description: 'Reliable 4WD land cruisers, modern tourist minivans, and airport pickup services across Ethiopia.',
      address: 'Bole Airport Road, Addis Ababa',
      city: 'Addis Ababa',
      region: 'Addis Ababa',
      latitude: 9.0054,
      longitude: 38.7750,
      phone: '+251 91 123 4567',
      facilities: ['4WD Land Cruisers', 'AC Minivans', 'English Speaking Drivers', 'Airport Pickup', 'Luggage Assistance'],
      priceRange: r'$$',
      openingHours: '6:00 AM - 10:00 PM',
      rating: 4.8,
      reviewCount: 76,
      approvalStatus: 'approved',
    ),
  ];

  static final List<ProviderService> _demoServices = [
    ProviderService(
      id: 'srv-k1',
      providerId: 'demo-kuriftu-bishoftu',
      name: 'Executive Lakefront Presidential Suite',
      serviceType: 'room',
      description: 'King-size bed, private wooden balcony overlooking Lake Kuriftu, jacuzzi bath, and complimentary wine.',
      price: 9500.0,
      capacity: 2,
      isAvailable: true,
    ),
    ProviderService(
      id: 'srv-k2',
      providerId: 'demo-kuriftu-bishoftu',
      name: 'Deluxe Garden Cottage',
      serviceType: 'room',
      description: 'Spacious cottage amidst lush botanical gardens with rain shower and fireplace.',
      price: 6500.0,
      capacity: 2,
      isAvailable: true,
    ),
    ProviderService(
      id: 'srv-m1',
      providerId: 'demo-maribela-lalibela',
      name: 'Panoramic Valley View Deluxe Room',
      serviceType: 'room',
      description: 'Private balcony facing the Lalibela valley with sunset views, luxury en-suite bathroom, and heated blankets.',
      price: 4800.0,
      capacity: 2,
      isAvailable: true,
    ),
    ProviderService(
      id: 'srv-y1',
      providerId: 'demo-yod-abyssinia',
      name: 'Cultural Feast & Dance Night (VIP Table)',
      serviceType: 'dining',
      description: 'Prime front-row table for traditional dance show, mixed Beyaynetu / Tibs feast, and Tej honey wine.',
      price: 1800.0,
      capacity: 4,
      isAvailable: true,
    ),
    ProviderService(
      id: 'srv-t1',
      providerId: 'demo-ethiotour-transport',
      name: 'Airport VIP Transfer (Bole International Airport)',
      serviceType: 'vehicle',
      description: 'Dedicated greeting at terminal, luggage handling, and transfer to any hotel in Addis Ababa.',
      price: 1200.0,
      capacity: 4,
      isAvailable: true,
    ),
    ProviderService(
      id: 'srv-t2',
      providerId: 'demo-ethiotour-transport',
      name: 'Full Day 4WD Land Cruiser with Driver',
      serviceType: 'vehicle',
      description: 'Rugged luxury Land Cruiser with experienced driver for regional trips (Debre Libanos, Wenchi, etc.).',
      price: 8500.0,
      capacity: 5,
      isAvailable: true,
    ),
  ];
}
