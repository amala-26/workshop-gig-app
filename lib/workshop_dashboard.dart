import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'workshop_profile_page.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'workshop_profile_page.dart';

class WorkshopDashboard extends StatelessWidget {
  const WorkshopDashboard({Key? key}) : super(key: key);

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error logging out. Please try again.')),
          );
        }
      }
    }
  }

  void _manageSuppliers(BuildContext context) {
    Navigator.pushNamed(context, '/manage-suppliers');
  }

  void _showInventoryOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('View Inventory'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/view-inventory');
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_shopping_cart),
              title: const Text('Request Inventory'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/request-inventory');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('View Requests'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/view-requests');
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workshop Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF1A237E)),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final doc = await FirebaseFirestore.instance
                      .collection('workshops')
                      .doc(user.uid)
                      .get();
                  if (doc.exists) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkshopProfilePage(
                          initialData: doc.data() ?? {},
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile not found.')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => _showInventoryOptions(context),
              icon: const Icon(Icons.storage),
              label: const Text('Inventory'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _manageSuppliers(context),
              icon: const Icon(Icons.group),
              label: const Text('Manage Suppliers'),
            ),
          ],
        ),
      ),
    );
  }
}
