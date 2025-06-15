import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addNotification({
    required String type,
    required String recipientId,
    String? senderId,
    String? gigId,
    String? applicationId,
    required String message,
    String? status, // For application status (Approved, Rejected, Cancelled)
    String? action, // For gig slot actions (added, edited, deleted)
    String? foremanName, // For owner notifications
    String? gigTitle, // For general context
    Timestamp? gigDate, // For general context
  }) async {
    await _firestore.collection('notifications').add({
      'type': type,
      'recipientId': recipientId,
      'senderId': senderId,
      'gigId': gigId,
      'applicationId': applicationId,
      'message': message,
      'timestamp': Timestamp.now(),
      'isRead': false,
      'status': status,
      'action': action,
      'foremanName': foremanName,
      'gigTitle': gigTitle,
      'gigDate': gigDate,
    });
  }

  Stream<QuerySnapshot> getNotificationsForUser(String userId) {
    return _firestore.collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }
} 