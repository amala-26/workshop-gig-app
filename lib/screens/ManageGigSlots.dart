import 'package:flutter/material.dart';
import '../services/gig_service.dart';

class ManageGigSlots extends StatefulWidget {
  final GigService gigService;

  const ManageGigSlots({Key? key, required this.gigService}) : super(key: key);

  @override
  State<ManageGigSlots> createState() => _ManageGigSlotsState();
}

class _ManageGigSlotsState extends State<ManageGigSlots> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Gig Slots'),
      ),
      body: const Center(
        child: Text('Manage Gig Slots Screen'),
      ),
    );
  }
} 