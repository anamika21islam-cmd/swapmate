import 'package:flutter/material.dart';

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
        title: const Text('SwapMate'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Category',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              DropdownButton<String>(
                value: _selectedCategory,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                dropdownColor: Colors.green,
                underline: const SizedBox(),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (newValue) =>
                    setState(() => _selectedCategory = newValue!),
              ),
            ],
          ),
        ),
        actions: [
          // person icon - profile screen e jabe
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: filteredItems.isEmpty
          ? const Center(child: Text('No items found'))
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image, size: 50),
                      ),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item.category} | ${item.location}'),
                        Text(
                          'Wants: ${item.wantToSwap}',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _showSwapDialog(context, item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Swap',
                        style: TextStyle(color: Colors.white),
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
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
