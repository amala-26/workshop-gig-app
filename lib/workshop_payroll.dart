// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WorkshopPayroll extends StatefulWidget {
  const WorkshopPayroll({Key? key}) : super(key: key);

  @override
  State<WorkshopPayroll> createState() => _WorkshopPayrollState();
}

class _WorkshopPayrollState extends State<WorkshopPayroll> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _selectedBank;
  String? _recipient;
  String? _accountNumber;
  double _amount = 0.00;
  DateTime? _paymentDate;
  String? _reference;
  bool _showError = false;
  bool _paymentSuccess = false;
  bool _isSubmitting = false;

  final List<String> _banks = ['Select...', 'Bank Islam', 'Maybank', 'RHB Bank'];
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'MYR ');

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _paymentDate = picked;
      });
    }
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Payment'),
          content: const Text('Do you want to submit this payment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _submitPayment(context);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitPayment(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      if (_selectedBank == null || _selectedBank == 'Select...') {
        setState(() {
          _showError = true;
        });
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        final user = _auth.currentUser;
        if (user != null) {
          final foremanQuery = await _firestore.collection('foremen')
              .where('name', isEqualTo: _recipient)
              .limit(1)
              .get();

          if (foremanQuery.docs.isNotEmpty) {
            final foremanUid = foremanQuery.docs.first.id;
            
            await _firestore.collection('payroll').add({
              'Foreman_Name': _recipient,
              'Foreman_Uid': foremanUid,
              'Bank_Name': _selectedBank,
              'Account_Number': _accountNumber,
              'Payment_Amount': _amount,
              'Payment_Date': _paymentDate ?? DateTime.now(),
              'Payment_Reference': _reference,
              'Payment_Status': 'Paid',
              'Created_By': user.uid,
              'Created_At': FieldValue.serverTimestamp(),
              'Role': 'foreman',
            });

            setState(() {
              _paymentSuccess = true;
            });
            // Navigate to payroll records after short delay
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/view-payroll');
              }
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Foreman not found. Please check the recipient name.')),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save payment: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    } else {
      setState(() {
        _showError = true;
      });
    }
  }

  void _showAmountModificationDialog(BuildContext context) {
    TextEditingController amountController = TextEditingController(
      text: _amount.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Modify Payment Amount'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Amount: ${_currencyFormat.format(_amount)}'),
              const SizedBox(height: 10),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'New Amount (MYR)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newAmount = double.tryParse(amountController.text);
                if (newAmount != null && newAmount > 0) {
                  setState(() {
                    _amount = newAmount;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _resetForm() {
    setState(() {
      _selectedBank = null;
      _recipient = null;
      _accountNumber = null;
      _amount = 0.00;
      _paymentDate = null;
      _reference = null;
      _showError = false;
      _paymentSuccess = false;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Payroll Record'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _paymentSuccess
            ? _buildSuccessView()
            : _buildFormView(),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.black,
            child: Icon(Icons.check, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          const Text(
            'Payment Successful',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your money has been\npaid to the worker',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Workshop Co',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
            'Payment Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          if (_showError)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Invalid Payment Details\nPlease Check and Try again.',
                style: TextStyle(color: Colors.red[700], fontSize: 16),
              ),
            ),
          
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Choose Bank',
              border: OutlineInputBorder(),
            ),
            value: _selectedBank,
            items: _banks.map((bank) => DropdownMenuItem(
              value: bank,
              child: Text(bank),
            )).toList(),
            onChanged: (value) {
              setState(() {
                _selectedBank = value;
                _showError = false;
              });
            },
            validator: (value) => value == null || value == 'Select...' 
                ? 'Please select a bank' 
                : null,
          ),
          const SizedBox(height: 20),
          
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Recipient Name',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _recipient = value),
            validator: (value) => value?.isEmpty ?? true 
                ? 'Please enter recipient name' 
                : null,
          ),
          const SizedBox(height: 20),
          
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Account Number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => setState(() => _accountNumber = value),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please enter account number';
              if (!RegExp(r'^[0-9]+$').hasMatch(value!)) {
                return 'Account number must contain only digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          InkWell(
            onTap: () => _showAmountModificationDialog(context),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Amount (MYR)',
                border: OutlineInputBorder(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_currencyFormat.format(_amount)),
                  const Icon(Icons.edit, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          InkWell(
            onTap: () => _selectDate(context),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Payment Date',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                _paymentDate != null 
                    ? DateFormat('dd/MM/yyyy').format(_paymentDate!)
                    : 'Select date',
                style: TextStyle(
                  color: _paymentDate != null 
                      ? Colors.black 
                      : Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Reference',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _reference = value),
            validator: (value) => value?.isEmpty ?? true 
                ? 'Please enter reference' 
                : null,
          ),
          const SizedBox(height: 30),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting 
                  ? null 
                  : () => _showConfirmationDialog(context),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Payment'),
            ),
          ),
        ],
      ),
    );
  }
}