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
  final requestCollection = FirebaseFirestore.instance.collection('inventory_requests');
  final suppliersRef = FirebaseFirestore.instance.collection('suppliers');

  String? selectedSupplier;

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
            SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: suppliersRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                final suppliers = snapshot.data!.docs.map((doc) => doc['name'] as String).toList();
                return DropdownButtonFormField<String>(
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
                );
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (quantity.text.isEmpty || selectedSupplier == null) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Missing Information'),
                      content: Text('Please enter requested quantity and select a supplier.'),
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
                  'Request_Date': Timestamp.now(),
                  'Status': 'Pending',
                  'Status_date': Timestamp.now(),
                  'Supplier': selectedSupplier,
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Request Submitted")));
                Navigator.pop(context);
              },
              child: Text("Submit Request"),
            )
          ],
        ),
      ),
    );
  }
}
