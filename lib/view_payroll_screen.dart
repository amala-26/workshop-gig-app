import 'package:flutter/material.dart';

class ViewPayrollScreen extends StatelessWidget {
  const ViewPayrollScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll Records'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text(
          'Payroll records will be displayed here',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}