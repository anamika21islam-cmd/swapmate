import 'package:flutter/material.dart';
import 'profile_screen.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _wantController = TextEditingController();
  String _category = 'Electronics';
  String _condition = 'Like New';
  String _location = 'Dhaka';
  String _itemType = 'Swap';

  final List<String> _categories = [
    'Electronics',
    'Sports',
    'Books',
    'Furniture',
    'Clothing',
    'Other',
  ];
  final List<String> _conditions = [
    'Brand New',
    'Like New',
    'Good',
    'Fair',
    'Poor',
  ];
  final List<String> _locations = [
    'Dhaka',
    'Chittagong',
    'Sylhet',
    'Rajshahi',
    'Khulna',
    'Barisal',
    'Rangpur',
    'Mymensingh',
  ];
  final List<String> _itemTypes = ['Swap', 'Gift'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Item',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal, // 🔥 Changed to Teal
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Item Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  labelStyle: TextStyle(color: Colors.teal.shade700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.teal.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.teal, width: 2),
                  ),
                  prefixIcon: Icon(Icons.label, color: Colors.teal),
                ),
                validator: (v) => v!.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 14),

              // Category
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: _categories.map((c) {
                  return DropdownMenuItem<String>(value: c, child: Text(c));
                }).toList(),
                onChanged: (v) => setState(() => _category = v!),
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: Colors.teal.shade700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.teal.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.teal, width: 2),
                  ),
                  prefixIcon: Icon(Icons.category, color: Colors.teal),
                ),
              ),
              const SizedBox(height: 14),

              // Description
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.teal.shade700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.teal.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.teal, width: 2),
                  ),
                  prefixIcon: Icon(Icons.description, color: Colors.teal),
                ),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 14),

              // Condition
              DropdownButtonFormField<String>(
                initialValue: _condition,
                items: _conditions.map((c) {
                  return DropdownMenuItem<String>(value: c, child: Text(c));
                }).toList(),
                onChanged: (v) => setState(() => _condition = v!),
                decoration: InputDecoration(
                  labelText: 'Condition',
                  labelStyle: TextStyle(color: Colors.teal.shade700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.teal.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.teal, width: 2),
                  ),
                  prefixIcon: Icon(Icons.fact_check, color: Colors.teal),
                ),
              ),
              const SizedBox(height: 14),

              // Item Type (Swap / Gift)
              DropdownButtonFormField<String>(
                initialValue: _itemType,
                items: _itemTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Row(
                      children: [
                        Icon(
                          type == 'Swap'
                              ? Icons.swap_horiz
                              : Icons.card_giftcard,
                          color: type == 'Swap' ? Colors.teal : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(type),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _itemType = v!),
                decoration: InputDecoration(
                  labelText: 'Item Type',
                  labelStyle: TextStyle(color: Colors.teal.shade700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.teal.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.teal, width: 2),
                  ),
                  prefixIcon: Icon(Icons.swap_vert, color: Colors.teal),
                ),
              ),
              const SizedBox(height: 14),

              // Want to swap for (only for Swap)
              if (_itemType == 'Swap') ...[
                TextFormField(
                  controller: _wantController,
                  decoration: InputDecoration(
                    labelText: 'Want to swap for',
                    labelStyle: TextStyle(color: Colors.teal.shade700),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.teal.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.teal, width: 2),
                    ),
                    prefixIcon: Icon(Icons.swap_horiz, color: Colors.teal),
                  ),
                  validator: (v) {
                    if (_itemType == 'Swap' && (v == null || v.isEmpty)) {
                      return 'Enter what you want';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
              ],

              // Location
              DropdownButtonFormField<String>(
                initialValue: _location,
                items: _locations.map((l) {
                  return DropdownMenuItem<String>(value: l, child: Text(l));
                }).toList(),
                onChanged: (v) => setState(() => _location = v!),
                decoration: InputDecoration(
                  labelText: 'Location',
                  labelStyle: TextStyle(color: Colors.teal.shade700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.teal.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.teal, width: 2),
                  ),
                  prefixIcon: Icon(Icons.location_on, color: Colors.teal),
                ),
              ),
              const SizedBox(height: 24),

              // 🔥 Post Button (Teal)
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _itemType == 'Swap'
                              ? '✅ Item added for Swap!'
                              : '🎁 Item added as Gift!',
                        ),
                        backgroundColor: Colors.teal,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _itemType == 'Swap'
                          ? Icons.swap_horiz
                          : Icons.card_giftcard,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _itemType == 'Swap' ? 'Post as Swap' : 'Post as Gift 🎁',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
