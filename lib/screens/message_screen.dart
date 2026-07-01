import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../widgets/conversation_tile.dart';
import 'chat_screen.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final ChatService _chatService = ChatService();
  late final Stream<List<Map<String, dynamic>>> _conversationsStream;
  late final Stream<List<Map<String, dynamic>>> _unreadMessagesStream;

  @override
  void initState() {
    super.initState();
    _conversationsStream = _chatService.getConversationsStream();
    _unreadMessagesStream = _chatService.getUnreadMessagesStream();
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    final time = DateTime.tryParse(timestamp);
    if (time == null) return '';
    final local = time.toLocal();
    final now = DateTime.now();

    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      final hour = local.hour > 12
          ? local.hour - 12
          : (local.hour == 0 ? 12 : local.hour);
      final minute = local.minute.toString().padLeft(2, '0');
      final ampm = local.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $ampm';
    } else {
      return '${local.day}/${local.month}/${local.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _unreadMessagesStream,
        builder: (context, unreadSnapshot) {
          final unreadMessages = unreadSnapshot.data ?? [];
          final Map<String, int> unreadCountMap = {};
          for (var msg in unreadMessages) {
            final convId = msg['conversation_id'] as String;
            unreadCountMap[convId] = (unreadCountMap[convId] ?? 0) + 1;
          }

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _conversationsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final conversations = snapshot.data ?? [];

              if (conversations.isEmpty) {
                return const Center(
                  child: Text(
                    'No messages yet.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: conversations.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final conv = conversations[index];
                  final convId = conv['id'] as String;
                  final currentUserId = _chatService.currentUserId;

                  // Support both column naming conventions
                  final p1 = conv['participant_1'] ?? conv['user1_id'];
                  final p2 = conv['participant_2'] ?? conv['user2_id'];
                  final isParticipant1 = p1 == currentUserId;
                  final otherUserId =
                      isParticipant1 ? p2 as String : p1 as String;

                  final lastMessage =
                      conv['last_message'] ?? 'Started a conversation';
                  final lastTime = _formatTime(
                      conv['last_message_time'] ?? conv['created_at']);
                  final unreadCount = unreadCountMap[convId] ?? 0;

                  return StreamBuilder<Map<String, dynamic>?>(
                    stream: _chatService
                        .getPresenceRealtimeStream(otherUserId),
                    builder: (context, profileSnap) {
                      final profileData = profileSnap.data;
                      final otherUserName =
                          profileData?['name'] as String? ?? 'User';
                      final otherUserImageUrl =
                          profileData?['image_url'] as String?;
                      final isOnline =
                          profileData?['is_online'] == true;

                      return ConversationTile(
                        conversationId: convId,
                        otherUserId: otherUserId,
                        otherUserName: otherUserName,
                        otherUserImageUrl: otherUserImageUrl,
                        isOnline: isOnline,
                        lastMessage: lastMessage,
                        lastTime: lastTime,
                        unreadCount: unreadCount,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                conversationId: convId,
                                receiverId: otherUserId,
                                receiverName: otherUserName,
                                receiverImageUrl: otherUserImageUrl,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
