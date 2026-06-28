import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_screen.dart';
import 'add_item_screen.dart';
import 'item_details_screen.dart';
import 'edit_item_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  List<Item> _allItems = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Electronics',
    'Sports',
    'Books',
    'Furniture',
    'Clothing',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase.from('items').select();

      setState(() {
        _allItems = (response as List<dynamic>).map((item) {
          return Item(
            id: item['id']?.toString() ?? '',
            userId: item['user_id']?.toString() ?? '',
            name: item['name']?.toString() ?? 'No Name',
            description: item['description']?.toString() ?? '',
            wantToSwap: item['want_to_swap']?.toString() ?? '',
            imageUrl:
                item['image_url']?.toString() ??
                'https://picsum.photos/200/200',
            ownerName: 'User',
            location: item['location']?.toString() ?? 'Unknown',
            category: item['category']?.toString() ?? 'Other',
            condition: item['condition']?.toString() ?? 'Good',
            itemType: item['item_type']?.toString() ?? 'Swap',
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem(Item item) async {
    try {
      if (!item.imageUrl.contains('picsum.photos')) {
        try {
          final uri = Uri.parse(item.imageUrl);
          final pathSegments = uri.pathSegments;
          if (pathSegments.isNotEmpty) {
            final fileName = pathSegments.last;
            await _supabase.storage.from('item_images').remove([fileName]);
          }
        } catch (e) {
          debugPrint('Storage deletion error: $e');
        }
      }
      await _supabase
          .from('items')
          .delete()
          .eq('id', item.id)
          .eq('user_id', _supabase.auth.currentUser!.id);
      _loadItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Item deleted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    }
  }

  void _confirmDelete(Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteItem(item);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showItemOptions(BuildContext context, Item item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.blue),
                  ),
                  title: const Text(
                    'Edit Post',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () async {
                    Navigator.pop(context); // close bottom sheet
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditItemScreen(item: item),
                      ),
                    );
                    if (result == true) _loadItems();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: const Text(
                    'Delete Post',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context); // close bottom sheet
                    _confirmDelete(item);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _supabase.auth.currentUser?.id;
    List<Item> filteredItems = _selectedCategory == 'All'
        ? _allItems
        : _allItems
              .where((item) => item.category == _selectedCategory)
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SwapMate',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.green.shade700,
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 5,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _selectedCategory == category
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: _selectedCategory == category
                            ? Colors.green
                            : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddItemScreen()),
          );
          if (result == true) _loadItems();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredItems.isEmpty
          ? const Center(child: Text('No items found'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final isOwner = currentUserId == item.userId;

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    // 🔥 এখানে onTap যুক্ত করা হয়েছে
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemDetailsScreen(item: item),
                        ),
                      );
                    },
                    leading: Image.network(
                      item.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                    title: Row(
                      children: [
                        Text(item.name),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: item.itemType == 'Swap'
                                ? Colors.teal.shade100
                                : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            item.itemType,
                            style: TextStyle(
                              fontSize: 10,
                              color: item.itemType == 'Swap'
                                  ? Colors.teal
                                  : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text('${item.category} | ${item.location}'),
                    trailing: isOwner
                        ? IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () => _showItemOptions(context, item),
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}

// Item ক্লাসের ডেফিনিশনটি এখানে আছে
class Item {
  final String id,
      userId,
      name,
      description,
      wantToSwap,
      imageUrl,
      ownerName,
      location,
      category,
      condition,
      itemType;

  Item({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.wantToSwap,
    required this.imageUrl,
    required this.ownerName,
    required this.location,
    required this.category,
    required this.condition,
    required this.itemType,
  });
}
