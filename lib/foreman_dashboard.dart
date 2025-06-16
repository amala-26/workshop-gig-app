// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'foreman_profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'view_payroll_foreman.dart';
// ignore: unused_import
import 'add_rating_foreman.dart';
import 'view_rating_foreman.dart';
import 'manage_rating_foreman.dart';
import 'package:workshopgigapp/services/gig_service.dart';
import 'package:workshopgigapp/controllers/gig_controller.dart';
import 'package:workshopgigapp/screens/GigApplicationInterface.dart';
import 'package:workshopgigapp/screens/AppliedGigList.dart';
import 'package:workshopgigapp/screens/NotificationsScreen.dart';
import 'package:workshopgigapp/services/notification_service.dart';

class ForemanDashboard extends StatefulWidget {
  const ForemanDashboard({Key? key}) : super(key: key);

  @override
  State<ForemanDashboard> createState() => _ForemanDashboardState();
}

class _ForemanDashboardState extends State<ForemanDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GigService _gigService = GigService();
  late final GigController _gigController;
  final NotificationService _notificationService = NotificationService();

  String _userName = '';
  String _userEmail = '';
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _gigController = GigController(_gigService);
    _currentUser = _auth.currentUser;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('foremen')
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
          .collection('foremen')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ForemanProfilePage(
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
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
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
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Foreman Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Foreman Dashboard'),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: _notificationService.getNotificationsForUser(_currentUser!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return IconButton(
                  icon: const Icon(Icons.notifications_none),
                  onPressed: () {},
                );
              }
              if (snapshot.hasError) {
                print('Error fetching notifications: ${snapshot.error}');
                return IconButton(
                  icon: const Icon(Icons.notifications_off),
                  onPressed: () {},
                );
              }

              final unreadCount = snapshot.data?.docs.where((doc) => doc['isRead'] == false).length ?? 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 11,
                      top: 11,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                ],
              );
            },
          ),
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
            // Profile Section
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: _navigateToProfile,
            ),
            
            // Payroll Section
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text('Payroll', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('View Payroll'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ViewPayrollForeman()),
                );
              },
            ),
            
            // Gig Application Section
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text('Gig Application', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.work_history),
              title: const Text('Gig Application'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GigApplicationInterface()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Applied Gigs'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AppliedGigList()),
                );
              },
            ),
            
            // Ratings Section
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text('Ratings', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ExpansionTile(
              leading: const Icon(Icons.star),
              title: const Text('Manage Ratings'),
              children: [
                ListTile(
                  title: const Text('Add Rating'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageRatingForeman()),
                    );
                  },
                ),
                ListTile(
                  title: const Text('View Ratings'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ViewRatingsForeman()),
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