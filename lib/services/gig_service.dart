import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gig_model.dart';

class GigService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get Firestore instance
  FirebaseFirestore getFirestore() => _firestore;

  // Add a new gig slot
  Future<Map<String, dynamic>> addGigSlot(GigModel gig) async {
    try {
      // Check for redundancy
      final redundancyResult = await checkGigSlotRedundancy(gig);
      if (!redundancyResult['success']) {
        return redundancyResult;
      }

      // Add the gig slot
      final docRef = await _firestore.collection('gigs').add(gig.toMap());
      return {
        'success': true,
        'message': 'Gig slot added successfully',
        'gigId': docRef.id,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error adding gig slot: $e',
      };
    }
  }

  // Check for redundant gig slots
  Future<Map<String, dynamic>> checkGigSlotRedundancy(GigModel newGig) async {
    try {
      // Get all gigs for the same date
      final querySnapshot = await _firestore
          .collection('gigs')
          .where('date', isEqualTo: newGig.date)
          .get();

      // Check for exact matches
      for (var doc in querySnapshot.docs) {
        final existingGig = GigModel.fromMap(doc.data());
        if (existingGig.location == newGig.location &&
            existingGig.startTime == newGig.startTime &&
            existingGig.endTime == newGig.endTime &&
            existingGig.title == newGig.title) {
          return {
            'success': false,
            'message': 'A gig slot with the same job description already exists at this location, date and time. Try again.',
          };
        }
      }

      // Check for overlapping time slots
      for (var doc in querySnapshot.docs) {
        final existingGig = GigModel.fromMap(doc.data());
        if (existingGig.location == newGig.location) {
          // Convert time strings to DateTime for comparison
          final newStart = DateTime.parse('2024-01-01 ${newGig.startTime}');
          final newEnd = DateTime.parse('2024-01-01 ${newGig.endTime}');
          final existingStart = DateTime.parse('2024-01-01 ${existingGig.startTime}');
          final existingEnd = DateTime.parse('2024-01-01 ${existingGig.endTime}');

          // Check for overlap
          if ((newStart.isBefore(existingEnd) && newEnd.isAfter(existingStart))) {
            return {
              'success': false,
              'message': 'This time slot overlaps with an existing gig at the same location. Try again.',
            };
          }
        }
      }

      return {'success': true};
    } catch (e) {
      return {
        'success': false,
        'message': 'Error checking redundancy: $e',
      };
    }
  }

  // Get all gig slots
  Stream<QuerySnapshot> getGigs() {
    return _firestore.collection('gigs').snapshots();
  }

  // Get gig slots by owner ID
  Stream<QuerySnapshot> getGigsByOwner(String ownerId) {
    return _firestore
        .collection('gigs')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots();
  }

  // Get a specific gig slot by ID
  Future<DocumentSnapshot> getGigById(String gigId) {
    return _firestore.collection('gigs').doc(gigId).get();
  }

  // Update a gig slot
  Future<Map<String, dynamic>> updateGigSlot(String gigId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('gigs').doc(gigId).update(updates);
      return {
        'success': true,
        'message': 'Gig slot updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error updating gig slot: $e',
      };
    }
  }

  // Delete a gig slot
  Future<Map<String, dynamic>> deleteGigSlot(String gigId) async {
    try {
      await _firestore.collection('gigs').doc(gigId).delete();
      return {
        'success': true,
        'message': 'Gig slot deleted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error deleting gig slot: $e',
      };
    }
  }

  // Alias methods for backward compatibility
  Future<String?> createGig(Map<String, dynamic> gigData) async {
    final DocumentReference docRef = await _firestore.collection('gigs').add(gigData);
    return docRef.id;
  }

  Future<void> updateGig(String gigId, Map<String, dynamic> gigData) async {
    await _firestore.collection('gigs').doc(gigId).update(gigData);
  }

  Future<void> deleteGig(String gigId) async {
    await _firestore.collection('gigs').doc(gigId).delete();
  }
} 