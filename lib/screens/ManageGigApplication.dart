import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/gig_service.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';

/// A widget that allows workshop owners to manage applications for their gigs.
/// This includes viewing applications and approving/rejecting them.
class ManageGigApplication extends StatefulWidget {
  final GigService gigService;

  const ManageGigApplication({Key? key, required this.gigService}) : super(key: key);

  @override
  State<ManageGigApplication> createState() => _ManageGigApplicationState();
}

class _ManageGigApplicationState extends State<ManageGigApplication> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  String? _currentOwnerId;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  /// Retrieves the current authenticated user and sets the owner ID
  void _getCurrentUser() {
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      _currentOwnerId = _currentUser!.uid;
      setState(() {}); // Trigger rebuild to show data
    }
  }

  /// Fetches foreman names from Firestore for a list of foreman IDs
  /// @param foremanIds List of foreman IDs to fetch names for
  /// @return Map of foreman IDs to their names
  Future<Map<String, String>> _fetchForemanNames(List<String> foremanIds) async {
    Map<String, String> foremanNames = {};
    if (foremanIds.isEmpty) return foremanNames;

    // Firestore 'whereIn' query can take up to 10 elements
    final chunks = [];
    for (var i = 0; i < foremanIds.length; i += 10) {
      chunks.add(foremanIds.sublist(i, i + 10 > foremanIds.length ? foremanIds.length : i + 10));
    }

    for (var chunk in chunks) {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('foremen')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (var doc in snapshot.docs) {
        foremanNames[doc.id] = doc['name'] ?? 'Unknown Foreman';
      }
    }
    return foremanNames;
  }

  /// Fetches gig details from Firestore for a list of gig IDs
  /// @param gigIds List of gig IDs to fetch details for
  /// @return Map of gig IDs to their details
  Future<Map<String, Map<String, dynamic>>> _fetchGigDetails(List<String> gigIds) async {
    Map<String, Map<String, dynamic>> gigDetails = {};
    if (gigIds.isEmpty) return gigDetails;

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

  /// Updates the status of a gig application and handles related notifications
  /// @param applicationId ID of the application to update
  /// @param status New status to set (Approved/Rejected/Cancelled)
  /// @param foremanId ID of the foreman who applied
  /// @param gigId ID of the gig being applied for
  Future<void> _updateApplicationStatus(String applicationId, String status, String foremanId, String gigId) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final applicationRef = FirebaseFirestore.instance.collection('gigApplications').doc(applicationId);
        final gigRef = FirebaseFirestore.instance.collection('gigs').doc(gigId);

        final applicationSnapshot = await transaction.get(applicationRef);
        final gigSnapshot = await transaction.get(gigRef);

        if (!applicationSnapshot.exists || !gigSnapshot.exists) {
          throw Exception('Application or Gig not found.');
        }

        final String oldStatus = applicationSnapshot['status'] ?? 'Pending';
        final Map<String, dynamic> gigData = gigSnapshot.data() as Map<String, dynamic>;
        
        // Safely get foremenAssigned with a default of 0
        int currentForemenAssigned = 0;
        if (gigData.containsKey('foremenAssigned')) {
          final foremenAssigned = gigData['foremenAssigned'];
          if (foremenAssigned is num) {
            currentForemenAssigned = foremenAssigned.toInt();
          }
        }
        
        // Safely get foremenNeeded with a default of 1
        int foremenNeeded = 1;
        if (gigData.containsKey('foremenNeeded')) {
          final foremenNeededValue = gigData['foremenNeeded'];
          if (foremenNeededValue is num) {
            foremenNeeded = foremenNeededValue.toInt();
          }
        }

        int newForemenAssigned = currentForemenAssigned;
        print('Before update: Gig ID: $gigId, Status: $status, currentForemenAssigned: $currentForemenAssigned');

        // Update foremen count based on status change
        if (status == 'Approved') {
          if (oldStatus != 'Approved') {
            // Only increment if it wasn't already approved
            if (currentForemenAssigned < foremenNeeded) {
              newForemenAssigned++;
            } else {
              throw Exception('Gig slot already has enough foremen.');
            }
          }
        } else if (status == 'Rejected' || status == 'Cancelled') {
          if (oldStatus == 'Approved') {
            // Only decrement if it was previously approved
            if (newForemenAssigned > 0) {
              newForemenAssigned--;
            }
          }
        }

        // Update application status
        transaction.update(applicationRef, {'status': status});

        // Update foremenAssigned count in gig
        transaction.update(gigRef, {'foremenAssigned': newForemenAssigned});
        print('After update: Gig ID: $gigId, newForemenAssigned: $newForemenAssigned');

        // Send notification to foreman about application status update
        final String gigTitle = gigData['title'] ?? 'Unknown Gig';
        final Timestamp gigDate = gigData['date'] as Timestamp;

        print('Attempting to send application status notification to foreman: $foremanId');
        print('Status: $status, Gig Title: $gigTitle, Gig Date: $gigDate');
        await _notificationService.addNotification(
          type: 'application_status',
          recipientId: foremanId,
          senderId: _currentOwnerId,
          gigId: gigId,
          applicationId: applicationId,
          message: 'Your application for the gig on ${DateFormat('MMM dd').format(gigDate.toDate())} was $status.',
          status: status,
          gigTitle: gigTitle,
          gigDate: gigDate,
        );
        print('Application status notification sent successfully (if no error thrown).');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Application $status successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating application status: $e'); // Add logging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to $status application: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator if owner ID is not yet available
    if (_currentOwnerId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Gig Applications')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Gig Applications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('gigs')
            .where('ownerId', isEqualTo: _currentOwnerId)
            .snapshots(),
        builder: (context, gigSnapshot) {
          if (gigSnapshot.hasError) {
            return Center(child: Text('Error: ${gigSnapshot.error}'));
          }
          if (gigSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!gigSnapshot.hasData || gigSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No gigs posted by you.'));
          }

          final List<String> ownerGigIds = gigSnapshot.data!.docs.map((doc) => doc.id).toList();

          if (ownerGigIds.isEmpty) {
            return const Center(child: Text('No gigs posted by you.'));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('gigApplications')
                .where('gigId', whereIn: ownerGigIds) // Filter by owner's gigs
                .snapshots(),
            builder: (context, applicationSnapshot) {
              if (applicationSnapshot.hasError) {
                return Center(child: Text('Error: ${applicationSnapshot.error}'));
              }
              if (applicationSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!applicationSnapshot.hasData || applicationSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No applications for your gigs yet.'));
              }

              final applications = applicationSnapshot.data!.docs;
              final List<String> foremanIds = applications.map((doc) => doc['foremanId'] as String).toList();
              final List<String> uniqueForemanIds = foremanIds.toSet().toList(); // Get unique IDs
              final List<String> gigIdsInApplications = applications.map((doc) => doc['gigId'] as String).toList();
              final List<String> uniqueGigIdsInApplications = gigIdsInApplications.toSet().toList();

              return FutureBuilder<Map<String, String>>(
                future: _fetchForemanNames(uniqueForemanIds),
                builder: (context, foremanNamesSnapshot) {
                  if (foremanNamesSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (foremanNamesSnapshot.hasError) {
                    return Center(child: Text('Error loading foreman names: ${foremanNamesSnapshot.error}'));
                  }
                  final Map<String, String> foremanNames = foremanNamesSnapshot.data ?? {};

                  return FutureBuilder<Map<String, Map<String, dynamic>>>(
                    future: _fetchGigDetails(uniqueGigIdsInApplications),
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
                          final String foremanId = app['foremanId'];
                          final String status = app['status'] ?? 'Pending';
                          final String foremanName = foremanNames[foremanId] ?? 'Unknown Foreman';
                          final Map<String, dynamic>? gig = gigDetails[gigId];
                          final String gigTitle = gig?['title'] ?? 'Unknown Gig';
                          final String gigLocation = gig?['location'] ?? 'Unknown Location';
                          final String gigDate = (gig?['date'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? ''; // Basic date format

                          // Set status color based on application status
                          Color statusColor = Colors.grey;
                          if (status == 'Pending') {
                            statusColor = Colors.orange;
                          } else if (status == 'Approved') {
                            statusColor = Colors.green;
                          } else if (status == 'Rejected') {
                            statusColor = Colors.red;
                          }

                          return Card(
                            margin: const EdgeInsets.all(8.0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gig: $gigTitle',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text('Foreman: $foremanName'),
                                  Text('Location: $gigLocation'),
                                  Text('Date: $gigDate'),
                                  Text('Foremen: ${gig?['foremenAssigned'] ?? 0} / ${gig?['foremenNeeded'] ?? 0}'),
                                  Row(
                                    children: [
                                      const Text('Status: '),
                                      Chip(
                                        label: Text(status),
                                        backgroundColor: statusColor,
                                        labelStyle: const TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  if (status == 'Pending')
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () => _updateApplicationStatus(applicationId, 'Approved', foremanId, gigId),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                          child: const Text('Approve', style: TextStyle(color: Colors.white)),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () => _updateApplicationStatus(applicationId, 'Rejected', foremanId, gigId),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          child: const Text('Reject', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
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
              );
            },
          );
        },
      ),
    );
  }
} 