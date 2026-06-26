import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'profile_screen.dart'; // 🔥 Import

class AllItemsScreen extends StatefulWidget {
  const AllItemsScreen({super.key});

  @override
  State<AllItemsScreen> createState() => _AllItemsScreenState();
}

class _AllItemsScreenState extends State<AllItemsScreen> {
  List<AllItem> _allItems = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    _allItems = [
      AllItem(
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
      AllItem(
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
      AllItem(
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
      AllItem(
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
      AllItem(
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Items',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          // 🔥 Profile Icon Added
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
        color: Colors.blue.shade50,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _allItems.length,
          itemBuilder: (context, index) {
            final item = _allItems[index];
            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.blue.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image, color: Colors.blue),
                    ),
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${item.category} | ${item.location} | Wants: ${item.wantToSwap}',
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _showSwapDialog(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
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
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSwapDialog(AllItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Swap Request'),
          content: Text('Send request to ${item.ownerName} for ${item.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Request sent to ${item.ownerName}')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }
}

class AllItem {
  final String id,
      name,
      description,
      wantToSwap,
      imageUrl,
      ownerName,
      location,
      category,
      condition;
  AllItem({
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
