import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestItemDetailPage extends StatefulWidget {
  final String itemId;
  final Map<String, dynamic> itemData;

  const RequestItemDetailPage({required this.itemId, required this.itemData});

  @override
  State<RequestItemDetailPage> createState() => _RequestItemDetailPageState();
}

class _RequestItemDetailPageState extends State<RequestItemDetailPage> {
  final quantity = TextEditingController();
  String? selectedSupplier;
  final requestCollection = FirebaseFirestore.instance.collection('inventory_requests');

  final List<String> suppliers = [
    'CarPart Supplies Sdn Bhd',
    'TopGear Malaysia',
    'AutoTech Distributors',
    'ProEngineers Supplier',
    'Wong Supplies Sdn Bhd',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Request Item")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item Name: ${widget.itemData['Item_Name'] ?? ''}'),
            Text('Category: ${widget.itemData['Category'] ?? ''}'),
            Text('Unit: ${widget.itemData['Unit'] ?? ''}'),
            Text('Storage Location: ${widget.itemData['Storage_Location'] ?? ''}'),
            SizedBox(height: 20),
            TextField(
              controller: quantity,
              decoration: InputDecoration(labelText: 'Requested Quantity'),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField<String>(
              value: selectedSupplier,
              decoration: InputDecoration(labelText: 'Select Supplier'),
              items: suppliers.map((supplier) {
                return DropdownMenuItem(
                  value: supplier,
                  child: Text(supplier),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSupplier = value;
                });
              },
              validator: (value) => value == null ? 'Please select a supplier' : null,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (quantity.text.isEmpty || selectedSupplier == null) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Missing Information'),
                      content: Text('Please enter quantity and select a supplier.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('OK'),
                        )
                      ],
                    ),
                  );
                  return;
                }
                final requestId = DateTime.now().millisecondsSinceEpoch.toString();
                await requestCollection.doc(requestId).set({
                  'Request_ID': requestId,
                  'Item_ID': widget.itemId,
                  'Requested_Quantity': int.parse(quantity.text),
                  'Supplier': selectedSupplier,
                  'Request_Date': Timestamp.now(),
                  'Status': 'Pending',
                  'Status_date': Timestamp.now(),
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Request Submitted Successfully")),
                  );
                  Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
                }
              },
              child: Text("Submit Request"),
            )
          ],
        ),
      ),
    );
  }
}