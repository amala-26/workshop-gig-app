import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestStatusPage extends StatelessWidget {
  final requests = FirebaseFirestore.instance.collection('inventory_requests');
  final List<String> statusOptions = ['Pending', 'Completed', 'Cancelled'];

  Color getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      case 'Pending':
      default:
        return Colors.orange;
    }
  }

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
              final doc = data[i];
              final item = doc.data() as Map<String, dynamic>;
              final currentStatus = item['Status'] ?? 'Pending';

              return ListTile(
                title: Text("Item ID: ${item['Item_ID']}"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Qty: ${item['Requested_Quantity']}"),
                    Row(
                      children: [
                        const Text("Status: "),
                        DropdownButton<String>(
                          value: currentStatus,
                          onChanged: (value) async {
                            if (value != null && value != currentStatus) {
                              await requests.doc(doc.id).update({
                                'Status': value,
                                'Status_date': Timestamp.now(),
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Status updated to $value")),
                              );
                            }
                          },
                          items: statusOptions.map((status) {
                            return DropdownMenuItem<String>(
                              value: status,
                              child: Text(
                                status,
                                style: TextStyle(color: getStatusColor(status)),
                              ),
                            );
                          }).toList(),
                          style: TextStyle(
                            color: getStatusColor(currentStatus),
                            fontWeight: FontWeight.bold,
                          ),
                          underline: Container(
                            height: 1,
                            color: getStatusColor(currentStatus),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Text(
                  (item['Request_Date'] as Timestamp).toDate().toString().split(' ')[0],
                  style: TextStyle(fontSize: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
