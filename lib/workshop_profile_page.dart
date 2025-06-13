import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkshopProfilePage extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const WorkshopProfilePage({Key? key, required this.initialData}) : super(key: key);

  @override
  State<WorkshopProfilePage> createState() => _WorkshopProfilePageState();
}

class _WorkshopProfilePageState extends State<WorkshopProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _workshopNameController;
  late TextEditingController _workshopAddressController;
  late TextEditingController _businessOverviewController;
  late TextEditingController _operatingHoursController;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _isDeleted = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData['name'] ?? '');
    _phoneController = TextEditingController(text: widget.initialData['phone'] ?? '');
    _emailController = TextEditingController(text: widget.initialData['email'] ?? '');
    _workshopNameController = TextEditingController(text: widget.initialData['workshopName'] ?? '');
    _workshopAddressController = TextEditingController(text: widget.initialData['workshopAddress'] ?? '');
    _businessOverviewController = TextEditingController(text: widget.initialData['businessOverview'] ?? '');
    _operatingHoursController = TextEditingController(text: widget.initialData['operatingHours'] ?? '');
    _isEditing = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isDeleted) {
      return const Scaffold(
        body: Center(child: Text('Profile deleted.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Workshop Profile')),
      body: _isEditing ? _buildEditForm(context) : _buildProfileView(context),
    );
  }

  Widget _buildEditForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
              validator: (v) => v == null || v.trim().isEmpty ? 'Phone number is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
                if (!emailRegex.hasMatch(v)) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _workshopNameController,
              decoration: const InputDecoration(labelText: 'Workshop Name'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Workshop name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _workshopAddressController,
              decoration: const InputDecoration(labelText: 'Workshop Address'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Workshop address is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _businessOverviewController,
              decoration: const InputDecoration(labelText: 'Business Overview'),
              maxLines: 3,
              validator: (v) => v == null || v.trim().isEmpty ? 'Business overview is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _operatingHoursController,
              decoration: const InputDecoration(labelText: 'Operating Hours'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Operating hours are required' : null,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _isSaving = true);
                            try {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                await FirebaseFirestore.instance.collection('workshops').doc(user.uid).set({
                                  'name': _nameController.text.trim(),
                                  'phone': _phoneController.text.trim(),
                                  'email': _emailController.text.trim(),
                                  'workshopName': _workshopNameController.text.trim(),
                                  'workshopAddress': _workshopAddressController.text.trim(),
                                  'businessOverview': _businessOverviewController.text.trim(),
                                  'operatingHours': _operatingHoursController.text.trim(),
                                }, SetOptions(merge: true));
                                if (mounted) {
                                  setState(() {
                                    _isEditing = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changes saved!')));
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save changes.')));
                              }
                            } finally {
                              if (mounted) setState(() => _isSaving = false);
                            }
                          }
                        },
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save Changes'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          setState(() {
                            _isEditing = false;
                          });
                        },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_nameController.text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Profile'),
                              content: const Text('If you click CONFIRM, your account and all your data will be permanently deleted. This action cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                await FirebaseFirestore.instance.collection('workshops').doc(user.uid).delete();
                                await user.delete();
                                await FirebaseAuth.instance.signOut();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deleted successfully.')));
                                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete profile.')));
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(_emailController.text, style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 8),
              Text(_phoneController.text, style: const TextStyle(fontSize: 16)),
              const Divider(height: 32),
              _buildReadOnlyField('Workshop Name', _workshopNameController.text),
              _buildReadOnlyField('Workshop Address', _workshopAddressController.text),
              _buildReadOnlyField('Business Overview', _businessOverviewController.text),
              _buildReadOnlyField('Operating Hours', _operatingHoursController.text),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
} 