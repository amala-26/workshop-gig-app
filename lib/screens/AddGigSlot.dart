import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/gig_service.dart';
import '../models/gig_model.dart';
import 'package:flutter/services.dart';
import '../services/notification_service.dart';

/// A widget that allows workshop owners to create new gig slots.
/// Provides form fields for entering gig details and handles validation,
/// redundancy checking, and notification of foremen about new gigs.
class AddGigSlot extends StatefulWidget {
  final GigService gigService;
  final String ownerId;

  const AddGigSlot({
    Key? key, 
    required this.gigService,
    required this.ownerId,
  }) : super(key: key);

  @override
  State<AddGigSlot> createState() => _AddGigSlotState();
}

class _AddGigSlotState extends State<AddGigSlot> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _foremenNeededController = TextEditingController();
  final TextEditingController _remunerationController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  final NotificationService _notificationService = NotificationService();

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

  /// Handles the creation of a new gig slot
  /// Validates form data, checks for redundancy, and notifies foremen
  Future<void> _addGig() async {
    print('Starting _addGig method');
    if (_formKey.currentState!.validate()) {
      print('Form validation passed');
      // Validate required fields
      if (_selectedDate == null) {
        print('Date is null');
        _showSnackBar('Please select a date', isError: true);
        return;
      }
      if (_selectedStartTime == null) {
        print('Start time is null');
        _showSnackBar('Please select a start time', isError: true);
        return;
      }
      if (_selectedEndTime == null) {
        print('End time is null');
        _showSnackBar('Please select an end time', isError: true);
        return;
      }

      print('Checking for redundancy');
      // Check for redundancy (E1)
      final redundancyResult = await widget.gigService.checkGigSlotRedundancy(
        GigModel(
          title: _titleController.text,
          description: _descriptionController.text,
          location: _locationController.text,
          date: _selectedDate!,
          startTime: DateFormat('HH:mm').format(DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedStartTime!.hour, _selectedStartTime!.minute)),
          endTime: DateFormat('HH:mm').format(DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedEndTime!.hour, _selectedEndTime!.minute)),
          remuneration: double.parse(_remunerationController.text),
          foremenNeeded: int.parse(_foremenNeededController.text),
          ownerId: widget.ownerId,
        ),
      );

      if (!redundancyResult['success']) {
        print('Redundancy check failed - slot exists');
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Slot Already Exists'),
            content: Text(redundancyResult['message']),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      print('Showing confirmation dialog');
      // Show confirmation dialog about non-editable fields
      final bool? confirmProceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,  // Prevent dismissing by tapping outside
        builder: (context) => AlertDialog(
          title: const Text('Confirm Add Gig Slot'),
          content: const Text('Once added, the foreman count and gig location cannot be changed. Do you want to proceed?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('NO'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('YES'),
            ),
          ],
        ),
      );

      print('Confirmation dialog result: $confirmProceed');
      if (confirmProceed == true) {
        try {
          print('Creating gig data');
          // Prepare gig data for creation
          final gigData = {
            'title': _titleController.text,
            'description': _descriptionController.text,
            'date': Timestamp.fromDate(_selectedDate!),
            'startTime': DateFormat('HH:mm').format(DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedStartTime!.hour, _selectedStartTime!.minute)),
            'endTime': DateFormat('HH:mm').format(DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedEndTime!.hour, _selectedEndTime!.minute)),
            'foremenNeeded': int.parse(_foremenNeededController.text),
            'remuneration': double.parse(_remunerationController.text),
            'location': _locationController.text,
            'createdAt': FieldValue.serverTimestamp(),
            'ownerId': widget.ownerId,
            'foremenAssigned': 0,
          };
          print('Saving gig data');
          await widget.gigService.createGig(gigData);

          // Notify all foremen about the new gig
          final QuerySnapshot foremenSnapshot = await FirebaseFirestore.instance.collection('foremen').get();
          final String formattedDate = DateFormat('MMM dd').format(_selectedDate!);

          print('Attempting to send gig added notification to all foremen.');
          for (var foremanDoc in foremenSnapshot.docs) {
            final String foremanId = foremanDoc.id;
            print('Sending gig added notification to foreman: $foremanId');
            await _notificationService.addNotification(
              type: 'gig_update',
              recipientId: foremanId,
              senderId: widget.ownerId,
              gigId: gigData['id'] as String?,
              message: 'A new gig slot has been added for $formattedDate at ${gigData['location']}.',
              action: 'added',
              gigTitle: gigData['title'] as String?,
              gigDate: Timestamp.fromDate(_selectedDate!),
            );
          }
          print('Gig added notifications sent successfully (if no error thrown).');

          _showSnackBar('Gig slot added successfully!');
          if (context.mounted) {
            Navigator.pop(context, true);
          }
        } catch (e) {
          print('Error creating gig: $e');
          _showSnackBar('Failed to add gig slot: $e', isError: true);
        }
      }
    } else {
      print('Form validation failed');
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
        title: const Text('Add New Gig Slot'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Basic gig information
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Slot Name', hintText: 'Enter Slot Name'),
                validator: (value) => value!.isEmpty ? 'Please enter a slot name' : null,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Job Description', hintText: 'Enter Job Description'),
                validator: (value) => value!.isEmpty ? 'Please enter a job description' : null,
              ),
              const SizedBox(height: 16.0),
              // Date and time selection
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
              const SizedBox(height: 16.0),
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
              const SizedBox(height: 16.0),
              // Location and foreman count
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location', hintText: 'Enter Location'),
                validator: (value) => value!.isEmpty ? 'Please enter a location' : null,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _foremenNeededController,
                decoration: const InputDecoration(labelText: 'Number of Foremen', hintText: 'Enter Number of Foremen'),
                keyboardType: TextInputType.number,
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
              const Text(
                "Foreman count cannot be edited once the slot is added.",
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
              const SizedBox(height: 16.0),
              // Remuneration details
              TextFormField(
                controller: _remunerationController,
                decoration: const InputDecoration(labelText: 'Salary Per Hour (RM)', hintText: 'Enter Salary Per Hour'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter salary per hour';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  if (double.parse(value) < 0) return 'Salary per hour cannot be negative';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addGig,
                child: const Text('Add Slot'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 