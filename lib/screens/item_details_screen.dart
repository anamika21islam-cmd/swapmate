import 'package:flutter/material.dart';
import 'home_screen.dart'; // Item class টি এখানে আছে
import 'chat_screen.dart'; // নতুন চ্যাট স্ক্রিন
import 'package:supabase_flutter/supabase_flutter.dart';

class ItemDetailsScreen extends StatelessWidget {
  final Item item;

  const ItemDetailsScreen({super.key, required this.item});

  Future<void> _openChat(BuildContext context) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to send a message.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await Supabase.instance.client
          .from('conversations')
          .select()
          .or('and(participant_1.eq.$currentUserId,participant_2.eq.${item.userId}),and(participant_1.eq.${item.userId},participant_2.eq.$currentUserId)')
          .maybeSingle();

      String conversationId;
      if (response != null) {
        conversationId = response['id'];
      } else {
        // Fetch current user name
        final profileResponse = await Supabase.instance.client
            .from('profiles')
            .select('name')
            .eq('id', currentUserId)
            .maybeSingle();
        final currentUserName = profileResponse != null ? profileResponse['name'] as String : 'Unknown';

        final insertResponse = await Supabase.instance.client
            .from('conversations')
            .insert({
              'participant_1': currentUserId,
              'participant_2': item.userId,
              'participant_1_name': currentUserName,
              'participant_2_name': item.ownerName,
              'item_id': item.id,
              'item_name': item.name,
              'item_image_url': item.imageUrl,
            })
            .select()
            .single();
        conversationId = insertResponse['id'];
      }

      if (!context.mounted) return;
      Navigator.pop(context); 

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: conversationId,
            receiverId: item.userId,
            receiverName: item.ownerName,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to start conversation. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = Supabase.instance.client.auth.currentUser?.id == item.userId;

    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                item.imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: item.itemType == 'Swap'
                              ? Colors.teal
                              : Colors.orange,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          item.itemType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Posted by: ${item.ownerName}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    "Category: ${item.category} | Location: ${item.location}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Description:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(item.description),
                  const SizedBox(height: 10),
                  if (item.itemType == 'Swap') ...[
                    const Text(
                      "Wants to swap for:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      item.wantToSwap,
                      style: const TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isOwner ? null : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openChat(context),
                icon: const Icon(Icons.message),
                label: const Text("Message"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "${item.itemType} request sent to ${item.ownerName}!",
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  item.itemType == 'Swap'
                      ? "Send Swap Request"
                      : "Request Gift",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
