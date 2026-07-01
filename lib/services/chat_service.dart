import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  String generateUuid() {
    final random = Random();
    final chars = '0123456789abcdef';
    String build(int length) => List.generate(length, (index) => chars[random.nextInt(16)]).join();
    return '${build(8)}-${build(4)}-4${build(3)}-a${build(3)}-${build(12)}';
  }

  // ============================
  // presence
  // ============================
  Future<void> updatePresence(bool isOnline) async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      await _supabase.from('profiles').update({
        'is_online': isOnline,
        'last_seen': DateTime.now().toUtc().toIso8601String(),
      }).eq('user_id', userId);
    } catch (e) {
      debugPrint('Error updating presence: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getPresenceStream(String userId) {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId);
  }

  // ============================
  // message queries
  // ============================
  Stream<List<Map<String, dynamic>>> getConversationsStream() {
    final userId = currentUserId;
    if (userId == null) return const Stream.empty();
    
    return _supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        .order('last_message_time', ascending: false)
        .map((conversations) => conversations.where((c) => c['user1_id'] == userId || c['user2_id'] == userId).toList());
  }

  Stream<List<Map<String, dynamic>>> getUnreadMessagesStream() {
    final userId = currentUserId;
    if (userId == null) return const Stream.empty();

    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', userId)
        .map((messages) => messages.where((m) => m['is_read'] == false).toList());
  }

  Stream<List<Map<String, dynamic>>> getMessagesStream(String conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
  }

  Future<Map<String, dynamic>> sendMessage(String conversationId, String receiverId, String text, String uuid) async {
    final userId = currentUserId;
    if (userId == null) throw Exception("Not logged in");

    // 1. Insert message
    final insertedMessage = await _supabase.from('messages').insert({
      'id': uuid,
      'conversation_id': conversationId,
      'sender_id': userId,
      'receiver_id': receiverId,
      'message': text,
      'status': 'sent',
      'is_read': false,
    }).select().single();

    // 2. Update conversation last message
    await _supabase.from('conversations').update({
      'last_message': text,
      'last_message_time': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', conversationId);

    return insertedMessage;
  }

  Future<void> markMessagesAsRead(String conversationId) async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      await _supabase
          .from('messages')
          .update({
            'is_read': true,
            'status': 'read'
          })
          .eq('conversation_id', conversationId)
          .eq('receiver_id', userId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> markMessageAsDelivered(String messageId) async {
    try {
      await _supabase.from('messages').update({'status': 'delivered'}).eq('id', messageId);
    } catch (e) {
      debugPrint('Error marking as delivered: $e');
    }
  }

  Future<Map<String, dynamic>?> getConversationData(String conversationId) async {
    try {
      return await _supabase
          .from('conversations')
          .select()
          .eq('id', conversationId)
          .maybeSingle();
    } catch (e) {
      debugPrint('Error fetching conversation data: $e');
      return null;
    }
  }
}
