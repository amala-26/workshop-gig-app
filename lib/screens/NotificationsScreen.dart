import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

/// A widget that displays a list of notifications for the current user.
/// Notifications can be of different types (application status, gig updates, new applications)
/// and are displayed with appropriate icons and colors based on their type and status.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  String? _currentUserId;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      _currentUserId = _currentUser!.uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator if user ID is not yet available
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationService.getNotificationsForUser(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No new notifications.'));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final Map<String, dynamic> data = notification.data() as Map<String, dynamic>;
              final String type = data['type'] ?? 'General';
              final String message = data['message'] ?? 'No message';
              final Timestamp timestamp = data['timestamp'] ?? Timestamp.now();
              final bool isRead = data['isRead'] ?? false;
              final DateTime notificationTime = timestamp.toDate();
              final String formattedTime = DateFormat('MMM dd, HH:mm').format(notificationTime);

              IconData icon = Icons.info_outline;
              Color iconColor = Colors.grey;
              String timeAgo = _getTimeAgo(notificationTime);

              // Set icon and color based on notification type and status
              if (type == 'application_status') {
                final String status = data['status'] ?? '';
                if (status == 'Approved') {
                  icon = Icons.check_circle_outline;
                  iconColor = Colors.green;
                } else if (status == 'Rejected') {
                  icon = Icons.cancel_outlined;
                  iconColor = Colors.red;
                } else if (status == 'Cancelled') {
                  icon = Icons.highlight_off;
                  iconColor = Colors.grey;
                }
              } else if (type == 'gig_update') {
                final String action = data['action'] ?? '';
                if (action == 'added') {
                  icon = Icons.event_available;
                  iconColor = Colors.blue;
                } else if (action == 'edited') {
                  icon = Icons.edit_note;
                  iconColor = Colors.orange;
                } else if (action == 'deleted') {
                  icon = Icons.event_busy;
                  iconColor = Colors.red;
                }
              } else if (type == 'new_application') {
                icon = Icons.person_add;
                iconColor = Colors.purple;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                color: isRead ? Colors.white : Colors.blue.shade50,
                child: ListTile(
                  leading: Icon(icon, color: iconColor, size: 30),
                  title: Text(message),
                  subtitle: Text(timeAgo),
                  trailing: Text(formattedTime, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  onTap: () {
                    if (!isRead) {
                      _notificationService.markNotificationAsRead(notification.id);
                    }
                    // Optionally navigate to a detailed view related to the notification
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Calculates and returns a human-readable time difference string
  /// @param dateTime The DateTime to calculate the difference from
  /// @return A string representing how long ago the time was (e.g., "2 hours ago")
  String _getTimeAgo(DateTime dateTime) {
    final Duration diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) {
      return '${diff.inDays} days ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hours ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
} 