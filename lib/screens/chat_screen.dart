import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/chat_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_header.dart';

class ChatScreen extends StatefulWidget {
  static String? currentActiveConversationId;

  final String conversationId;
  final String receiverId;
  final String receiverName;
  final String? receiverImageUrl;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.receiverId,
    required this.receiverName,
    this.receiverImageUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _messages = [];
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSubscription;
  late final RealtimeChannel _typingChannel;
  
  bool _isOtherUserTyping = false;
  Timer? _typingDebounceTimer;

  @override
  void initState() {
    super.initState();
    ChatScreen.currentActiveConversationId = widget.conversationId;
    _setupMessagesListener();
    _setupTypingIndicator();
    
    // Mark read on open
    _chatService.markMessagesAsRead(widget.conversationId);
  }

  void _setupTypingIndicator() {
    final supabase = Supabase.instance.client;
    _typingChannel = supabase.channel('typing:${widget.conversationId}');
    
    _typingChannel.onBroadcast(
      event: 'typing',
      callback: (payload) {
        if (!mounted) return;
        final senderId = payload['user_id'];
        final isTyping = payload['typing'];
        if (senderId != _chatService.currentUserId) {
          setState(() {
            _isOtherUserTyping = isTyping == true;
          });
        }
      },
    ).subscribe();
  }

  void _onTextChanged(String text) {
    if (_typingDebounceTimer?.isActive ?? false) {
      _typingDebounceTimer!.cancel();
    }
    
    _typingChannel.sendBroadcastMessage(
      event: 'typing',
      payload: {'user_id': _chatService.currentUserId, 'typing': true},
    );

    _typingDebounceTimer = Timer(const Duration(seconds: 2), () {
      _typingChannel.sendBroadcastMessage(
        event: 'typing',
        payload: {'user_id': _chatService.currentUserId, 'typing': false},
      );
    });
  }

  void _setupMessagesListener() {
    _messagesSubscription = _chatService.getMessagesStream(widget.conversationId).listen((data) {
      if (!mounted) return;
      
      setState(() {
        final optimisticMessages = _messages.where((m) => m['status'] == 'sending' || m['status'] == 'failed').toList();
        _messages = List.from(data);
        
        for (final optMsg in optimisticMessages) {
           if (!_messages.any((m) => m['id'] == optMsg['id'])) {
             _messages.add(optMsg);
           }
        }
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      _chatService.markMessagesAsRead(widget.conversationId);
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    
    // Stop typing indicator instantly
    if (_typingDebounceTimer?.isActive ?? false) _typingDebounceTimer!.cancel();
    _typingChannel.sendBroadcastMessage(
      event: 'typing',
      payload: {'user_id': _chatService.currentUserId, 'typing': false},
    );
    
    final newId = _chatService.generateUuid();
    final newMessage = {
      'id': newId,
      'conversation_id': widget.conversationId,
      'sender_id': _chatService.currentUserId,
      'receiver_id': widget.receiverId,
      'message': text,
      'status': 'sending',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    
    setState(() => _messages.add(newMessage));
    _scrollToBottom();

    try {
      final insertedMessage = await _chatService.sendMessage(
        widget.conversationId,
        widget.receiverId,
        text,
        newId,
      );

      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m['id'] == newId);
          if (idx != -1) _messages[idx] = insertedMessage;
        });
      }
    } catch (e, st) {
      debugPrint("SEND MESSAGE ERROR: $e");
      debugPrintStack(stackTrace: st);
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m['id'] == newId);
          if (idx != -1) _messages[idx]['status'] = 'failed';
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    }
  }

  @override
  void dispose() {
    ChatScreen.currentActiveConversationId = null;
    _typingDebounceTimer?.cancel();
    _typingChannel.unsubscribe();
    _messagesSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _chatService.currentUserId;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _chatService.getPresenceStream(widget.receiverId),
          builder: (context, snapshot) {
            final profileData = snapshot.data?.isNotEmpty == true ? snapshot.data!.first : null;
            final isOnline = profileData?['is_online'] == true;
            final lastSeen = profileData?['last_seen'] as String?;
            final updatedName = profileData?['name'] ?? widget.receiverName;
            final updatedImageUrl = profileData?['image_url'] ?? widget.receiverImageUrl;

            return ChatHeader(
              receiverName: updatedName,
              receiverImageUrl: updatedImageUrl,
              isOnline: isOnline,
              lastSeen: lastSeen,
              isTyping: _isOtherUserTyping,
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message['sender_id'] == currentUserId;
                
                // Determine if we should show a date separator
                bool showDate = false;
                if (index == 0) {
                  showDate = true;
                } else {
                  final prevMessage = _messages[index - 1];
                  final currentCreated = DateTime.tryParse(message['created_at'] ?? '')?.toLocal();
                  final prevCreated = DateTime.tryParse(prevMessage['created_at'] ?? '')?.toLocal();
                  if (currentCreated != null && prevCreated != null) {
                    if (currentCreated.day != prevCreated.day || currentCreated.month != prevCreated.month) {
                      showDate = true;
                    }
                  }
                }

                Widget bubble = ChatBubble(message: message, isMe: isMe);
                
                if (showDate) {
                  final date = DateTime.tryParse(message['created_at'] ?? '')?.toLocal();
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          date != null ? '${date.day}/${date.month}/${date.year}' : '',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      bubble,
                    ],
                  );
                }
                
                return bubble;
              },
            ),
          ),
          
          // Input Area
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        onChanged: _onTextChanged,
                        decoration: const InputDecoration(
                          hintText: 'Message...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.teal.shade500,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
