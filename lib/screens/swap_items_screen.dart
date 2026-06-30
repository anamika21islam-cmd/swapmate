import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_screen.dart';
import 'home_screen.dart';
import 'item_details_screen.dart';

class SwapItemsScreen extends StatefulWidget {
  const SwapItemsScreen({super.key});

  @override
  State<SwapItemsScreen> createState() => _SwapItemsScreenState();
}

class _SwapItemsScreenState extends State<SwapItemsScreen> {
  List<SwapRequestItem> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSwapItems();
  }

  Future<void> _loadSwapItems() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('items')
          .select()
          .eq('item_type', 'Swap');

      setState(() {
        _requests = (response as List<dynamic>).map((item) {
          final fullItem = Item(
            id: item['id']?.toString() ?? '',
            userId: item['user_id']?.toString() ?? '',
            name: item['name']?.toString() ?? 'No Name',
            description: item['description']?.toString() ?? '',
            wantToSwap: item['want_to_swap']?.toString() ?? '',
            imageUrl: item['image_url']?.toString() ?? 'https://picsum.photos/200/200',
            ownerName: 'User',
            location: item['location']?.toString() ?? 'Unknown',
            category: item['category']?.toString() ?? 'Other',
            condition: item['condition']?.toString() ?? 'Good',
            itemType: item['item_type']?.toString() ?? 'Swap',
          );
          return SwapRequestItem(
            id: item['id']?.toString() ?? '',
            itemName: item['name']?.toString() ?? 'No Name',
            ownerName: 'User', // Usually would fetch from profiles table
            status: (item['is_available'] == true) ? 'Available' : 'Swapped',
            imageUrl: item['image_url']?.toString() ?? 'https://picsum.photos/200/200',
            fullItem: fullItem,
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendSwapRequest(Item item) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to send a request.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (item.userId == user.id) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot request your own item.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      final existingRequest = await Supabase.instance.client
          .from('requests')
          .select()
          .eq('sender_id', user.id)
          .eq('item_id', item.id)
          .maybeSingle();

      if (existingRequest != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You have already sent a request for this item.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
          );
        }
        return;
      }

      await Supabase.instance.client.from('requests').insert({
        'item_id': item.id,
        'item_name': item.name,
        'item_type': 'Swap',
        'sender_id': user.id,
        'receiver_id': item.userId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Swap request sent successfully.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending request: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    }
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
        backgroundColor: Colors.blue, // 🔥 Changed to Blue
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
            colors: [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.blue))
            : _requests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.swap_horiz,
                          size: 80,
                          color: Colors.blue.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No swap items yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade400,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: _requests.length,
                itemBuilder: (context, index) {
                  final req = _requests[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemDetailsScreen(item: req.fullItem),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.blue.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child: Image.network(
                                      req.imageUrl,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.image,
                                        size: 60,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    req.itemName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    'Owner: ${req.ownerName}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              req.status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => _sendSwapRequest(req.fullItem),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Swap Request',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
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
  final Item fullItem;
  SwapRequestItem({
    required this.id,
    required this.itemName,
    required this.ownerName,
    required this.status,
    required this.imageUrl,
    required this.fullItem,
  });
}
