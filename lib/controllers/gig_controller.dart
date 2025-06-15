import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/gig_service.dart';
import '../models/gig_model.dart';

class GigController {
  final GigService _gigService;

  GigController(this._gigService);

  // Get Firestore instance
  FirebaseFirestore getFirestore() => _gigService.getFirestore();

  // Add a new gig slot
  Future<Map<String, dynamic>> addGigSlot(GigModel gig) async {
    return await _gigService.addGigSlot(gig);
  }

  // Get all gig slots
  Stream<QuerySnapshot> getGigs() {
    return _gigService.getGigs();
  }

  // Get gig slots by owner ID
  Stream<QuerySnapshot> getGigsByOwner(String ownerId) {
    return _gigService.getGigsByOwner(ownerId);
  }

  // Get a specific gig slot by ID
  Future<DocumentSnapshot> getGigById(String gigId) {
    return _gigService.getGigById(gigId);
  }

  // Update a gig slot
  Future<Map<String, dynamic>> updateGigSlot(String gigId, Map<String, dynamic> updates) async {
    return await _gigService.updateGigSlot(gigId, updates);
  }

  // Delete a gig slot
  Future<Map<String, dynamic>> deleteGigSlot(String gigId) async {
    return await _gigService.deleteGigSlot(gigId);
  }
} 