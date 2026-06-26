import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'profile_screen.dart'; // 🔥 Import Profile

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Item> _allItems = [];
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

  void _loadItems() {
    _allItems = [
      Item(
        id: '1',
        name: 'iPhone 13 Pro Max',
        description: 'Like new, 256GB',
        wantToSwap: 'Samsung S22 Ultra',
        imageUrl: 'https://picsum.photos/id/0/200/200',
        ownerName: 'Rahim',
        location: 'Dhaka',
        category: 'Electronics',
        condition: 'Like New',
      ),
      Item(
        id: '2',
        name: 'Mountain Bike',
        description: 'Giant brand, 21 gears',
        wantToSwap: 'Gym equipment',
        imageUrl: 'https://picsum.photos/id/20/200/200',
        ownerName: 'Karim',
        location: 'Chittagong',
        category: 'Sports',
        condition: 'Good',
      ),
      Item(
        id: '3',
        name: 'English Grammar Book',
        description: 'Cambridge University Press',
        wantToSwap: 'Any novel',
        imageUrl: 'https://picsum.photos/id/24/200/200',
        ownerName: 'Fatema',
        location: 'Dhaka',
        category: 'Books',
        condition: 'Like New',
      ),
      Item(
        id: '4',
        name: 'Gaming Chair',
        description: 'High back, adjustable',
        wantToSwap: 'Monitor',
        imageUrl: 'https://picsum.photos/id/26/200/200',
        ownerName: 'Sakib',
        location: 'Sylhet',
        category: 'Furniture',
        condition: 'Good',
      ),
      Item(
        id: '5',
        name: 'Sony Headphones',
        description: 'Wireless, noise cancel',
        wantToSwap: 'Smartwatch',
        imageUrl: 'https://picsum.photos/id/30/200/200',
        ownerName: 'Nadia',
        location: 'Dhaka',
        category: 'Electronics',
        condition: 'Like New',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    List<Item> filteredItems = _allItems;
    if (_selectedCategory != 'All') {
      filteredItems = _allItems
          .where((item) => item.category == _selectedCategory)
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SwapMate',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          // 🔥 Logout সরিয়ে Profile আইকন দিলাম
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.green.shade700,
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.green.shade700
                            : Colors.white,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: filteredItems.isEmpty
          ? const Center(
              child: Text(
                'No items found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item.imageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${item.category} | ${item.location}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'Wants: ${item.wantToSwap}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _showSwapDialog(context, item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        'Swap',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showSwapDialog(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Swap Request'),
        content: Text(
          'Send swap request to ${item.ownerName} for ${item.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Request sent to ${item.ownerName}!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

class Item {
  final String id,
      name,
      description,
      wantToSwap,
      imageUrl,
      ownerName,
      location,
      category,
      condition;
  Item({
    required this.id,
    required this.name,
    required this.description,
    required this.wantToSwap,
    required this.imageUrl,
    required this.ownerName,
    required this.location,
    required this.category,
    required this.condition,
  });
}
