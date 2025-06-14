import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Import for TimeOfDay
import 'package:intl/intl.dart'; // Import for DateFormat

class GigService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all gigs
  Stream<QuerySnapshot> getGigs() {
    return _firestore.collection('gigs').snapshots();
  }

  // Get gig by ID
  Future<DocumentSnapshot> getGigById(String gigId) {
    return _firestore.collection('gigs').doc(gigId).get();
  }

  // Create a new gig
  Future<void> createGig(Map<String, dynamic> gigData) {
    return _firestore.collection('gigs').add(gigData);
  }

  // Update a gig
  Future<void> updateGig(String gigId, Map<String, dynamic> gigData) {
    return _firestore.collection('gigs').doc(gigId).update(gigData);
  }

  // Delete a gig
  Future<void> deleteGig(String gigId) {
    return _firestore.collection('gigs').doc(gigId).delete();
  }

  // Check for gig slot redundancy (E1)
  Future<bool> checkGigSlotRedundancy(
      String title,
      String location,
      DateTime date,
      TimeOfDay startTime,
      TimeOfDay endTime,
      ) async {
    // Convert TimeOfDay to a formatted string using 'HH:mm' for unambiguous storage/querying
    final String formattedStartTime = DateFormat('HH:mm').format(DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute));
    final String formattedEndTime = DateFormat('HH:mm').format(DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute));

    final querySnapshot = await _firestore
        .collection('gigs')
        .where('title', isEqualTo: title)
        .where('location', isEqualTo: location)
        .where('date', isEqualTo: Timestamp.fromDate(date))
        .where('startTime', isEqualTo: formattedStartTime)
        .where('endTime', isEqualTo: formattedEndTime)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  // Check if foremen have booked a slot before deletion
  Future<bool> hasBookedForemen(String gigId) async {
    // Assuming a 'applications' collection where foremen book gigs
    final querySnapshot = await _firestore
        .collection('applications')
        .where('gigId', isEqualTo: gigId)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }
} 