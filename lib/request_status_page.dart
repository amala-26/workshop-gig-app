import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestStatusPage extends StatelessWidget {
  final requests = FirebaseFirestore.instance.collection('inventory_requests');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Request Status")),
      body: StreamBuilder<QuerySnapshot>(
        stream: requests.orderBy('Request_Date', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final data = snapshot.data!.docs;
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, i) {
              final item = data[i].data() as Map<String, dynamic>;
              return ListTile(
                title: Text("Item ID: ${item['Item_ID']}"),
                subtitle: Text("Qty: ${item['Requested_Quantity']} - Status: ${item['Status']}"),
                trailing: Text((item['Request_Date'] as Timestamp).toDate().toString().split(' ')[0]),
              );
            },
          );
        },
      ),
    );
  }
}
