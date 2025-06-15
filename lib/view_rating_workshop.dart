import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ViewRatingsWorkshop extends StatelessWidget {
  const ViewRatingsWorkshop({Key? key}) : super(key: key);

  Widget _buildStarRow(int starCount) {
    return Row(
      children: List.generate(5, (index) => Icon(
        index < starCount ? Icons.star : Icons.star_border,
        color: Colors.black,
        size: 24,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Ratings (Workshop)'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Workshop Co', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('ratings').orderBy('Rating_Date', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: \\${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('No ratings found.'));
                  }
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final customerId = data['Customer_ID'] ?? 'Unknown';
                      final workshopId = data['Workshop_ID'] ?? '';
                      final starRating = data['Star_Rating'] ?? 0;
                      final feedback = data['Feedback_Comment'] ?? '';
                      final date = (data['Rating_Date'] as Timestamp?)?.toDate();
                      final formattedDate = date != null ? DateFormat('d/M/yyyy').format(date) : '';
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 20,
                                      child: Icon(Icons.person, size: 28),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(customerId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text('Workshop: $workshopId', style: const TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(formattedDate, style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildStarRow(starRating),
                            if (feedback.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(feedback, style: const TextStyle(fontSize: 15)),
                            ],
                          ],
                        ),
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