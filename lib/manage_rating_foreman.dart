import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'add_rating_foreman.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageRatingForeman extends StatefulWidget {
  const ManageRatingForeman({Key? key}) : super(key: key);

  @override
  State<ManageRatingForeman> createState() => _ManageRatingForemanState();
}

class _ManageRatingForemanState extends State<ManageRatingForeman> {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    print('Current user UID: ${currentUser?.uid}');
    return Scaffold(
      appBar: AppBar(title: const Text('Add Rating')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Workshop Co', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Add Rating', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                  .collection('payroll')
                  .snapshots(),
                builder: (context, payrollSnapshot) {
                  if (payrollSnapshot.hasError) return Center(child: Text('Error: ${payrollSnapshot.error}'));
                  if (payrollSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final payrolls = payrollSnapshot.data!.docs;
                  print('Payrolls fetched:');
                  for (var p in payrolls) {
                    print(p.data());
                  }
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('ratings').snapshots(),
                    builder: (context, ratingSnapshot) {
                      if (ratingSnapshot.hasError) return Center(child: Text('Error: ${ratingSnapshot.error}'));
                      if (ratingSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      final ratings = ratingSnapshot.data!.docs;
                      // Map for quick lookup
                      final ratedMap = <String, QueryDocumentSnapshot>{};
                      for (var r in ratings) {
                        final data = r.data() as Map<String, dynamic>;
                        ratedMap['${data['workshopId']}_${data['customerId']}'] = r;
                      }
                      final unrated = <QueryDocumentSnapshot>[];
                      for (var p in payrolls) {
                        final pdata = p.data() as Map<String, dynamic>;
                        final key = '${pdata['Foreman_Uid']}_${pdata['Created_By']}';
                        if (!ratedMap.containsKey(key)) {
                          unrated.add(p);
                        }
                      }
                      return ListView(
                        children: [
                          const Text('Completed Service', style: TextStyle(fontWeight: FontWeight.bold)),
                          ...unrated.map((p) {
                            final pdata = p.data() as Map<String, dynamic>;
                            final date = (pdata['Payment_Date'] as Timestamp?)?.toDate();
                            final formattedDate = date != null ? DateFormat('d/M/yyyy').format(date) : '';
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const CircleAvatar(radius: 20, child: Icon(Icons.person, size: 28)),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Workshop Co', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              Text('Task: ${pdata['Payment_Reference'] ?? ''}', style: const TextStyle(fontSize: 14)),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Text(formattedDate, style: const TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AddRatingForeman(
                                              serviceName: pdata['Payment_Reference'] ?? '',
                                              task: pdata['Payment_Reference'] ?? '',
                                            ),
                                          ),
                                        );
                                        setState(() {});
                                      },
                                      child: const Text('Submit Your Rating'),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 