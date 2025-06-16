// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class AddRatingForeman extends StatefulWidget {
  final String? serviceName;
  final String? customerName;
  final String? task;
  final String? feedbackComment;
  final int? starRating;
  const AddRatingForeman({Key? key, this.serviceName, this.customerName, this.task, this.feedbackComment, this.starRating}) : super(key: key);

  @override
  State<AddRatingForeman> createState() => _AddRatingForemanState();
}

class _AddRatingForemanState extends State<AddRatingForeman> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _customerNameController;
  late TextEditingController _taskController;
  late TextEditingController _feedbackController;
  int _starRating = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _customerNameController = TextEditingController(text: widget.customerName ?? '');
    _taskController = TextEditingController(text: widget.task ?? '');
    _feedbackController = TextEditingController(text: widget.feedbackComment ?? '');
    _starRating = widget.starRating ?? 0;
  }

  String _generateRatingId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(10, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  void _submitRating() async {
    if (!_formKey.currentState!.validate() || _starRating == 0) return;
    setState(() { _isSubmitting = true; });
    final ratingId = _generateRatingId();
    final now = DateTime.now();
    try {
      await FirebaseFirestore.instance.collection('ratings').doc(ratingId).set({
        'Rating_ID': ratingId,
        'Customer_ID': _customerNameController.text.trim(),
        'Workshop_ID': widget.serviceName ?? '',
        'Star_Rating': _starRating,
        'Feedback_Comment': _feedbackController.text.trim(),
        'Rating_Date': now,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rating submitted!')));
        _formKey.currentState!.reset();
        setState(() { _starRating = 0; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit: $e')));
    } finally {
      setState(() { _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Workshop Co', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 16),
                if (widget.serviceName != null && widget.serviceName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text('Service: ${widget.serviceName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                const Text('Your Rating', style: TextStyle(fontWeight: FontWeight.normal)),
                Row(
                  children: List.generate(5, (index) => IconButton(
                    icon: Icon(
                      index < _starRating ? Icons.star : Icons.star_border,
                      color: Colors.black,
                    ),
                    onPressed: () => setState(() { _starRating = index + 1; }),
                  )),
                ),
                if (_starRating == 0)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text('Please select a rating', style: TextStyle(color: Colors.red)),
                  ),
                TextFormField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Enter Customer Name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _taskController,
                  decoration: const InputDecoration(
                    labelText: 'Task',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Enter Task' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _feedbackController,
                  decoration: const InputDecoration(
                    labelText: 'Comments',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 4,
                  maxLines: 6,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Colors.black),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isSubmitting ? null : _submitRating,
                    child: _isSubmitting ? const CircularProgressIndicator(color: Colors.black) : const Text('Submit', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}