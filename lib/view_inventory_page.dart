import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewInventoryPage extends StatelessWidget {
  final CollectionReference inventory =
      FirebaseFirestore.instance.collection('inventory');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Inventory List')),
      body: StreamBuilder<QuerySnapshot>(
        stream: inventory.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['Item_Name'] ?? ''),
                subtitle: Text("Qty: ${data['Quantity']} - ${data['Category']}"),
                trailing: Text(data['Unit']),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => Navigator.pushNamed(context, '/add-inventory'),
      ),
    );
  }
}
