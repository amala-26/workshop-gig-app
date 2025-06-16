// ignore_for_file: unused_element, unnecessary_cast

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

/// A widget that displays a list of gigs that the current foreman has applied for.
/// Shows application status, gig details, and allows cancellation of applications
/// with appropriate time restrictions.
class AppliedGigList extends StatefulWidget {
  const AppliedGigList({Key? key}) : super(key: key);

  @override
  State<AppliedGigList> createState() => _AppliedGigListState();
}

class _AppliedGigListState extends State<AppliedGigList> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  String? _currentForemanId;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      _currentForemanId = _currentUser!.uid;
    }
  }

  /// Fetches gig details from Firestore for a list of gig IDs
  /// @param gigIds List of gig IDs to fetch details for
  /// @return Map of gig IDs to their details
  Future<Map<String, Map<String, dynamic>>> _fetchGigDetails(List<String> gigIds) async {
    Map<String, Map<String, dynamic>> gigDetails = {};
    if (gigIds.isEmpty) return gigDetails;

    // Split gigIds into chunks of 10 to comply with Firestore's whereIn limit
    final chunks = [];
    for (var i = 0; i < gigIds.length; i += 10) {
      chunks.add(gigIds.sublist(i, i + 10 > gigIds.length ? gigIds.length : i + 10));
    }

    for (var chunk in chunks) {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('gigs')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (var doc in snapshot.docs) {
        gigDetails[doc.id] = doc.data() as Map<String, dynamic>;
      }
    }
    return gigDetails;
  }

  /// Handles the selection of an applied gig
  /// @param gigID The ID of the selected gig
  void _selectAppliedGig(String gigID) {
    print('Selected applied gig with ID: $gigID');
  }

  /// Initiates the cancellation process for a gig application
  /// Checks time restrictions before allowing cancellation
  /// @param gigApplication Map containing application details
  void _cancelApplication(Map<String, dynamic> gigApplication) async {
    final String applicationId = gigApplication['id'];
    final DateTime? gigStartTime = gigApplication['gigStartTimeForCancellation'];
    final String gigId = gigApplication['gigId'];

    if (gigStartTime == null) {
      _showCancellationNotApplicableDialog('Invalid gig start time.');
      return;
    }

    final DateTime now = DateTime.now();
    final Duration timeUntilGig = gigStartTime.difference(now);

    // Only allow cancellation if more than 24 hours before gig start
    if (timeUntilGig.inHours > 24) {
      _showCancelConfirmationDialog(applicationId, gigId);
    } else {
      _showCancellationNotApplicableDialog(
          'Cancellation is not allowed within 24 hours of the gig start time. Contact the workshop owner for assistance.');
    }
  }

  /// Shows a confirmation dialog before cancelling an application
  /// @param applicationId The ID of the application to cancel
  /// @param gigId The ID of the associated gig
  void _showCancelConfirmationDialog(String applicationId, String gigId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Application'),
          content: const Text('Are you sure you want to cancel this application?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Yes'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _performCancellation(applicationId, gigId);
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Performs the actual cancellation of a gig application
  /// Updates application status and notifies the workshop owner
  /// @param applicationId The ID of the application to cancel
  /// @param gigId The ID of the associated gig
  Future<void> _performCancellation(String applicationId, String gigId) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final applicationRef = FirebaseFirestore.instance.collection('gigApplications').doc(applicationId);
        final gigRef = FirebaseFirestore.instance.collection('gigs').doc(gigId);

        final applicationSnapshot = await transaction.get(applicationRef);
        final gigSnapshot = await transaction.get(gigRef);

        if (!applicationSnapshot.exists || !gigSnapshot.exists) {
          throw Exception('Application or Gig not found.');
        }

        // Update foremen count if application was approved
        final String oldStatus = applicationSnapshot['status'] ?? 'Pending';
        final Map<String, dynamic>? gigData = gigSnapshot.data() as Map<String, dynamic>?;
        int currentForemenAssigned = (gigData?['foremenAssigned'] as num?)?.toInt() ?? 0;

        if (oldStatus == 'Approved') {
          if (currentForemenAssigned > 0) {
            currentForemenAssigned--;
          }
        }

        // Update application status and foremen count
        transaction.update(applicationRef, {'status': 'Cancelled'});
        transaction.update(gigRef, {'foremenAssigned': currentForemenAssigned});

        // Send notification to workshop owner
        final String gigTitle = gigData?['title'] ?? 'Unknown Gig';
        final Timestamp gigDate = gigData?['date'] as Timestamp? ?? Timestamp.now();
        final String ownerId = gigData?['ownerId'] ?? '';

        if (ownerId.isNotEmpty) {
          await _notificationService.addNotification(
            type: 'application_status',
            recipientId: ownerId,
            senderId: _currentForemanId,
            gigId: gigId,
            applicationId: applicationId,
            message: '${_currentUser?.displayName ?? 'A foreman'} cancelled their application for "$gigTitle" gig on ${DateFormat('MMM dd').format(gigDate.toDate())}.',
            status: 'Cancelled',
            gigTitle: gigTitle,
            gigDate: gigDate,
          );
        }
      });

      _showCancellationSuccessDialog();
    } catch (e) {
      _showSnackBar('Failed to cancel application: $e', isError: true);
    }
  }

  /// Shows a success dialog after successful cancellation
  void _showCancellationSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancellation Confirmed'),
          content: const Text('Your application has been cancelled.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Shows a dialog when cancellation is not allowed
  /// @param message The reason why cancellation is not allowed
  void _showCancellationNotApplicableDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancellation Not Allowed'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Displays a snackbar message with optional error styling
  /// @param message The message to display
  /// @param isError If true, the snackbar will be styled as an error (red background)
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  /// Returns the appropriate color for different application statuses
  /// @param status The application status
  /// @return Color corresponding to the status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Cancelled':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  /// Builds a row of information with an icon and text
  /// @param icon The icon to display
  /// @param text The text to display
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentForemanId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gigs Applied')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gigs Applied'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('gigApplications')
            .where('foremanId', isEqualTo: _currentForemanId)
            .snapshots(),
        builder: (context, applicationSnapshot) {
          if (applicationSnapshot.hasError) {
            return Center(child: Text('Error: ${applicationSnapshot.error}'));
          }
          if (applicationSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!applicationSnapshot.hasData || applicationSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text('You have not applied for any gigs yet.'));
          }

          final applications = applicationSnapshot.data!.docs;
          final List<String> gigIds = applications.map((doc) => doc['gigId'] as String).toList();

          return FutureBuilder<Map<String, Map<String, dynamic>>>(
            future: _fetchGigDetails(gigIds),
            builder: (context, gigDetailsSnapshot) {
              if (gigDetailsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (gigDetailsSnapshot.hasError) {
                return Center(child: Text('Error loading gig details: ${gigDetailsSnapshot.error}'));
              }
              final Map<String, Map<String, dynamic>> gigDetails = gigDetailsSnapshot.data ?? {};

              return ListView.builder(
                itemCount: applications.length,
                itemBuilder: (context, index) {
                  final app = applications[index];
                  final String applicationId = app.id;
                  final String gigId = app['gigId'];
                  final String status = app['status'] ?? 'Pending';
                  final Map<String, dynamic>? gig = gigDetails[gigId];

                  // Extract and format gig details
                  String gigTitle = gig?['title'] ?? 'Unknown Gig';
                  String gigLocation = gig?['location'] ?? 'Unknown Location';
                  String formattedDate = '';
                  String formattedTime = '';

                  if (gig?['date'] != null) {
                    Timestamp dateTimestamp = gig!['date'] as Timestamp;
                    DateTime gigDate = dateTimestamp.toDate();
                    formattedDate = DateFormat('MMMM dd, yyyy').format(gigDate);
                  }

                  String startTime = gig?['startTime'] ?? '';
                  String endTime = gig?['endTime'] ?? '';
                  if (startTime.isNotEmpty && endTime.isNotEmpty) {
                    formattedTime = '$startTime - $endTime';
                  } else if (startTime.isNotEmpty) {
                    formattedTime = startTime;
                  } else if (endTime.isNotEmpty) {
                    formattedTime = endTime;
                  }

                  // Calculate gig start time for cancellation check
                  final DateTime? gigStartTimeForCancellation = gig?['date'] != null && gig?['startTime'] != null
                      ? DateTime(
                          (gig!['date'] as Timestamp).toDate().year,
                          (gig['date'] as Timestamp).toDate().month,
                          (gig['date'] as Timestamp).toDate().day,
                          int.parse(gig['startTime'].split(':')[0]),
                          int.parse(gig['startTime'].split(':')[1]),
                        )
                      : null;

                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  gigTitle,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  status,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.location_on, gigLocation),
                          _buildInfoRow(Icons.calendar_today, formattedDate),
                          _buildInfoRow(Icons.access_time, formattedTime),
                          const SizedBox(height: 16),
                          if (status == 'Pending' || status == 'Approved')
                            Center(
                              child: ElevatedButton(
                                onPressed: () => _cancelApplication({
                                  'id': applicationId,
                                  'gigStartTimeForCancellation': gigStartTimeForCancellation,
                                  'gigId': gigId,
                                }),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Cancel Application'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
} 