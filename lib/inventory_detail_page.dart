import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryDetailPage extends StatelessWidget {
  final String itemId;
  final Map<String, dynamic> itemData;

  const InventoryDetailPage({super.key, required this.itemId, required this.itemData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Item Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item ID: $itemId', style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text('Name: ${itemData['Item_Name'] ?? ''}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text('Category: ${itemData['Category'] ?? ''}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text('Quantity: ${itemData['Quantity'] ?? ''}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text('Unit: ${itemData['Unit'] ?? ''}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text('Storage Location: ${itemData['Storage_Location'] ?? ''}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text('Supplier: ${itemData['Supplier'] ?? 'Not specified'}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 30),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/edit-inventory',
                      arguments: {'itemId': itemId, 'itemData': itemData},
                    );
                  },
                  icon: Icon(Icons.edit),
                  label: Text('Edit'),
                ),
                SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Delete Item'),
                        content: Text('Are you sure you want to delete this item?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await FirebaseFirestore.instance.collection('inventory').doc(itemId).delete();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Item deleted successfully')),
                      );
                    }
                  },
                  icon: Icon(Icons.delete),
                  label: Text('Delete'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
