import 'package:flutter/material.dart';

class WorkshopPayroll extends StatefulWidget {
  const WorkshopPayroll({Key? key}) : super(key: key);

  @override
  State<WorkshopPayroll> createState() => _WorkshopPayrollState();
}

class _WorkshopPayrollState extends State<WorkshopPayroll> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedBank;
  String? _recipient;
  String? _accountNumber;
  double _amount = 0.00;
  String? _paymentDate;
  String? _reference;
  bool _showError = false;
  bool _paymentSuccess = false;

  final List<String> _banks = ['Select...', 'Bank Islam', 'Maybank', 'RHB Bank'];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _paymentDate = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Payment'),
          content: const Text('Do you want to submit the payment?'),
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
              child: const Text('Submit Payment'),
            ),
          ],
        );
      },
    );
  }

  void _submitPayment(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      if (_selectedBank == null || _selectedBank == 'Select...') {
        setState(() {
          _showError = true;
        });
        return;
      }

      setState(() {
        _paymentSuccess = true;
      });
    } else {
      setState(() {
        _showError = true;
      });
    }
  }

  void _showAmountModificationDialog(BuildContext context) {
    TextEditingController amountController = TextEditingController(text: _amount.toStringAsFixed(2));
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Modify Payment Amount'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Amount: MYR ${_amount.toStringAsFixed(2)}'),
              const SizedBox(height: 10),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'New Amount: (MYR)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
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
                if (newAmount != null && newAmount >= 0) {
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
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Workshop Co',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Payment Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(thickness: 2),
                  const SizedBox(height: 30),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 30,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Payment Successful',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Your money has been\npaid to the worker',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _resetForm,
                          child: const Text('Submit Another Payment'),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Workshop Co',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Payment Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    if (_showError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'Invalid Payment Details\nPlease Check and Try again.',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 16,
                          ),
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
                        labelText: 'To',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _recipient = value;
                          _showError = false;
                        });
                      },
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
                      onChanged: (value) {
                        setState(() {
                          _accountNumber = value;
                          _showError = false;
                        });
                      },
                      validator: (value) => value?.isEmpty ?? true 
                          ? 'Please enter account number' 
                          : null,
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
                            Text('MYR ${_amount.toStringAsFixed(2)}'),
                            const Icon(Icons.edit, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Payment Date',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: _paymentDate),
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (value) => value?.isEmpty ?? true 
                          ? 'Please select payment date' 
                          : null,
                    ),
                    const SizedBox(height: 20),
                    
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Reference',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _reference = value;
                          _showError = false;
                        });
                      },
                      validator: (value) => value?.isEmpty ?? true 
                          ? 'Please enter reference' 
                          : null,
                    ),
                    const SizedBox(height: 30),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showConfirmationDialog(context),
                        child: const Text('Submit Payment'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}