import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart'; // Make sure this path is correct
import 'package:flutter/material.dart'; // Added for WidgetsFlutterBinding

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print("✅ Firebase initialized!");

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> sampleGigs = [
    {
      'title': 'Routine Engine Check-Up',
      'description': 'Standard check and maintenance for vehicle engines.',
      'date': Timestamp.fromDate(DateTime(2025, 5, 25)),
      'startTime': DateFormat('HH:mm').format(DateTime(2025, 5, 25, 9, 0)), // 9:00 AM
      'endTime': DateFormat('HH:mm').format(DateTime(2025, 5, 25, 12, 0)), // 12:00 PM
      'foremenNeeded': 3,
      'remuneration': 30.0, // RM 30
      'location': 'Location A',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'title': 'Diesel Engine Diagnostics',
      'description': 'Advanced diagnostics for diesel engine issues.',
      'date': Timestamp.fromDate(DateTime(2025, 5, 25)),
      'startTime': DateFormat('HH:mm').format(DateTime(2025, 5, 25, 13, 0)), // 1:00 PM
      'endTime': DateFormat('HH:mm').format(DateTime(2025, 5, 25, 16, 0)), // 4:00 PM
      'foremenNeeded': 4,
      'remuneration': 40.0, // RM 40
      'location': 'Location B',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'title': 'Tyre Rotation and Alignment',
      'description': 'Rotation and alignment service for all car types.',
      'date': Timestamp.fromDate(DateTime(2025, 6, 1)),
      'startTime': DateFormat('HH:mm').format(DateTime(2025, 6, 1, 10, 0)), // 10:00 AM
      'endTime': DateFormat('HH:mm').format(DateTime(2025, 6, 1, 13, 0)), // 1:00 PM
      'foremenNeeded': 2,
      'remuneration': 25.0, // RM 25
      'location': 'Location C',
      'createdAt': FieldValue.serverTimestamp(),
    },
  ];

  print("Adding sample gig slots...");
  for (var gig in sampleGigs) {
    try {
      await firestore.collection('gigs').add(gig);
      print("Added gig: ${gig['title']}");
    } catch (e) {
      print("Error adding gig ${gig['title']}: $e");
    }
  }
  print("Finished adding sample gig slots.");
} 