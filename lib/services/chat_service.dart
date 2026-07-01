import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ============================
  // UUID Helper
  // ============================
  String generateUuid() {
    final random = Random();
    final chars = '0123456789abcdef';
    String build(int length) =>
        List.generate(length, (index) => chars[random.nextInt(16)]).join();
    return '${build(8)}-${build(4)}-4${build(3)}-a${build(3)}-${build(12)}';
  }

  // ============================
  // Presence Management
  // ============================

  /// Call this when user opens the app or any screen.
  /// Sets is_online=true and marks pending messages as delivered.
  Future<void> updatePresence(bool isOnline) async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      await _supabase.from('profiles').update({
        'is_online': isOnline,
        'last_seen': DateTime.now().toUtc().toIso8601String(),
      }).eq('user_id', userId);

      // When coming online, mark all pending 'sent' messages as 'delivered'
      if (isOnline) {
        await _supabase.rpc('mark_messages_delivered_for_user', params: {
          'p_user_id': userId,
        });
      }
    } catch (e) {
      debugPrint('Error updating presence: $e');
    }
  }

  /// Real-time presence stream using Supabase Realtime postgres_changes.
  /// Fires immediately on any change to the target user's profile row.
  Stream<Map<String, dynamic>?> getPresenceRealtimeStream(String userId) {
    late StreamController<Map<String, dynamic>?> controller;
    RealtimeChannel? channel;

    controller = StreamController<Map<String, dynamic>?>.broadcast(
      onListen: () async {
        // 1. Fetch initial data
        try {
          final data = await _supabase
              .from('profiles')
              .select()
              .eq('user_id', userId)
              .maybeSingle();
          if (!controller.isClosed) controller.add(data);
        } catch (e) {
          debugPrint('Presence initial fetch error: $e');
        }

        // 2. Subscribe to realtime changes
        channel = _supabase.channel('presence:$userId');
        channel!
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'profiles',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId,
              ),
              callback: (payload) {
                if (!controller.isClosed) {
                  controller.add(payload.newRecord);
                }
              },
            )
            .subscribe();
      },
      onCancel: () {
        channel?.unsubscribe();
        controller.close();
      },
    );

    return controller.stream;
  }

  /// Legacy stream method kept for any fallback (uses polling via .stream())
  Stream<List<Map<String, dynamic>>> getPresenceStream(String userId) {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId);
  }

  // ============================
  // Conversations Stream
  // ============================

  /// Returns a real-time stream of conversations the current user is part of.
  /// Works with both old schema (participant_1/participant_2) and new columns
  /// (user1_id/user2_id). Falls back gracefully.
  Stream<List<Map<String, dynamic>>> getConversationsStream() {
    final userId = currentUserId;
    if (userId == null) return const Stream.empty();

    return _supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        .order('last_message_time', ascending: false)
        .map((conversations) => conversations.where((c) {
              // Support both column naming conventions
              final p1 = c['participant_1'] ?? c['user1_id'];
              final p2 = c['participant_2'] ?? c['user2_id'];
              return p1 == userId || p2 == userId;
            }).toList());
  }

  // ============================
  // Unread Messages Stream
  // ============================
  Stream<List<Map<String, dynamic>>> getUnreadMessagesStream() {
    final userId = currentUserId;
    if (userId == null) return const Stream.empty();

    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', userId)
        .map((messages) =>
            messages.where((m) => m['is_read'] == false).toList());
  }

  // ============================
  // Messages Stream (Realtime)
  // ============================

  /// Real-time messages stream using Supabase Realtime postgres_changes.
  /// Instantly receives new messages and updates (read/delivered status).
  Stream<List<Map<String, dynamic>>> getMessagesStream(String conversationId) {
    late StreamController<List<Map<String, dynamic>>> controller;
    RealtimeChannel? channel;
    List<Map<String, dynamic>> currentMessages = [];

    controller = StreamController<List<Map<String, dynamic>>>.broadcast(
      onListen: () async {
        // 1. Initial load
        try {
          final data = await _supabase
              .from('messages')
              .select()
              .eq('conversation_id', conversationId)
              .order('created_at', ascending: true);
          currentMessages = List<Map<String, dynamic>>.from(data);
          if (!controller.isClosed) controller.add(List.from(currentMessages));
        } catch (e) {
          debugPrint('Messages initial load error: $e');
        }

        // 2. Subscribe to realtime changes
        channel = _supabase.channel('messages:$conversationId');
        channel!
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'messages',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'conversation_id',
                value: conversationId,
              ),
              callback: (payload) {
                if (!controller.isClosed) {
                  final newMsg =
                      Map<String, dynamic>.from(payload.newRecord);
                  // Avoid duplicates (optimistic messages already in list)
                  final idx = currentMessages
                      .indexWhere((m) => m['id'] == newMsg['id']);
                  if (idx == -1) {
                    currentMessages.add(newMsg);
                  } else {
                    currentMessages[idx] = newMsg;
                  }
                  controller.add(List.from(currentMessages));
                }
              },
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'messages',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'conversation_id',
                value: conversationId,
              ),
              callback: (payload) {
                if (!controller.isClosed) {
                  final updatedMsg =
                      Map<String, dynamic>.from(payload.newRecord);
                  final idx = currentMessages
                      .indexWhere((m) => m['id'] == updatedMsg['id']);
                  if (idx != -1) {
                    currentMessages[idx] = updatedMsg;
                    controller.add(List.from(currentMessages));
                  }
                }
              },
            )
            .subscribe();
      },
      onCancel: () {
        channel?.unsubscribe();
        controller.close();
      },
    );

    return controller.stream;
  }

  // ============================
  // Send Message
  // ============================
  Future<Map<String, dynamic>> sendMessage(
    String conversationId,
    String receiverId,
    String text,
    String uuid,
  ) async {
    final userId = currentUserId;
    if (userId == null) throw Exception("Not logged in");

    // 1. Insert message with 'sent' status
    final insertedMessage = await _supabase.from('messages').insert({
      'id': uuid,
      'conversation_id': conversationId,
      'sender_id': userId,
      'receiver_id': receiverId,
      'message': text,
      'status': 'sent',
      'is_read': false,
    }).select().single();

    // 2. Check if receiver is online — if so, mark as delivered immediately
    try {
      final receiverProfile = await _supabase
          .from('profiles')
          .select('is_online')
          .eq('user_id', receiverId)
          .maybeSingle();
      if (receiverProfile?['is_online'] == true) {
        await _supabase
            .from('messages')
            .update({'status': 'delivered'})
            .eq('id', uuid);
        insertedMessage['status'] = 'delivered';
      }
    } catch (e) {
      debugPrint('Could not check receiver online status: $e');
    }

    // 3. Update conversation last message
    await _supabase.from('conversations').update({
      'last_message': text,
      'last_message_time': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', conversationId);

    return insertedMessage;
  }

  // ============================
  // Mark as Read
  // ============================
  Future<void> markMessagesAsRead(String conversationId) async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true, 'status': 'read'})
          .eq('conversation_id', conversationId)
          .eq('receiver_id', userId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  // ============================
  // Mark as Delivered
  // ============================
  Future<void> markMessageAsDelivered(String messageId) async {
    try {
      await _supabase
          .from('messages')
          .update({'status': 'delivered'})
          .eq('id', messageId)
          .eq('status', 'sent'); // Only upgrade from 'sent', not from 'read'
    } catch (e) {
      debugPrint('Error marking as delivered: $e');
    }
  }

  // ============================
  // Conversation Data
  // ============================
  Future<Map<String, dynamic>?> getConversationData(
      String conversationId) async {
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
