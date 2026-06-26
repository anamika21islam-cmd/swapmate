import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

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
      SwapRequestItem(
        id: '1',
        itemName: 'iPhone 13 Pro Max',
        ownerName: 'Rahim Khan',
        status: 'pending',
        imageUrl: 'https://picsum.photos/id/0/200/200',
      ),
      SwapRequestItem(
        id: '2',
        itemName: 'Gaming Chair',
        ownerName: 'Sakib Hasan',
        status: 'accepted',
        imageUrl: 'https://picsum.photos/id/26/200/200',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Swap Items',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.indigo.shade600, // 🔥 Changed to Indigo
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
            colors: [Colors.indigo.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _requests.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.swap_horiz,
                      size: 80,
                      color: Colors.indigo.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No swap requests yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.indigo.shade400,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: _requests.length,
                itemBuilder: (context, index) {
                  final req = _requests[index];
                  final isPending = req.status == 'pending';
                  return Card(
                    elevation: 6,
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            isPending
                                ? Colors.amber.shade50
                                : Colors.green.shade50,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            req.imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.image,
                                color: Colors.indigo.shade400,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          req.itemName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          'Owner: ${req.ownerName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isPending
                                ? Colors.amber.shade400
                                : Colors.green.shade400,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: (isPending ? Colors.amber : Colors.green)
                                    .withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            req.status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
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
