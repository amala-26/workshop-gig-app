import 'package:flutter/material.dart';

class ViewPayrollForeman extends StatelessWidget {
  const ViewPayrollForeman({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Foreman Payroll'),
      ),
      body: const Center(
        child: Text('Foreman Payroll Information'),
      ),
    );
  }
}