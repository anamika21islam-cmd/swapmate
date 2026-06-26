import 'package:flutter/material.dart';
import 'login_screen.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  List<ChatUser> _chats = [];

  @override
  void initState() {
    super.initState();
    _chats = [
      ChatUser(
        id: '1',
        name: 'Rahim Khan',
        lastMessage: 'Do you still have the iPhone?',
        time: '10:30 AM',
        imageUrl: 'https://picsum.photos/id/1/50/50',
        unread: 2,
      ),
      ChatUser(
        id: '2',
        name: 'Karim Ahmed',
        lastMessage: 'I am interested in your bike',
        time: 'Yesterday',
        imageUrl: 'https://picsum.photos/id/2/50/50',
        unread: 0,
      ),
      ChatUser(
        id: '3',
        name: 'Fatema Begum',
        lastMessage: 'Swap request accepted!',
        time: 'Yesterday',
        imageUrl: 'https://picsum.photos/id/3/50/50',
        unread: 1,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: Container(
        color: Colors.pink.shade50,
        child: _chats.isEmpty
            ? const Center(
                child: Text(
                  'No messages yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.pink,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _chats.length,
                itemBuilder: (context, index) {
                  final chat = _chats[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.pink.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(chat.imageUrl),
                          child: chat.imageUrl.isEmpty
                              ? const Icon(Icons.person, color: Colors.pink)
                              : null,
                        ),
                        title: Text(
                          chat.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          chat.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              chat.time,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                            if (chat.unread > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 5),
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Colors.pink,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${chat.unread}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onTap: () => _showChatDialog(context, chat),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showChatDialog(BuildContext context, ChatUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.name, style: const TextStyle(color: Colors.pink)),
        content: SizedBox(
          height: 300,
          width: 300,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    _buildBubble('Hi, is the item still available?', true),
                    _buildBubble('Yes, it is available', false),
                    _buildBubble('I want to swap', true),
                    _buildBubble('Ok, let me know when', false),
                  ],
                ),
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.pink),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message sent!')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.all(5),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe ? Colors.pink : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(color: isMe ? Colors.white : Colors.black),
        ),
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

class ChatUser {
  final String id, name, lastMessage, time, imageUrl;
  final int unread;
  ChatUser({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.imageUrl,
    required this.unread,
  });
}
