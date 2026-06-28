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

      String imageUrl = '';
      if (_selectedImage != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${user.id}.jpg';
        await Supabase.instance.client.storage
            .from('item_images')
            .upload(fileName, _selectedImage!);
        imageUrl = Supabase.instance.client.storage
            .from('item_images')
            .getPublicUrl(fileName);
      } else {
        imageUrl = 'https://picsum.photos/200/200';
      }

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
        'image_url': imageUrl,
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

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      prefixIcon: Icon(icon, color: const Color(0xFF16A34A)),
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF16A34A), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: Column(
        children: [
          // Premium Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              right: 20,
              bottom: 30,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF16A34A), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48), // Match roughly the size of the previous IconButton to keep layout balanced
                    const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 28),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Add Item',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Share something amazing',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Form Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Upload Photo Component
                    const Text(
                      'Photos',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: _selectedImage != null
                            ? Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedImage = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.cloud_upload_outlined,
                                      size: 40,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Upload Photos',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap to add photos',
                                    style: TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Item Details Section
                    const Text(
                      'Item Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: _buildInputDecoration('Item Name', Icons.label_outline),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _category,
                            decoration: _buildInputDecoration('Category', Icons.category_outlined),
                            icon: const Icon(Icons.expand_more, color: Color(0xFF16A34A)),
                            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) => setState(() => _category = v!),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _condition,
                            decoration: _buildInputDecoration('Condition', Icons.star_border_outlined),
                            icon: const Icon(Icons.expand_more, color: Color(0xFF16A34A)),
                            items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) => setState(() => _condition = v!),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _itemType,
                            decoration: _buildInputDecoration('Item Type', Icons.swap_horiz_outlined),
                            icon: const Icon(Icons.expand_more, color: Color(0xFF16A34A)),
                            items: _itemTypes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) => setState(() => _itemType = v!),
                          ),
                          
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: _itemType == 'Swap'
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: TextFormField(
                                      controller: _wantController,
                                      decoration: _buildInputDecoration('Want to swap for', Icons.sync_alt),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descController,
                            decoration: _buildInputDecoration('Description', Icons.description_outlined).copyWith(
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Post Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF16A34A), Color(0xFF10B981)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    "Posting...",
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send_rounded, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text(
                                    "Post Item",
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
