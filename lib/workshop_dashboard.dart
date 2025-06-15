import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/ManageGigSlots.dart';
import 'screens/ManageGigApplication.dart';
import 'services/gig_service.dart';
import 'workshop_profile_page.dart';
import 'view_inventory_page.dart';
import 'add_inventory_page.dart';
import 'request_inventory_page.dart';
import 'request_status_page.dart';
import 'workshop_payroll.dart';
import 'view_payroll_screen.dart';

class WorkshopDashboard extends StatefulWidget {
  const WorkshopDashboard({Key? key}) : super(key: key);

  @override
  State<WorkshopDashboard> createState() => _WorkshopDashboardState();
}

class _WorkshopDashboardState extends State<WorkshopDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GigService _gigService = GigService();
  String _userName = '';
  String _userEmail = '';
  bool _isScheduleExpanded = false;
  bool _isInventoryExpanded = false;
  bool _isPayrollExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('workshops')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _userName = doc.data()?['name'] ?? '';
          _userEmail = doc.data()?['email'] ?? '';
        });
      }
    }
  }

  Future<void> _navigateToProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('workshops')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkshopProfilePage(initialData: doc.data()!),
          ),
        );
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
            onPressed: () async {
              await _auth.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF1A237E),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Color(0xFF1A237E)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _userEmail,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: _navigateToProfile,
            ),
            ExpansionTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Manage Inventory'),
              initiallyExpanded: _isInventoryExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  _isInventoryExpanded = expanded;
                });
              },
              children: [
                ListTile(
                  leading: const Icon(Icons.list),
                  title: const Text('View Inventory'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewInventoryPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_box),
                  title: const Text('Add Inventory'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddInventoryPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_cart),
                  title: const Text('Request Inventory'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RequestInventoryPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Request Status'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RequestStatusPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.group),
                  title: const Text('Manage Suppliers'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/manage-suppliers');
                  },
                ),
              ],
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
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageGigSlots(gigService: _gigService),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.assignment),
                  title: const Text('Manage Applications'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageGigApplication(gigService: _gigService),
                      ),
                    );
                  },
                ),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.payment),
              title: const Text('Payroll Management'),
              initiallyExpanded: _isPayrollExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  _isPayrollExpanded = expanded;
                });
              },
              children: [
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('View Payroll'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ViewPayrollScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_circle),
                  title: const Text('Add Payroll Record'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WorkshopPayroll(),
                      ),
                    );
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
            const Icon(
              Icons.dashboard,
              size: 100,
              color: Color(0xFF1A237E),
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome, $_userName',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Use the menu to navigate',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}