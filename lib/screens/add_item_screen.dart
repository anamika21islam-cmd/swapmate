import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddItemScreen extends StatefulWidget {
  final VoidCallback? onSaved;
  const AddItemScreen({super.key, this.onSaved});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _wantController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  String _category = 'Electronics';
  String _condition = 'Brand New'; // ডিফল্ট কন্ডিশন
  String _itemType = 'Swap'; // ডিফল্ট টাইপ
  final String _location = 'Dhaka';
  bool _isLoading = false;

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
  final List<String> _itemTypes = ['Swap', 'Gift'];

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please select an image!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = {
        'user_id': user.id,
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'category': _category,
        'condition': _condition,
        'item_type': _itemType,
        'want_to_swap': _itemType == 'Swap'
            ? _wantController.text.trim()
            : null,
        'location': _location,
        'image_url':
            'https://picsum.photos/200/200', // আপলোডের পর এখানে ইমেজ ইউআরএল হবে
        'is_available': true,
      };

      await Supabase.instance.client.from('items').insert(data);
      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else {
        if (widget.onSaved != null) {
          widget.onSaved!();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Item'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.teal),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          size: 50,
                          color: Colors.teal,
                        ),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _condition,
                decoration: const InputDecoration(
                  labelText: 'Condition',
                  border: OutlineInputBorder(),
                ),
                items: _conditions
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _condition = v!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _itemType,
                decoration: const InputDecoration(
                  labelText: 'Item Type',
                  border: OutlineInputBorder(),
                ),
                items: _itemTypes
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _itemType = v!),
              ),
              if (_itemType == 'Swap') ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _wantController,
                  decoration: const InputDecoration(
                    labelText: 'Want to swap for',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(_isLoading ? "Posting..." : "Post Item"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
