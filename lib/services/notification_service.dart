import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // In-memory fallback list for demo mode
  final List<AppNotification> _localNotifications = [];
  final StreamController<List<AppNotification>> _localStreamController =
      StreamController<List<AppNotification>>.broadcast();

  /// Send a notification to a specific user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'general',
    String? relatedId,
  }) async {
    try {
      final docRef = _db.collection('notifications').doc();
      final notification = AppNotification(
        id: docRef.id,
        userId: userId,
        title: title,
        message: message,
        type: type,
        relatedId: relatedId,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await docRef.set(notification.toMap());

      // Also add to local cache for instant UI feedback
      _localNotifications.insert(0, notification);
      _localStreamController.add(List.from(_localNotifications));
    } catch (_) {
      // Fallback to local in-memory
      final notification = AppNotification(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: title,
        message: message,
        type: type,
        relatedId: relatedId,
        isRead: false,
        createdAt: DateTime.now(),
      );
      _localNotifications.insert(0, notification);
      _localStreamController.add(List.from(_localNotifications));
    }
  }

  /// Stream of notifications for a specific user
  Stream<List<AppNotification>> getUserNotificationsStream(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        // Return matching local notifications if any
        return _localNotifications.where((n) => n.userId == userId).toList();
      }
      final list = snapshot.docs
          .map((doc) => AppNotification.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return list;
    }).handleError((_) {
      return _localNotifications.where((n) => n.userId == userId).toList();
    });
  }

  /// Stream of unread notification count
  Stream<int> getUnreadCountStream(String userId) {
    return getUserNotificationsStream(userId).map(
      (list) => list.where((n) => !n.isRead).length,
    );
  }

  /// Mark single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).update({'isRead': true});
    } catch (_) {}
    for (int i = 0; i < _localNotifications.length; i++) {
      if (_localNotifications[i].id == notificationId) {
        _localNotifications[i] = AppNotification(
          id: _localNotifications[i].id,
          userId: _localNotifications[i].userId,
          title: _localNotifications[i].title,
          message: _localNotifications[i].message,
          type: _localNotifications[i].type,
          relatedId: _localNotifications[i].relatedId,
          isRead: true,
          createdAt: _localNotifications[i].createdAt,
        );
      }
    }
    _localStreamController.add(List.from(_localNotifications));
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (_) {}

    for (int i = 0; i < _localNotifications.length; i++) {
      if (_localNotifications[i].userId == userId) {
        _localNotifications[i] = AppNotification(
          id: _localNotifications[i].id,
          userId: _localNotifications[i].userId,
          title: _localNotifications[i].title,
          message: _localNotifications[i].message,
          type: _localNotifications[i].type,
          relatedId: _localNotifications[i].relatedId,
          isRead: true,
          createdAt: _localNotifications[i].createdAt,
        );
      }
    }
    _localStreamController.add(List.from(_localNotifications));
  }
}
