import 'package:flutter/material.dart';
import '../services/gig_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'AddGigSlot.dart'; // Import the AddGigSlot page
import 'EditGigSlot.dart'; // Import the EditGigSlot page

class ManageGigSlots extends StatefulWidget {
  final GigService gigService;

  const ManageGigSlots({Key? key, required this.gigService}) : super(key: key);

  @override
  State<ManageGigSlots> createState() => _ManageGigSlotsState();
}

class _ManageGigSlotsState extends State<ManageGigSlots> {
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _deleteGigSlot(String gigId) async {
    String confirmationContent = 'Are you sure you want to delete this slot?';

    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Gig Slot'),
        content: Text(confirmationContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('NO'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('YES'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        await widget.gigService.deleteGig(gigId);
        _showSnackBar('Gig slot deleted successfully!');
      } catch (e) {
        _showSnackBar('Failed to delete gig slot: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workshop Gig Slots'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Gig Slots',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.gigService.getGigs(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No gig slots available.'));
                }

                final gigs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: gigs.length,
                  itemBuilder: (context, index) {
                    var gig = gigs[index].data() as Map<String, dynamic>;
                    String gigId = gigs[index].id;

                    // Safely extract data with default values
                    String title = gig['title'] ?? 'No Title';
                    Timestamp dateTimestamp = gig['date'] ?? Timestamp.now();
                    DateTime date = dateTimestamp.toDate();
                    String formattedDate = DateFormat('MM/dd/yyyy').format(date);
                    String startTime = gig['startTime'] ?? 'N/A';
                    String endTime = gig['endTime'] ?? 'N/A';
                    String description = gig['description'] ?? 'No Description';
                    int foremenNeeded = gig['foremenNeeded'] ?? 0;
                    double remuneration = (gig['remuneration'] ?? 0).toDouble();
                    String location = gig['location'] ?? 'N/A';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.alarm, size: 40, color: Color(0xFF1A237E)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A237E),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(formattedDate, style: const TextStyle(fontSize: 14)),
                                  Text(description, style: const TextStyle(fontSize: 14)),
                                  Text('$foremenNeeded Foremen', style: const TextStyle(fontSize: 14)),
                                  Text('RM ${remuneration.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('$startTime - $endTime', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text(location, style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Color(0xFFFF9800)),
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditGigSlot(
                                              gigService: widget.gigService,
                                              gigId: gigId,
                                              initialData: gig,
                                            ),
                                          ),
                                        );
                                        if (result == true) {
                                          _showSnackBar('Gig slot updated successfully!');
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      onPressed: () => _deleteGigSlot(gigId),
                                    ),
                                  ],
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddGigSlot(gigService: widget.gigService),
                        ),
                      );
                      if (result == true) {
                        _showSnackBar('Gig slot added successfully!');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Add Gig Slot',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 