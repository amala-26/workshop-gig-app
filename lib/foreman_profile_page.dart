import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForemanProfilePage extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const ForemanProfilePage({Key? key, required this.initialData}) : super(key: key);

  @override
  State<ForemanProfilePage> createState() => _ForemanProfilePageState();
}

class _ForemanProfilePageState extends State<ForemanProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  List<String> positions = [];
  List<String> skills = [];
  List<String> specializations = [];
  List<String> experiences = [];
  bool _isSaving = false;
  bool _isEditing = false;
  bool _isDeleted = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData['name'] ?? '');
    _phoneController = TextEditingController(text: widget.initialData['phone'] ?? '');
    _emailController = TextEditingController(text: widget.initialData['email'] ?? '');
    positions = List<String>.from(widget.initialData['positions'] ?? []);
    skills = List<String>.from(widget.initialData['skills'] ?? []);
    specializations = List<String>.from(widget.initialData['specializations'] ?? []);
    experiences = List<String>.from(widget.initialData['experiences'] ?? []);
    _isEditing = false;
  }

  void _addToList(List<String> list, String label) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $label'),
        content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(labelText: label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => list.add(result));
    }
  }

  void _editListItem(List<String> list, int index, String label) async {
    final controller = TextEditingController(text: list[index]);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(labelText: label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => list[index] = result);
    }
  }

  void _deleteListItem(List<String> list, int index) {
    setState(() => list.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    if (_isDeleted) {
      return const Scaffold(
        body: Center(child: Text('Profile deleted.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Foreman Profile')),
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
            const SizedBox(height: 20),
            _buildEditableList('Position', positions),
            _buildEditableList('Skill', skills),
            _buildEditableList('Specialization', specializations),
            _buildEditableList('Experience', experiences),
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
                                await FirebaseFirestore.instance.collection('foremen').doc(user.uid).set({
                                  'name': _nameController.text.trim(),
                                  'phone': _phoneController.text.trim(),
                                  'email': _emailController.text.trim(),
                                  'positions': positions,
                                  'skills': skills,
                                  'specializations': specializations,
                                  'experiences': experiences,
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
                              title: const Text('Delete Account'),
                              content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final passwordController = TextEditingController();
                            final passwordOk = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirm Password'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Please re-enter your password to confirm account deletion.'),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: passwordController,
                                      obscureText: true,
                                      decoration: const InputDecoration(labelText: 'Password'),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                  ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
                                ],
                              ),
                            );
                            if (passwordOk == true) {
                              await _deleteAccountWithReauth(context, passwordController.text);
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
              _buildReadOnlyList('Positions', positions),
              _buildReadOnlyList('Skills', skills),
              _buildReadOnlyList('Specializations', specializations),
              _buildReadOnlyList('Experiences', experiences),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyList(String label, List<String> list) {
    if (list.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          ...list.map((item) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Text('- $item', style: const TextStyle(fontSize: 15)),
              )),
        ],
      ),
    );
  }

  Widget _buildEditableList(String label, List<String> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label + 's', style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addToList(list, label),
            ),
          ],
        ),
        ...list.asMap().entries.map((entry) => ListTile(
              title: Text(entry.value),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editListItem(list, entry.key, label),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteListItem(list, entry.key),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _deleteAccountWithReauth(BuildContext context, String password) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        final cred = EmailAuthProvider.credential(email: user.email!, password: password);
        await user.reauthenticateWithCredential(cred);
        await FirebaseFirestore.instance.collection('foremen').doc(user.uid).delete();
        await user.delete();
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deleted successfully.')));
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete account. Please try again.')));
      }
    }
  }
} 