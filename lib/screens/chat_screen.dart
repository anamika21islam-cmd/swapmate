import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  static String? currentActiveConversationId;

  final String conversationId;
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _supabase = Supabase.instance.client;
  late final String _currentUserId;
  late final Stream<List<Map<String, dynamic>>> _messagesStream;

  Map<String, dynamic>? _conversationData;

  @override
  void initState() {
    super.initState();
    ChatScreen.currentActiveConversationId = widget.conversationId;
    _currentUserId = _supabase.auth.currentUser!.id;
    _messagesStream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', widget.conversationId)
        .order('created_at', ascending: true);

    _markMessagesAsRead();
    _fetchConversationData();
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', widget.conversationId)
          .eq('receiver_id', _currentUserId);
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> _fetchConversationData() async {
    try {
      final response = await _supabase
          .from('conversations')
          .select()
          .eq('id', widget.conversationId)
          .maybeSingle();
      if (response != null && mounted) {
        setState(() {
          _conversationData = response;
        });
      }
    } catch (e) {
      debugPrint('Error fetching conversation: $e');
    }
  }

  @override
  void dispose() {
    ChatScreen.currentActiveConversationId = null;
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      // 1. Insert message
      await _supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': _currentUserId,
        'receiver_id': widget.receiverId,
        'message': text,
        'is_read': false,
      });

      // 2. Update conversation last message
      await _supabase.from('conversations').update({
        'last_message': text,
        'last_message_time': DateTime.now().toIso8601String(),
      }).eq('id', widget.conversationId);

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    final time = DateTime.tryParse(timestamp);
    if (time == null) return '';
    final local = time.toLocal();
    final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                widget.receiverName.isNotEmpty ? widget.receiverName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.receiverName,
                style: const TextStyle(fontSize: 18, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            if (_conversationData != null && _conversationData!['item_name'] != null)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    if (_conversationData!['item_image_url'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _conversationData!['item_image_url'],
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 20, color: Colors.grey),
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Inquiry about',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          Text(
                            _conversationData!['item_name'],
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _messagesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'Say hi to ${widget.receiverName}!',
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }

                  // Auto scroll to bottom when new messages arrive
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg['sender_id'] == _currentUserId;
                      final text = msg['message'] ?? '';
                      final time = _formatTime(msg['created_at']);

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.blue : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                                    bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  text,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isMe ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                time,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
