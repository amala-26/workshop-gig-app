import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ViewPayrollScreen extends StatelessWidget {
  const ViewPayrollScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat.currency(symbol: 'MYR ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/add-payroll');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workshop Co',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Payment Records',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('payroll')
                    .orderBy('Payment_Date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No payment records found'));
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Recipient')),
                        DataColumn(label: Text('Amount'), numeric: true),
                        DataColumn(label: Text('Reference')),
                      ],
                      rows: snapshot.data!.docs.map((document) {
                        final data = document.data() as Map<String, dynamic>;
                        final date = (data['Payment_Date'] as Timestamp).toDate();
                        final formattedDate = DateFormat('d/M/yyyy').format(date);
                        final amount = data['Payment_Amount'] ?? 0;
                        final reference = data['Payment_Reference'] ?? '';
                        final recipient = data['Foreman_Name'] ?? '';

                        return DataRow(cells: [
                          DataCell(Text(formattedDate)),
                          DataCell(Text(recipient)),
                          DataCell(Text(currencyFormat.format(amount))),
                          DataCell(Text(reference)),
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