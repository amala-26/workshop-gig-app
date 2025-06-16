// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewPayrollForeman extends StatelessWidget {
  const ViewPayrollForeman({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Payment Records'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Center(
              child: Text(
                'Payment Records',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('payroll')
                    .where('Foreman_Uid', isEqualTo: currentUser?.uid ?? '')
                    .orderBy('Payment_Date', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final payments = snapshot.data!.docs;

                  if (payments.isEmpty) {
                    return const Center(
                      child: Text(
                        'No payment records found',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Amount (MYR)')),
                        DataColumn(label: Text('Reference')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: payments.map((doc) {
                        final payment = doc.data() as Map<String, dynamic>;
                        final date = (payment['Payment_Date'] as Timestamp).toDate();
                        final formattedDate = DateFormat('d/M/yyyy').format(date);
                        final amount = payment['Payment_Amount'] ?? 0;
                        final reference = payment['Payment_Reference'] ?? '';
                        final status = payment['Payment_Status'] ?? '';
                        return DataRow(cells: [
                          DataCell(Text(formattedDate)),
                          DataCell(Text(amount.toStringAsFixed(2))),
                          DataCell(Text(reference)),
                          DataCell(Text(status)),
                        ]);
                      }).toList(),
                    ),
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