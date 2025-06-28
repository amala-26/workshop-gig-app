import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart'; // Import NotificationService

/// A widget that displays available gigs and allows foremen to apply for them.
/// Includes filtering capabilities for location, date, time, and job type.
/// Handles application submission with validation for overlapping schedules and capacity.
class GigApplicationInterface extends StatefulWidget {
  const GigApplicationInterface({Key? key}) : super(key: key);

  @override
  State<GigApplicationInterface> createState() => _GigApplicationInterfaceState();
}

class _GigApplicationInterfaceState extends State<GigApplicationInterface> {
  // List<dynamic> availableSlots = []; // This will now be managed by StreamBuilder
  String? _selectedLocation;
  DateTime? _selectedFilterDate;
  String? _selectedFilterTime;
  String? _selectedJobType;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  final NotificationService _notificationService = NotificationService(); // Instantiate NotificationService

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    // _displaySlots(); // Removed as StreamBuilder will handle initial load and updates
  }

  /// Retrieves the current authenticated user
  void _getCurrentUser() {
    _currentUser = _auth.currentUser;
  }

  /// Checks the application status for a specific gig and foreman
  /// @param gigId The ID of the gig to check
  /// @param foremanId The ID of the foreman
  /// @return The application status or null if no application exists
  Future<String?> _getApplicationStatus(String gigId, String foremanId) async {
    try {
      final QuerySnapshot existingApplications = await FirebaseFirestore.instance
          .collection('gigApplications')
          .where('foremanId', isEqualTo: foremanId)
          .where('gigId', isEqualTo: gigId)
          .get();

      if (existingApplications.docs.isNotEmpty) {
        return existingApplications.docs.first['status'] as String?;
      }
      return null;
    } catch (e) {
      print('Error checking application status: $e');
      return null;
    }
  }

  /// Gets the appropriate button text and state based on application status
  /// @param status The application status
  /// @return Map containing button text and whether it's enabled
  Map<String, dynamic> _getButtonState(String? status) {
    if (status == null) {
      return {'text': 'Apply', 'enabled': true, 'color': Colors.blue};
    } else if (status == 'Pending') {
      return {'text': 'Apply', 'enabled': true, 'color': Colors.blue};
    } else if (status == 'Approved') {
      return {'text': 'Apply', 'enabled': true, 'color': Colors.blue};
    } else if (status == 'Rejected') {
      return {'text': 'Apply', 'enabled': true, 'color': Colors.blue};
    } else if (status == 'Cancelled') {
      return {'text': 'Apply', 'enabled': true, 'color': Colors.blue};
    }
    return {'text': 'Apply', 'enabled': true, 'color': Colors.blue};
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Resets all active filters to their default state
  void _resetFilters() {
    setState(() {
      _selectedLocation = null;
      _selectedFilterDate = null;
      _selectedFilterTime = null;
      _selectedJobType = null;
    });
    // _displaySlots(); // Not needed with StreamBuilder
  }

  // _displaySlots method will be removed/refactored into StreamBuilder

  /// Shows a confirmation dialog before submitting the application
  /// @param gigID The ID of the gig to apply for
  /// @param applicationStatus The current application status (null for new application)
  void _showConfirmApplicationDialog(String gigID, [String? applicationStatus]) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Application'),
          content: const Text('Are you sure you want to apply for this slot?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                _applyForGig(gigID);
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

  /// Handles the gig application process with validation and database updates
  /// @param gigId The ID of the gig to apply for
  Future<void> _applyForGig(String gigId) async {
    if (_currentUser == null) {
      _showSnackBar('You must be logged in to apply for a gig.', isError: true);
      return;
    }

    final String foremanId = _currentUser!.uid;

    try {
      // 1. Check if the gig exists and is still available
      final DocumentSnapshot gigDoc = await FirebaseFirestore.instance.collection('gigs').doc(gigId).get();
      if (!gigDoc.exists) {
        _showSnackBar('Gig not found.', isError: true);
        return;
      }

      // Check for existing applications - only prevent reapplication if approved
      final QuerySnapshot existingApplications = await FirebaseFirestore.instance
          .collection('gigApplications')
          .where('foremanId', isEqualTo: foremanId)
          .where('gigId', isEqualTo: gigId)
          .get();

      // Check if there's an approved application for this gig
      bool hasApprovedApplication = existingApplications.docs.any((doc) => doc['status'] == 'Approved');
      if (hasApprovedApplication) {
        _showSnackBar('You have already applied for this gig and received approval.', isError: true);
        return;
      }

      // Check if there's a pending application for this gig
      bool hasPendingApplication = existingApplications.docs.any((doc) => doc['status'] == 'Pending');
      if (hasPendingApplication) {
        _showSnackBar('You have already applied for this gig and your application is pending review.', isError: true);
        return;
      }

      final int foremenNeeded = (gigDoc['foremenNeeded'] as num?)?.toInt() ?? 0;
      final Map<String, dynamic>? gigData = gigDoc.data() as Map<String, dynamic>?;
      final int foremenAssigned = (gigData?['foremenAssigned'] as num?)?.toInt() ?? 0; // More robust null check

      // Rule 1: Check if the slot has reached its required number of foremen.
      if (foremenAssigned >= foremenNeeded) {
        _showSlotNotAvailableDialog();
        return;
      }

      // 2. Check for overlapping slots (Rule 2)
      final Timestamp gigDateTimestamp = gigDoc['date'] as Timestamp;
      final DateTime gigStartDate = gigDateTimestamp.toDate();
      final String gigStartTimeStr = gigDoc['startTime'] ?? '';
      final String gigEndTimeStr = gigDoc['endTime'] ?? '';

      final DateTime selectedGigStart = DateTime(
        gigStartDate.year,
        gigStartDate.month,
        gigStartDate.day,
        int.parse(gigStartTimeStr.split(':')[0]),
        int.parse(gigStartTimeStr.split(':')[1]),
      );
      final DateTime selectedGigEnd = DateTime(
        gigStartDate.year,
        gigStartDate.month,
        gigStartDate.day,
        int.parse(gigEndTimeStr.split(':')[0]),
        int.parse(gigEndTimeStr.split(':')[1]),
      );

      final QuerySnapshot approvedApplications = await FirebaseFirestore.instance
          .collection('gigApplications')
          .where('foremanId', isEqualTo: foremanId)
          .where('status', isEqualTo: 'Approved') // Only check against approved gigs
          .get();

      for (var appDoc in approvedApplications.docs) {
        final String existingGigId = appDoc['gigId'];
        if (existingGigId == gigId) continue; // Skip the current gig if already applied and approved

        final DocumentSnapshot existingGigDoc = await FirebaseFirestore.instance.collection('gigs').doc(existingGigId).get();
        if (!existingGigDoc.exists) continue;

        final Timestamp existingGigDateTimestamp = existingGigDoc['date'] as Timestamp;
        final DateTime existingGigDate = existingGigDateTimestamp.toDate();
        final String existingGigStartTimeStr = existingGigDoc['startTime'] ?? '';
        final String existingGigEndTimeStr = existingGigDoc['endTime'] ?? '';

        final DateTime existingGigStart = DateTime(
          existingGigDate.year,
          existingGigDate.month,
          existingGigDate.day,
          int.parse(existingGigStartTimeStr.split(':')[0]),
          int.parse(existingGigStartTimeStr.split(':')[1]),
        );
        final DateTime existingGigEnd = DateTime(
          existingGigDate.year,
          existingGigDate.month,
          existingGigDate.day,
          int.parse(existingGigEndTimeStr.split(':')[0]),
          int.parse(existingGigEndTimeStr.split(':')[1]),
        );

        // Check for overlap
        if (selectedGigStart.isBefore(existingGigEnd) && selectedGigEnd.isAfter(existingGigStart)) {
          _showSnackBar('You already have an approved gig that overlaps with this time slot.', isError: true);
          return;
        }
      }

      // 3. Add the application to Firestore within a transaction
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final applicationRef = FirebaseFirestore.instance.collection('gigApplications').doc();
        final gigRef = FirebaseFirestore.instance.collection('gigs').doc(gigId);

        final gigSnapshotForUpdate = await transaction.get(gigRef);
        final Map<String, dynamic> gigDataForUpdate = gigSnapshotForUpdate.data() as Map<String, dynamic>;
        int currentForemenAssigned = (gigDataForUpdate.containsKey('foremenAssigned') ? gigDataForUpdate['foremenAssigned'] as num? : 0)?.toInt() ?? 0;

        print('Before application: Gig ID: $gigId, currentForemenAssigned: $currentForemenAssigned');

        transaction.set(applicationRef, {
          'foremanId': foremanId,
          'gigId': gigId,
          'status': 'Pending',
          'applicationDate': Timestamp.now(),
        });

        // Functional Requirement: Foreman count should only update upon workshop owner approval.
        // Removed the premature increment of foremenAssigned.
        print('Application submitted for Gig ID: $gigId');

        // Get ownerId and foremanName for notification
        final String ownerId = gigDoc['ownerId'];
        final String gigTitle = gigDoc['title'] ?? 'Unknown Gig';
        final Timestamp gigDate = gigDoc['date'] as Timestamp;

        DocumentSnapshot foremanDoc = await FirebaseFirestore.instance.collection('foremen').doc(foremanId).get();
        String foremanName = foremanDoc['name'] ?? 'A foreman'; // Default name if not found

        // Send notification to workshop owner
        print('Attempting to send new application notification to owner: $ownerId');
        print('Foreman Name: $foremanName, Gig Title: $gigTitle, Gig Date: $gigDate');
        await _notificationService.addNotification(
          type: 'new_application',
          recipientId: ownerId,
          senderId: foremanId,
          gigId: gigId,
          applicationId: applicationRef.id,
          message: '$foremanName applied for "$gigTitle" gig.',
          foremanName: foremanName,
          gigTitle: gigTitle,
          gigDate: gigDate,
        );
        print('New application notification sent successfully (if no error thrown).');
      });

      _showApplicationSubmittedDialog();
      // _displaySlots(); // Refresh list to reflect changes (e.g., if foremenNeeded was reached)
    } catch (e) {
      print('Error applying for gig: $e');
      _showSnackBar('Failed to apply for gig: $e', isError: true);
    }
  }

  /// Shows a success dialog after application submission
  void _showApplicationSubmittedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Application Submitted'),
          content: const Text("Application submitted successfully. You will be notified once it's reviewed."),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                // Optionally refresh the gig list
                // _displaySlots(); // Not needed with StreamBuilder
              },
            ),
          ],
        );
      },
    );
  }

  /// Shows a dialog when the selected gig slot is no longer available
  void _showSlotNotAvailableDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Gig Slot Not Available'),
          content: const Text('The selected slot is no longer available. Please choose another slot.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                // Optionally refresh the gig list
                // _displaySlots(); // Not needed with StreamBuilder
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

  /// Fetches workshop names from Firestore for a list of owner IDs
  /// @param ownerIds List of owner IDs to fetch workshop names for
  /// @return Map of owner IDs to their workshop names
  Future<Map<String, String>> _fetchWorkshopNames(List<String> ownerIds) async {
    Map<String, String> workshopNames = {};
    if (ownerIds.isEmpty) return workshopNames;

    final chunks = [];
    for (var i = 0; i < ownerIds.length; i += 10) {
      chunks.add(ownerIds.sublist(i, i + 10 > ownerIds.length ? ownerIds.length : i + 10));
    }

    for (var chunk in chunks) {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('workshops')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (var doc in snapshot.docs) {
        workshopNames[doc.id] = doc['workshopName'] ?? 'Unknown Workshop';
      }
    }
    return workshopNames;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Available Gigs')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Gigs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetFilters,
            tooltip: 'Reset Filters',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                _buildFilterChip('Location', Icons.location_on, (isSelected) async {
                  print('Location filter clicked. isSelected: $isSelected');
                  if (!isSelected) {
                    setState(() {
                      _selectedLocation = null;
                      print('Location filter cleared: $_selectedLocation');
                    });
                  } else {
                    final String? location = await _showLocationPickerDialog();
                    if (location != null) {
                      setState(() {
                        _selectedLocation = location;
                        print('Location filter applied: $_selectedLocation');
                      });
                    }
                  }
                  // _displaySlots(); // Not needed with StreamBuilder
                }),
                _buildFilterChip('Date', Icons.calendar_today, (isSelected) async {
                  print('Date filter clicked. isSelected: $isSelected');
                  if (!isSelected) {
                    setState(() {
                      _selectedFilterDate = null;
                      print('Date filter cleared: $_selectedFilterDate');
                    });
                  } else {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedFilterDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedFilterDate = picked;
                        print('Date filter applied: $_selectedFilterDate');
                      });
                    }
                  }
                  // _displaySlots(); // Not needed with StreamBuilder
                }),
                _buildFilterChip('Time', Icons.access_time, (isSelected) async {
                  print('Time filter clicked. isSelected: $isSelected');
                  if (!isSelected) {
                    setState(() {
                      _selectedFilterTime = null;
                      print('Time filter cleared: $_selectedFilterTime');
                    });
                  } else {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedFilterTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                        print('Time filter applied: $_selectedFilterTime');
                      });
                    }
                  }
                  // _displaySlots(); // Not needed with StreamBuilder
                }),
                _buildFilterChip('Job Type', Icons.work, (isSelected) async {
                  print('Job Type filter clicked. isSelected: $isSelected');
                  if (!isSelected) {
                    setState(() {
                      _selectedJobType = null;
                      print('Job Type filter cleared: $_selectedJobType');
                    });
                  } else {
                    final String? jobType = await _showJobTypePickerDialog();
                    if (jobType != null) {
                      setState(() {
                        _selectedJobType = jobType;
                        print('Job Type filter applied: $_selectedJobType');
                      });
                    }
                  }
                  // _displaySlots(); // Not needed with StreamBuilder
                }),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('gigs').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No available gigs at the moment.'));
                }

                List<QueryDocumentSnapshot> gigs = snapshot.data!.docs;

                // Apply filters in-memory after fetching all gigs from the stream
                if (_selectedLocation != null && _selectedLocation!.isNotEmpty) {
                  gigs = gigs.where((gig) => gig['location'] == _selectedLocation).toList();
                }

                if (_selectedFilterDate != null) {
                  gigs = gigs.where((gig) {
                    Timestamp dateTimestamp = gig['date'] as Timestamp;
                    DateTime gigDate = dateTimestamp.toDate();
                    return gigDate.year == _selectedFilterDate!.year &&
                           gigDate.month == _selectedFilterDate!.month &&
                           gigDate.day == _selectedFilterDate!.day;
                  }).toList();
                }

                if (_selectedFilterTime != null && _selectedFilterTime!.isNotEmpty) {
                  gigs = gigs.where((gig) => gig['startTime'] == _selectedFilterTime).toList();
                }

                if (_selectedJobType != null && _selectedJobType!.isNotEmpty) {
                  gigs = gigs.where((gig) => gig['title'] == _selectedJobType).toList();
                }

                // Further filter out gigs where foremenAssigned >= foremenNeeded
                gigs = gigs.where((gig) {
                  final gigData = gig.data() as Map<String, dynamic>;
                  final int foremenNeeded = (gigData['foremenNeeded'] as num?)?.toInt() ?? 0;
                  final int foremenAssigned = (gigData['foremenAssigned'] as num?)?.toInt() ?? 0;
                  
                  // Check if gig is not fully booked
                  if (foremenAssigned >= foremenNeeded) {
                    return false;
                  }
                  
                  // Check if gig is in the future
                  final Timestamp dateTimestamp = gigData['date'] as Timestamp? ?? Timestamp.now();
                  final DateTime gigDate = dateTimestamp.toDate();
                  final DateTime now = DateTime.now();
                  
                  // Compare dates (ignore time for date comparison)
                  final DateTime gigDateOnly = DateTime(gigDate.year, gigDate.month, gigDate.day);
                  final DateTime nowDateOnly = DateTime(now.year, now.month, now.day);
                  
                  // Only show gigs that are today or in the future
                  return gigDateOnly.isAfter(nowDateOnly) || gigDateOnly.isAtSameMomentAs(nowDateOnly);
                }).toList();

                if (gigs.isEmpty) {
                  return const Center(child: Text('No available gigs matching your filters.'));
                }

                return ListView.builder(
                  itemCount: gigs.length,
                  itemBuilder: (context, index) {
                    var gig = gigs[index].data() as Map<String, dynamic>;
                    String gigID = gigs[index].id;

                    // Safely extract and format data
                    String title = gig['title'] ?? 'N/A';
                    double remuneration = (gig['remuneration'] as num?)?.toDouble() ?? 0.0;
                    String location = gig['location'] ?? 'N/A';
                    String ownerId = gig['ownerId'] ?? '';

                    Timestamp dateTimestamp = gig['date'] as Timestamp? ?? Timestamp.now();
                    DateTime gigDate = dateTimestamp.toDate();
                    String formattedDate = DateFormat('MMMM dd, yyyy').format(gigDate);

                    String startTime = gig['startTime'] ?? '';
                    String endTime = gig['endTime'] ?? '';
                    String formattedTime = '';
                    if (startTime.isNotEmpty && endTime.isNotEmpty) {
                      formattedTime = '$startTime - $endTime';
                    } else if (startTime.isNotEmpty) {
                      formattedTime = startTime;
                    } else if (endTime.isNotEmpty) {
                      formattedTime = endTime;
                    }

                    int foremenNeeded = (gig['foremenNeeded'] as num?)?.toInt() ?? 0;
                    int foremenAssigned = (gig['foremenAssigned'] as num?)?.toInt() ?? 0;

                    return FutureBuilder<Map<String, String>>(
                      future: _fetchWorkshopNames([ownerId]),
                      builder: (context, workshopSnapshot) {
                        String workshopName = workshopSnapshot.data?[ownerId] ?? 'Loading...';
                        
                        return FutureBuilder<String?>(
                          future: _currentUser != null ? _getApplicationStatus(gigID, _currentUser!.uid) : Future.value(null),
                          builder: (context, statusSnapshot) {
                            String? applicationStatus = statusSnapshot.data;
                            Map<String, dynamic> buttonState = _getButtonState(applicationStatus);
                            
                            return Card(
                              margin: const EdgeInsets.all(8.0),
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              // Functional Requirement: Display the respective workshop name along with gig details.
                                              Text(
                                                workshopName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Functional Requirement: Display salary details (RM/hr) in the top-right badge.
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: Text(
                                            'RM ${remuneration.toStringAsFixed(2)}/hr',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(Icons.location_on, location),
                                    _buildInfoRow(Icons.calendar_today, formattedDate),
                                    _buildInfoRow(Icons.access_time, formattedTime),
                                    // Functional Requirement: Display foreman count at the bottom of the gig card.
                                    _buildInfoRow(Icons.people, 'Foremen: ${foremenAssigned} / ${foremenNeeded}'),
                                    const SizedBox(height: 16),
                                    // Apply button
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: buttonState['enabled'] ? () => _showConfirmApplicationDialog(gigID, applicationStatus) : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: buttonState['color'],
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          buttonState['text'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a filter chip widget for the filter bar
  /// @param label The label text for the filter chip
  /// @param icon The icon to display on the filter chip
  /// @param onSelected Callback function when the filter is selected/deselected
  Widget _buildFilterChip(String label, IconData icon, Function(bool) onSelected) {
    bool isSelected = false;
    if (label == 'Location') {
      isSelected = _selectedLocation != null;
    } else if (label == 'Date') {
      isSelected = _selectedFilterDate != null;
    } else if (label == 'Time') {
      isSelected = _selectedFilterTime != null;
    } else if (label == 'Job Type') {
      isSelected = _selectedJobType != null;
    }

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        onSelected(selected);
      },
      avatar: Icon(icon),
      selectedColor: const Color(0xFF1A237E),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      checkmarkColor: Colors.white,
    );
  }

  /// Shows a dialog to select a location from available gig locations
  /// @return The selected location or null if cancelled
  Future<String?> _showLocationPickerDialog() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('gigs').get();
    final List<String> locations = snapshot.docs
        .map((doc) => doc['location'] as String)
        .where((location) => location.isNotEmpty)
        .toSet()
        .toList();

    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Location'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: locations.map((location) {
                return ListTile(
                  title: Text(location),
                  onTap: () {
                    Navigator.of(context).pop(location);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  /// Shows a dialog to select a job type from available gig titles
  /// @return The selected job type or null if cancelled
  Future<String?> _showJobTypePickerDialog() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('gigs').get();
    final List<String> jobTypes = snapshot.docs
        .map((doc) => doc['title'] as String)
        .where((title) => title.isNotEmpty)
        .toSet()
        .toList();

    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Job Type'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: jobTypes.map((jobType) {
                return ListTile(
                  title: Text(jobType),
                  onTap: () {
                    Navigator.of(context).pop(jobType);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
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
} 