import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'workshop_profile_page.dart';

class WorkshopDashboard extends StatefulWidget {
  const WorkshopDashboard({Key? key}) : super(key: key);

  @override
  State<WorkshopDashboard> createState() => _WorkshopDashboardState();
}

class _WorkshopDashboardState extends State<WorkshopDashboard> {
  bool _isScheduleExpanded = false;

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
            ExpansionTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Manage Foreman Schedule'),
              initiallyExpanded: _isScheduleExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  _isScheduleExpanded = expanded;
                });
              },
              children: [
                ListTile(
                  leading: const Icon(Icons.work_outline),
                  title: const Text('Manage Gig Slots'),
                  onTap: () {
                    Navigator.pushNamed(context, '/manage-gig-slots');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.assignment),
                  title: const Text('Manage Gig Applications'),
                  onTap: () {
                    Navigator.pushNamed(context, '/manage-applications');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/view-inventory');
              },
              icon: const Icon(Icons.inventory),
              label: const Text('View Inventory'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/request-inventory');
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Request Inventory'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/view-requests');
              },
              icon: const Icon(Icons.receipt_long),
              label: const Text('View Requests'),
            ),
          ],
        ),
      ),
    );
  }
}
