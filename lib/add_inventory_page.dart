import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddInventoryPage extends StatefulWidget {
  @override
  State<AddInventoryPage> createState() => _AddInventoryPageState();
}

class _AddInventoryPageState extends State<AddInventoryPage> {
  final _formKey = GlobalKey<FormState>();
  final itemName = TextEditingController();
  final category = TextEditingController();
  final quantity = TextEditingController();
  final unit = TextEditingController();
  final location = TextEditingController();

  final inventory = FirebaseFirestore.instance.collection('inventory');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Inventory Item")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(children: [
            TextFormField(controller: itemName, decoration: InputDecoration(labelText: 'Item Name')),
            TextFormField(controller: category, decoration: InputDecoration(labelText: 'Category')),
            TextFormField(controller: quantity, decoration: InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
            TextFormField(controller: unit, decoration: InputDecoration(labelText: 'Unit')),
            TextFormField(controller: location, decoration: InputDecoration(labelText: 'Storage Location')),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  String itemId = DateTime.now().millisecondsSinceEpoch.toString();
                  await inventory.doc(itemId).set({
                    'Item_ID': itemId,
                    'Item_Name': itemName.text,
                    'Category': category.text,
                    'Quantity': int.parse(quantity.text),
                    'Unit': unit.text,
                    'Storage_Location': location.text,
                    'Created_at': Timestamp.now(),
                    'Updated_at': Timestamp.now(),
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Item Added")));
                  Navigator.pop(context);
                }
              },
              child: Text("Add Item"),
            )
          ]),
        ),
      ),
    );
  }
}
