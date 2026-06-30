import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_screen.dart'; // 🔥 Import
import 'home_screen.dart';
import 'item_details_screen.dart';

class GiftScreen extends StatefulWidget {
  const GiftScreen({super.key});

  @override
  State<GiftScreen> createState() => _GiftScreenState();
}

class _GiftScreenState extends State<GiftScreen> {
  List<GiftItem> _gifts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  Future<void> _loadGifts() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('items')
          .select()
          .eq('item_type', 'Gift');

      setState(() {
        _gifts = (response as List<dynamic>).map((item) {
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
            itemType: item['item_type']?.toString() ?? 'Gift',
          );
          return GiftItem(
            id: item['id']?.toString() ?? '',
            name: item['name']?.toString() ?? 'No Name',
            price: 'Free', // Gifts are usually free
            imageUrl: item['image_url']?.toString() ?? 'https://picsum.photos/200/200',
            description: item['description']?.toString() ?? '',
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

  Future<void> _sendGiftRequest(Item item) async {
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
        'item_type': 'Gift',
        'sender_id': user.id,
        'receiver_id': item.userId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gift request sent successfully.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
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
          'Gift Items',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.green))
            : _gifts.isEmpty
                ? const Center(
                    child: Text(
                      'No gifts available',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
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
                itemCount: _gifts.length,
                itemBuilder: (context, index) {
                  final gift = _gifts[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemDetailsScreen(item: gift.fullItem),
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
                          colors: [Colors.white, Colors.green.shade50],
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
                                      gift.imageUrl,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.card_giftcard,
                                        size: 60,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    gift.name,
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
                                    gift.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
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
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              gift.price,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => _sendGiftRequest(gift.fullItem),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Gift Request',
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

class GiftItem {
  final String id, name, price, imageUrl, description;
  final Item fullItem;
  GiftItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.fullItem,
  });
}
