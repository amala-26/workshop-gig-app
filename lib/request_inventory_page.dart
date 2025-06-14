import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestInventoryPage extends StatefulWidget {
  @override
  State<RequestInventoryPage> createState() => _RequestInventoryPageState();
}

class _RequestInventoryPageState extends State<RequestInventoryPage> {
  final itemID = TextEditingController();
  final quantity = TextEditingController();

  final requestCollection = FirebaseFirestore.instance.collection('inventory_requests');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Request Inventory")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: itemID, decoration: InputDecoration(labelText: 'Item ID')),
            TextField(controller: quantity, decoration: InputDecoration(labelText: 'Requested Quantity'), keyboardType: TextInputType.number),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final requestId = DateTime.now().millisecondsSinceEpoch.toString();
                await requestCollection.doc(requestId).set({
                  'Request_ID': requestId,
                  'Item_ID': itemID.text.trim(),
                  'Requested_Quantity': int.parse(quantity.text),
                  'Request_Date': Timestamp.now(),
                  'Status': 'Pending',
                  'Status_date': Timestamp.now(),
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
