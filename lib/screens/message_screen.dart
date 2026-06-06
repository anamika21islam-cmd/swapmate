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
        unread: 1,
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
        title: const Text('Messages'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
        // back button add kora
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
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
      body: _chats.isEmpty
          ? const Center(child: Text('No messages yet'))
          : ListView.builder(
              itemCount: _chats.length,
              itemBuilder: (context, index) {
                final chat = _chats[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(chat.imageUrl),
                    child: chat.imageUrl.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    chat.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                      if (chat.unread > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.green,
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
                );
              },
            ),
    );
  }

  void _showChatDialog(BuildContext context, ChatUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.name),
        content: SizedBox(
          height: 350,
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
                    icon: const Icon(Icons.send, color: Colors.green),
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
          color: isMe ? Colors.green : Colors.grey[300],
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
