import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkshopPayroll extends StatefulWidget {
  const WorkshopPayroll({Key? key}) : super(key: key);

  @override
  State<WorkshopPayroll> createState() => _WorkshopPayrollState();
}

class _WorkshopPayrollState extends State<WorkshopPayroll> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _payrollRecords = [];

  @override
  void initState() {
    super.initState();
    _loadPayrollRecords();
  }

  Future<void> _loadPayrollRecords() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final snapshot = await _firestore
            .collection('workshops')
            .doc(user.uid)
            .collection('payroll')
            .orderBy('date', descending: true)
            .get();

        setState(() {
          _payrollRecords = snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading payroll records: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll Management'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Payroll Records',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/add-payroll');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Record'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _payrollRecords.isEmpty
                      ? const Center(
                          child: Text('No payroll records found'),
                        )
                      : ListView.builder(
                          itemCount: _payrollRecords.length,
                          itemBuilder: (context, index) {
                            final record = _payrollRecords[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                title: Text(
                                  'Foreman: ${record['foremanName'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date: ${record['date']?.toDate().toString().split(' ')[0] ?? 'N/A'}',
                                    ),
                                    Text(
                                      'Amount: RM ${record['amount']?.toStringAsFixed(2) ?? '0.00'}',
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.visibility),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/view-payroll',
                                      arguments: record,
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
