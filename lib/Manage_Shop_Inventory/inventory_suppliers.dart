import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageSuppliersPage extends StatefulWidget {
  const ManageSuppliersPage({Key? key}) : super(key: key);

  @override
  State<ManageSuppliersPage> createState() => _ManageSuppliersPageState();
}

class _ManageSuppliersPageState extends State<ManageSuppliersPage> {
  final TextEditingController _supplierController = TextEditingController();
  final CollectionReference suppliersRef = FirebaseFirestore.instance.collection('suppliers');

  Future<void> _addSupplier() async {
    final name = _supplierController.text.trim();
    if (name.isNotEmpty) {
      await suppliersRef.add({'name': name});
      _supplierController.clear();
    }
  }

  Future<void> _editSupplier(String docId, String currentName) async {
    _supplierController.text = currentName;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Supplier'),
        content: TextField(
          controller: _supplierController,
          decoration: InputDecoration(labelText: 'Supplier Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newName = _supplierController.text.trim();
              if (newName.isNotEmpty) {
                await suppliersRef.doc(docId).update({'name': newName});
              }
              Navigator.pop(context);
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSupplier(String docId) async {
    await suppliersRef.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Suppliers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _supplierController,
                    decoration: InputDecoration(
                      labelText: 'Add New Supplier',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addSupplier,
                  child: Text('Add'),
                )
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: suppliersRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final name = doc['name'];
                    return ListTile(
                      title: Text(name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _editSupplier(doc.id, name),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteSupplier(doc.id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
