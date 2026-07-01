import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/chat_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_header.dart';

class ChatScreen extends StatefulWidget {
  /// Tracks which conversation is currently open so that snackbars
  /// in DashboardWrapper are suppressed for the active conversation.
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
  StreamSubscription<Map<String, dynamic>?>? _presenceSubscription;
  late final RealtimeChannel _typingChannel;

  Map<String, dynamic>? _receiverProfile;
  bool _isOtherUserTyping = false;
  Timer? _typingDebounceTimer;

  @override
  void initState() {
    super.initState();
    ChatScreen.currentActiveConversationId = widget.conversationId;
    _setupMessagesListener();
    _setupPresenceListener();
    _setupTypingIndicator();
    _markReadOnOpen();
  }

  void _markReadOnOpen() {
    // Slight delay so messages load first
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _chatService.markMessagesAsRead(widget.conversationId);
      }
    });
  }

  // ─── Typing Indicator ────────────────────────────────────────────────────────
  void _setupTypingIndicator() {
    final supabase = Supabase.instance.client;
    _typingChannel = supabase.channel('typing:${widget.conversationId}');

    _typingChannel
        .onBroadcast(
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
        )
        .subscribe();
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

  // ─── Presence Listener ───────────────────────────────────────────────────────
  void _setupPresenceListener() {
    _presenceSubscription = _chatService
        .getPresenceRealtimeStream(widget.receiverId)
        .listen((profileData) {
      if (!mounted) return;
      setState(() {
        _receiverProfile = profileData;
      });
    });
  }

  // ─── Messages Listener ───────────────────────────────────────────────────────
  void _setupMessagesListener() {
    _messagesSubscription =
        _chatService.getMessagesStream(widget.conversationId).listen((data) {
      if (!mounted) return;

      setState(() {
        // Merge server data with any local optimistic messages still pending
        final optimisticMessages = _messages
            .where((m) => m['status'] == 'sending' || m['status'] == 'failed')
            .toList();

        _messages = List.from(data);

        for (final optMsg in optimisticMessages) {
          if (!_messages.any((m) => m['id'] == optMsg['id'])) {
            _messages.add(optMsg);
          }
        }

        // Keep sorted by created_at
        _messages.sort((a, b) {
          final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(0);
          final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(0);
          return aTime.compareTo(bTime);
        });
      });

      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToBottom(animated: false));

      // Mark messages as read whenever we receive an update
      _chatService.markMessagesAsRead(widget.conversationId);
    });
  }

  // ─── Scroll ──────────────────────────────────────────────────────────────────
  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    if (animated) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  // ─── Send Message ─────────────────────────────────────────────────────────────
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    // Stop typing indicator
    if (_typingDebounceTimer?.isActive ?? false) _typingDebounceTimer!.cancel();
    _typingChannel.sendBroadcastMessage(
      event: 'typing',
      payload: {'user_id': _chatService.currentUserId, 'typing': false},
    );

    final newId = _chatService.generateUuid();
    final optimisticMessage = {
      'id': newId,
      'conversation_id': widget.conversationId,
      'sender_id': _chatService.currentUserId,
      'receiver_id': widget.receiverId,
      'message': text,
      'status': 'sending',
      'is_read': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    setState(() => _messages.add(optimisticMessage));
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToBottom(animated: true));

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
    } catch (e) {
      debugPrint("SEND MESSAGE ERROR: $e");
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m['id'] == newId);
          if (idx != -1) _messages[idx]['status'] = 'failed';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── Dispose ─────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    ChatScreen.currentActiveConversationId = null;
    _typingDebounceTimer?.cancel();
    _typingChannel.unsubscribe();
    _messagesSubscription?.cancel();
    _presenceSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final currentUserId = _chatService.currentUserId;

    final isOnline = _receiverProfile?['is_online'] == true;
    final lastSeen = _receiverProfile?['last_seen'] as String?;
    final updatedName =
        _receiverProfile?['name'] as String? ?? widget.receiverName;
    final updatedImageUrl =
        _receiverProfile?['image_url'] as String? ?? widget.receiverImageUrl;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: ChatHeader(
        receiverName: updatedName,
        receiverImageUrl: updatedImageUrl,
        isOnline: isOnline,
        lastSeen: lastSeen,
        isTyping: _isOtherUserTyping,
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

                // Date separator
                bool showDate = false;
                if (index == 0) {
                  showDate = true;
                } else {
                  final prev = _messages[index - 1];
                  final cur = DateTime.tryParse(
                          message['created_at'] ?? '')
                      ?.toLocal();
                  final pre =
                      DateTime.tryParse(prev['created_at'] ?? '')?.toLocal();
                  if (cur != null && pre != null) {
                    if (cur.day != pre.day ||
                        cur.month != pre.month ||
                        cur.year != pre.year) {
                      showDate = true;
                    }
                  }
                }

                final bubble = ChatBubble(message: message, isMe: isMe);

                if (showDate) {
                  final date =
                      DateTime.tryParse(message['created_at'] ?? '')?.toLocal();
                  final dateStr = date != null
                      ? _formatDate(date)
                      : '';
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            dateStr,
                            style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
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
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _messageController,
                        onChanged: _onTextChanged,
                        decoration: const InputDecoration(
                          hintText: 'Message...',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
