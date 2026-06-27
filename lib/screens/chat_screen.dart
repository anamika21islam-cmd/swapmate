import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final String ownerId;
  final String ownerName;

  const ChatScreen({super.key, required this.ownerId, required this.ownerName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat with $ownerName")),
      body: Center(
        child: Text(
          "Chatting with user ID: $ownerId\n(Implement real-time chat here)",
        ),
      ),
    );
  }
}
