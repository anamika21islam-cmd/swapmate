import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final _supabase = Supabase.instance.client;
  late final String _currentUserId;
  late final Stream<List<Map<String, dynamic>>> _conversationsStream;
  late final Stream<List<Map<String, dynamic>>> _unreadMessagesStream;

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabase.auth.currentUser!.id;
    _conversationsStream = _supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        .order('last_message_time', ascending: false)
        .map((conversations) => conversations.where((c) => c['participant_1'] == _currentUserId || c['participant_2'] == _currentUserId).toList());

    _unreadMessagesStream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', _currentUserId)
        .map((messages) => messages.where((m) => m['is_read'] == false).toList());
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    final time = DateTime.tryParse(timestamp);
    if (time == null) return '';
    final local = time.toLocal();
    final now = DateTime.now();
    
    if (local.year == now.year && local.month == now.month && local.day == now.day) {
      final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
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
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)),
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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final conversations = snapshot.data ?? [];

              if (conversations.isEmpty) {
                return const Center(
                  child: Text('No messages yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                );
              }

              return ListView.separated(
                itemCount: conversations.length,
                separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
                itemBuilder: (context, index) {
                  final conv = conversations[index];
                  final convId = conv['id'];
                  final isParticipant1 = conv['participant_1'] == _currentUserId;
                  final otherUserId = isParticipant1 ? conv['participant_2'] : conv['participant_1'];
                  final otherUserName = isParticipant1 ? conv['participant_2_name'] ?? 'User' : conv['participant_1_name'] ?? 'User';
                  
                  final lastMessage = conv['last_message'] ?? 'Started a conversation';
                  final lastTime = _formatTime(conv['last_message_time'] ?? conv['created_at']);
                  final unreadCount = unreadCountMap[convId] ?? 0;

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            conversationId: convId,
                            receiverId: otherUserId,
                            receiverName: otherUserName,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.blue.withValues(alpha: 0.1),
                            child: Text(
                              otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        otherUserName,
                                        style: TextStyle(
                                          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      lastTime,
                                      style: TextStyle(
                                        color: unreadCount > 0 ? Colors.blue : Colors.grey,
                                        fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        lastMessage,
                                        style: TextStyle(
                                          color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                                          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (unreadCount > 0)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
