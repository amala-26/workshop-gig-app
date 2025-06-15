import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditInventoryPage extends StatefulWidget {
  final String itemId;
  final Map<String, dynamic> itemData;

  const EditInventoryPage({Key? key, required this.itemId, required this.itemData}) : super(key: key);

  @override
  State<EditInventoryPage> createState() => _EditInventoryPageState();
}

class _EditInventoryPageState extends State<EditInventoryPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController itemName;
  late TextEditingController quantity;
  late TextEditingController location;

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

  final suppliersRef = FirebaseFirestore.instance.collection('suppliers');

  @override
  void initState() {
    super.initState();
    itemName = TextEditingController(text: widget.itemData['Item_Name']);
    quantity = TextEditingController(text: widget.itemData['Quantity'].toString());
    location = TextEditingController(text: widget.itemData['Storage_Location']);
    selectedCategory = widget.itemData['Category'];
    selectedUnit = widget.itemData['Unit'];
    selectedSupplier = widget.itemData['Supplier'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Inventory Item')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: itemName,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter item name' : null,
              ),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
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
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Please enter quantity' : null,
              ),
              DropdownButtonFormField<String>(
                value: selectedUnit,
                decoration: const InputDecoration(labelText: 'Unit'),
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
                decoration: const InputDecoration(labelText: 'Storage Location'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter storage location' : null,
              ),
              StreamBuilder<QuerySnapshot>(
                stream: suppliersRef.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final suppliers = snapshot.data!.docs.map((doc) => doc['name'] as String).toList();
                  return DropdownButtonFormField<String>(
                    value: selectedSupplier,
                    decoration: const InputDecoration(labelText: 'Supplier'),
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await FirebaseFirestore.instance.collection('inventory').doc(widget.itemId).update({
                      'Item_Name': itemName.text,
                      'Category': selectedCategory,
                      'Quantity': int.parse(quantity.text),
                      'Unit': selectedUnit,
                      'Storage_Location': location.text,
                      'Supplier': selectedSupplier,
                      'Updated_at': Timestamp.now(),
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Item updated successfully")),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Update Item'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
