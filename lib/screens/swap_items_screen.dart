import 'package:flutter/material.dart';
import 'login_screen.dart';

class SwapItemsScreen extends StatefulWidget {
  const SwapItemsScreen({super.key});

  @override
  State<SwapItemsScreen> createState() => _SwapItemsScreenState();
}

class _SwapItemsScreenState extends State<SwapItemsScreen> {
  List<SwapRequestItem> _requests = [];

  @override
  void initState() {
    super.initState();
    _requests = [
      SwapRequestItem(id: '1', itemName: 'iPhone 13 Pro Max', ownerName: 'Rahim Khan', status: 'pending', imageUrl: 'https://picsum.photos/id/0/200/200'),
      SwapRequestItem(id: '2', itemName: 'Gaming Chair', ownerName: 'Sakib Hasan', status: 'accepted', imageUrl: 'https://picsum.photos/id/26/200/200'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swap Items'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _showLogoutDialog(context)),
        ],
      ),
      body: _requests.isEmpty
          ? const Center(child: Text('No swap requests yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final req = _requests[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(req.imageUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image)),
                    ),
                    title: Text(req.itemName),
                    subtitle: Text('Owner: ${req.ownerName}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: req.status == 'pending' ? Colors.orange : Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(req.status, style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                );
              },
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class SwapRequestItem {
  final String id, itemName, ownerName, status, imageUrl;
  SwapRequestItem({
    required this.id,
    required this.itemName,
    required this.ownerName,
    required this.status,
    required this.imageUrl,
  });
}