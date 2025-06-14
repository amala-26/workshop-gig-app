import 'package:flutter/material.dart';
import '../services/gig_service.dart';

class ManageGigApplication extends StatefulWidget {
  final GigService gigService;

  const ManageGigApplication({Key? key, required this.gigService}) : super(key: key);

  @override
  State<ManageGigApplication> createState() => _ManageGigApplicationState();
}

class _ManageGigApplicationState extends State<ManageGigApplication> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Gig Applications'),
      ),
      body: const Center(
        child: Text('Manage Gig Applications Screen'),
      ),
    );
  }
} 