import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddInventoryPage extends StatefulWidget {
  @override
  State<AddInventoryPage> createState() => _AddInventoryPageState();
}

class _AddInventoryPageState extends State<AddInventoryPage> {
  final _formKey = GlobalKey<FormState>();
  final itemName = TextEditingController();
  final quantity = TextEditingController();
  final location = TextEditingController();

  String? selectedCategory;
  String? selectedUnit;
  String? selectedSupplier;

  final List<String> categories = [
    'Tools',
    'Lubricants',
    'Parts',
    'Accessories',
  ];

  final List<String> units = [
    'Pieces',
    'Liters',
    'Boxes',
    'Kilograms',
  ];

  final inventory = FirebaseFirestore.instance.collection('inventory');
  final suppliersRef = FirebaseFirestore.instance.collection('suppliers');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Inventory Item")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(children: [
            TextFormField(
              controller: itemName,
              decoration: InputDecoration(labelText: 'Item Name'),
              validator: (value) => value == null || value.isEmpty ? 'Please enter item name' : null,
            ),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              hint: Text('Select Category'),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
              validator: (value) => value == null ? 'Please select a category' : null,
            ),
            TextFormField(
              controller: quantity,
              decoration: InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
              validator: (value) => value == null || value.isEmpty ? 'Please enter quantity' : null,
            ),
            DropdownButtonFormField<String>(
              value: selectedUnit,
              hint: Text('Select Unit'),
              items: units.map((unit) {
                return DropdownMenuItem(
                  value: unit,
                  child: Text(unit),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedUnit = value;
                });
              },
              validator: (value) => value == null ? 'Please select a unit' : null,
            ),
            TextFormField(
              controller: location,
              decoration: InputDecoration(labelText: 'Storage Location'),
              validator: (value) => value == null || value.isEmpty ? 'Please enter storage location' : null,
            ),
            StreamBuilder<QuerySnapshot>(
              stream: suppliersRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                final suppliers = snapshot.data!.docs.map((doc) => doc['name'] as String).toList();
                return DropdownButtonFormField<String>(
                  value: selectedSupplier,
                  hint: Text('Select Supplier'),
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
                if (_formKey.currentState!.validate()) {
                  String itemId = DateTime.now().millisecondsSinceEpoch.toString();
                  await inventory.doc(itemId).set({
                    'Item_ID': itemId,
                    'Item_Name': itemName.text,
                    'Category': selectedCategory,
                    'Quantity': int.parse(quantity.text),
                    'Unit': selectedUnit,
                    'Storage_Location': location.text,
                    'Supplier': selectedSupplier,
                    'Created_at': Timestamp.now(),
                    'Updated_at': Timestamp.now(),
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Item Added")));
                  Navigator.pop(context);
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Missing Information'),
                      content: Text('Please fill in all required fields.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('OK'),
                        )
                      ],
                    ),
                  );
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
