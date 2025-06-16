// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/gig_service.dart';
import '../models/gig_model.dart';
import 'package:flutter/services.dart'; // Import for FilteringTextInputFormatter
import '../services/notification_service.dart'; // Import NotificationService

/// A widget that allows workshop owners to edit existing gig slots.
/// Provides form fields for updating gig details while maintaining certain restrictions
/// (e.g., location and foreman count cannot be modified).
class EditGigSlot extends StatefulWidget {
  // These parameters are still needed because ManageGigSlots passes them
  final GigService gigService;
  final String gigId;
  final Map<String, dynamic> initialData;

  const EditGigSlot({
    Key? key,
    required this.gigService,
    required this.gigId,
    required this.initialData,
  }) : super(key: key);

  @override
  State<EditGigSlot> createState() => _EditGigSlotState();
}

class _EditGigSlotState extends State<EditGigSlot> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _foremenNeededController;
  late TextEditingController _remunerationController;
  late TextEditingController _locationController;

  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  final NotificationService _notificationService = NotificationService(); // Instantiate NotificationService

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing gig data
    _titleController = TextEditingController(text: widget.initialData['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.initialData['description'] ?? '');
    _foremenNeededController = TextEditingController(text: (widget.initialData['foremenNeeded'] ?? 0).toString());
    _remunerationController = TextEditingController(text: (widget.initialData['remuneration'] ?? 0.0).toString());
    _locationController = TextEditingController(text: widget.initialData['location'] ?? '');

    // Parse existing date and time data
    if (widget.initialData['date'] != null) {
      _selectedDate = (widget.initialData['date'] as Timestamp).toDate();
    }
    if (widget.initialData['startTime'] != null) {
      try {
        final parts = (widget.initialData['startTime'] as String).split(':');
        _selectedStartTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (e) {
        _selectedStartTime = null;
      }
    }
    if (widget.initialData['endTime'] != null) {
      try {
        final parts = (widget.initialData['endTime'] as String).split(':');
        _selectedEndTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (e) {
        _selectedEndTime = null;
      }
    }
  }

  /// Shows a date picker dialog and updates the selected date
  /// @param context The build context
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Shows a time picker dialog and updates either start or end time
  /// @param context The build context
  /// @param isStartTime If true, updates start time; otherwise updates end time
  // ignore: unused_element
  Future<void> _selectTime(BuildContext context, {required bool isStartTime}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_selectedStartTime ?? TimeOfDay.now())
          : (_selectedEndTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _selectedStartTime = picked;
        } else {
          _selectedEndTime = picked;
        }
      });
    }
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

  /// Updates the gig slot with new information and notifies relevant foremen
  /// Validates form data and required fields before proceeding with the update
  Future<void> _updateGig() async {
    if (_formKey.currentState!.validate()) {
      // Validate required fields
      if (_selectedDate == null) {
        _showSnackBar('Please select a date', isError: true);
        return;
      }
      if (_selectedStartTime == null) {
        _showSnackBar('Please select a start time', isError: true);
        return;
      }
      if (_selectedEndTime == null) {
        _showSnackBar('Please select an end time', isError: true);
        return;
      }

      try {
        // Prepare updated gig data
        final gigData = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'date': Timestamp.fromDate(_selectedDate!),
          'startTime': DateFormat('HH:mm').format(DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedStartTime!.hour, _selectedStartTime!.minute)),
          'endTime': DateFormat('HH:mm').format(DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedEndTime!.hour, _selectedEndTime!.minute)),
          'remuneration': double.parse(_remunerationController.text),
          // foremanNeeded and location are not updated as per requirement
        };
        await widget.gigService.updateGigSlot(widget.gigId, gigData);

        // Notify foremen about the update
        final QuerySnapshot applicationsSnapshot = await FirebaseFirestore.instance
            .collection('gigApplications')
            .where('gigId', isEqualTo: widget.gigId)
            .get();

        final String formattedDate = DateFormat('MMM dd').format(_selectedDate!);

        for (var appDoc in applicationsSnapshot.docs) {
          final String foremanId = appDoc['foremanId'];
          await _notificationService.addNotification(
            type: 'gig_update',
            recipientId: foremanId,
            senderId: widget.initialData['ownerId'],
            gigId: widget.gigId,
            message: 'The gig slot "${_titleController.text}" for $formattedDate has been edited. Please review the new details.',
            action: 'edited',
            gigTitle: _titleController.text,
            gigDate: Timestamp.fromDate(_selectedDate!),
          );
        }

        _showSnackBar('Gig slot updated successfully!');
        if (context.mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        _showSnackBar('Failed to update gig slot: $e', isError: true);
      }
    }
  }

  @override
  void dispose() {
    // Clean up controllers
    _titleController.dispose();
    _descriptionController.dispose();
    _foremenNeededController.dispose();
    _remunerationController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Gig Slot'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Form fields for editing gig details
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Slot Name', hintText: 'Diesel Engine Diagnostics'),
                validator: (value) => value!.isEmpty ? 'Please enter a slot name' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Job Description', hintText: 'Description_Blablabla'),
                validator: (value) => value!.isEmpty ? 'Please enter a job description' : null,
              ),
              // Date selection
              ListTile(
                title: Text(
                  _selectedDate == null
                      ? 'Select Date'
                      : '${DateFormat('MM/dd/yy').format(_selectedDate!)}',
                  style: TextStyle(color: _selectedDate == null ? Colors.grey[700] : Colors.black),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              // Time selection
              ListTile(
                title: Text(
                  _selectedStartTime == null || _selectedEndTime == null
                      ? 'Select Time'
                      : '${_selectedStartTime!.format(context)} - ${_selectedEndTime!.format(context)}',
                  style: TextStyle(color: _selectedStartTime == null && _selectedEndTime == null ? Colors.grey[700] : Colors.black),
                ),
                trailing: const Icon(Icons.timer),
                onTap: () async {
                  final TimeOfDay? pickedStartTime = await showTimePicker(
                    context: context,
                    initialTime: _selectedStartTime ?? TimeOfDay.now(),
                  );
                  if (pickedStartTime != null) {
                    final TimeOfDay? pickedEndTime = await showTimePicker(
                      context: context,
                      initialTime: _selectedEndTime ?? pickedStartTime,
                    );
                    if (pickedEndTime != null) {
                      setState(() {
                        _selectedStartTime = pickedStartTime;
                        _selectedEndTime = pickedEndTime;
                      });
                    }
                  }
                },
              ),
              // Read-only fields
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                enabled: false,
                style: const TextStyle(color: Color(0xFF8D8D8D)),
                validator: (value) => value!.isEmpty ? 'Please enter a location' : null,
              ),
              TextFormField(
                controller: _foremenNeededController,
                decoration: const InputDecoration(labelText: 'Number of Foremen'),
                keyboardType: TextInputType.number,
                enabled: false,
                style: const TextStyle(color: Color(0xFF8D8D8D)),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter number of foremen';
                  final int? parsedValue = int.tryParse(value);
                  if (parsedValue == null) return 'Please enter a valid whole number';
                  if (parsedValue <= 0) return 'Foreman count must be greater than 0';
                  return null;
                },
              ),
              // Editable fields
              TextFormField(
                controller: _remunerationController,
                decoration: const InputDecoration(labelText: 'Salary Details', hintText: 'RM 30'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter salary details';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  if (double.parse(value) < 0) return 'Salary details cannot be negative';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateGig,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 