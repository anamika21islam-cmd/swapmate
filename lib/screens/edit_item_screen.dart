import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart'; // To import Item model

class EditItemScreen extends StatefulWidget {
  final Item item;

  const EditItemScreen({super.key, required this.item});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _wantController;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  late String _category;
  late String _condition;
  late String _itemType;
  late String _location;
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _descController = TextEditingController(text: widget.item.description);
    _wantController = TextEditingController(text: widget.item.wantToSwap);
    
    // Validate if the existing value is in the predefined lists, otherwise fallback to default to prevent Dropdown crash.
    _category = _categories.contains(widget.item.category) ? widget.item.category : _categories.first;
    _condition = _conditions.contains(widget.item.condition) ? widget.item.condition : _conditions.first;
    _itemType = _itemTypes.contains(widget.item.itemType) ? widget.item.itemType : _itemTypes.first;
    _location = widget.item.location;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _wantController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _updateItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      if (user.id != widget.item.userId) throw Exception('Unauthorized edit');

      String imageUrl = widget.item.imageUrl;
      
      // If a new image was selected, upload it
      if (_selectedImage != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${user.id}.jpg';
        await Supabase.instance.client.storage
            .from('item_images')
            .upload(fileName, _selectedImage!);
        imageUrl = Supabase.instance.client.storage
            .from('item_images')
            .getPublicUrl(fileName);
      }

      final data = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'category': _category,
        'condition': _condition,
        'item_type': _itemType,
        'want_to_swap': _itemType == 'Swap'
            ? _wantController.text.trim()
            : null,
        'location': _location,
        'image_url': imageUrl,
      };

      await Supabase.instance.client
          .from('items')
          .update(data)
          .eq('id', widget.item.id)
          .eq('user_id', user.id);

      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
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
        automaticallyImplyLeading: false,
        title: const Text('Edit Item'),
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
                    border: Border.all(color: Colors.teal, width: 2),
                    image: _selectedImage == null && widget.item.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(widget.item.imageUrl),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withValues(alpha: 0.3),
                              BlendMode.darken,
                            ),
                          )
                        : null,
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.edit,
                                size: 40,
                                color: Colors.white,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap to change image',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
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
                  onPressed: _isLoading ? null : _updateItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(_isLoading ? "Updating..." : "Save Changes"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
