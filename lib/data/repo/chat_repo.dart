import 'dart:io';
import 'package:chat_app/data/model/chat_messege_model.dart';
import 'package:chat_app/data/model/chat_mode_model.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepo {
  final supabase = Supabase.instance.client;

  /// Get or create a chat room between two users.
  Future<ChatRoomModel> getOrCreateRoom(
    String currentUserId,
    String otherUserId,
  ) async {
    try {
      // Create deterministic room id
      final userIds = [currentUserId, otherUserId]..sort();
      final roomId = userIds.join('_');

      // Try to fetch existing room
      final existingRoom = await supabase
          .from('chat_rooms')
          .select()
          .eq('id', roomId)
          .maybeSingle();

      // Fetch participants' public info
      final usersData = await supabase
          .from('users')
          .select('id, username')
          .inFilter('id', userIds);

      // Build participants_name map
      final participantsName = {
        for (var user in usersData)
          user['id'] as String: user['username'] as String,
      };

      if (existingRoom != null) {
        // Update participants_name if changed
        final existingNames = Map<String, String>.from(
          existingRoom['participants_name'] ?? {},
        );

        if (!mapEquals(existingNames, participantsName)) {
          await supabase
              .from('chat_rooms')
              .update({'participants_name': participantsName})
              .eq('id', roomId);
          existingRoom['participants_name'] = participantsName;
        }

        return ChatRoomModel.fromSupabase(existingRoom);
      }

      // Create new room
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final newRoom = {
        'id': roomId,
        'participants': userIds,
        'participants_name': participantsName,
        'last_read': {currentUserId: nowIso, otherUserId: nowIso},
        'created_at': nowIso,
        'last_message': null,
        'last_message_time': null,
        'last_message_status': 'read',
      };

      final insertedRoom = await supabase
          .from('chat_rooms')
          .insert(newRoom)
          .select()
          .maybeSingle();

      return ChatRoomModel.fromSupabase(insertedRoom ?? newRoom);
    } on PostgrestException catch (e) {
      throw Exception("Database error: ${e.message}");
    } catch (e) {
      throw Exception("Failed to get or create room: $e");
    }
  }

  /// Send a message inside a chat room and return the message ID.
  Future<String> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String content,
    String type = 'text',
  }) async {
    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();

      // Insert message
      final response = await supabase
          .from('messages')
          .insert({
            'chat_room_id': chatRoomId,
            'sender_id': senderId,
            'receiver_id': receiverId,
            'content': content,
            'type': type,
            'status': MessageStatus.sent.name,
            'is_deleted': false,
            'created_at': nowIso,
            'seen_by': [senderId],
          })
          .select('id')
          .single();

      // Update chat room last message info
      await supabase
          .from('chat_rooms')
          .update({
            'last_message': type == 'voice' ? '[voice]' : content,
            'last_message_time': nowIso,
            'last_message_status': MessageStatus.sent.name,
          })
          .eq('id', chatRoomId);

      return response['id'] as String;
    } on PostgrestException catch (e) {
      throw Exception("Failed to send message: ${e.message}");
    } catch (e) {
      throw Exception("Failed to send message: $e");
    }
  }

  /// Listen to messages in real-time for a given chat room.
  Stream<List<ChatMessageModel>> listenMessages(String chatRoomId) {
    try {
      return supabase
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('chat_room_id', chatRoomId)
          .order('created_at', ascending: true)
          .map(
            (rows) =>
                rows.map((row) => ChatMessageModel.fromSupabase(row)).toList(),
          );
    } catch (e) {
      throw Exception("Failed to listen to messages: $e");
    }
  }

  /// Fetch all messages for a given chat room.
  Future<List<ChatMessageModel>> getMessages(String chatRoomId) async {
    try {
      final response = await supabase
          .from('messages')
          .select()
          .eq('chat_room_id', chatRoomId)
          .order('created_at', ascending: true);

      return (response as List<dynamic>)
          .map<ChatMessageModel>((m) => ChatMessageModel.fromSupabase(m))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception("Failed to fetch messages: ${e.message}");
    } catch (e) {
      throw Exception("Failed to fetch messages: $e");
    }
  }

  /// Mark a specific message as read by a given user.
  Future<void> markAsRead(
    String messageId,
    String userId,
    String chatRoomId,
  ) async {
    try {
      final message = await supabase
          .from('messages')
          .select('id, status, seen_by')
          .eq('id', messageId)
          .maybeSingle();

      if (message == null) return;

      final seenBy = (message['seen_by'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();

      if (!seenBy.contains(userId)) {
        final newSeenBy = [...seenBy, userId];
        await supabase
            .from('messages')
            .update({'status': MessageStatus.read.name, 'seen_by': newSeenBy})
            .eq('id', messageId);
      }

      await updateChatRoomLastMessageStatus(
        chatRoomId,
        MessageStatus.read.name,
      );
    } on PostgrestException catch (e) {
      throw Exception("Failed to mark message as read: ${e.message}");
    } catch (e) {
      throw Exception("Failed to mark message as read: $e");
    }
  }

  Future<void> markAllAsRead(String chatRoomId, String userId) async {
    try {
      await supabase
          .from('messages')
          .update({'status': MessageStatus.read.name})
          .eq('chat_room_id', chatRoomId)
          .neq('sender_id', userId)
          .neq('status', MessageStatus.read.name);

      // لو عايز تضيف الـ userId في seen_by وتمنع التكرار، الأحسن تعمل RPC
      // لكن مؤقتاً ممكن تعمل كده:
      await supabase.rpc(
        'add_seen_by_bulk',
        params: {'room_id': chatRoomId, 'uid': userId},
      );

      await updateChatRoomLastMessageStatus(
        chatRoomId,
        MessageStatus.read.name,
      );
    } on PostgrestException catch (e) {
      throw Exception("Failed to mark messages as read: ${e.message}");
    } catch (e) {
      throw Exception("Failed to mark messages as read: $e");
    }
  }

  /// Update the last message status in a chat room.
  Future<void> updateChatRoomLastMessageStatus(
    String chatRoomId,
    String status,
  ) async {
    try {
      await supabase
          .from('chat_rooms')
          .update({'last_message_status': status})
          .eq('id', chatRoomId);
    } on PostgrestException catch (e) {
      throw Exception("Failed to update chat room status: ${e.message}");
    } catch (e) {
      throw Exception("Failed to update chat room status: $e");
    }
  }

  /// Upload a voice file to Supabase Storage and return a URL.
  Future<String> uploadVoiceFile({
    required File file,
    required String pathInBucket,
    int signedUrlDurationSeconds = 3600,
  }) async {
    try {
      final fullPath = pathInBucket.startsWith('voices/')
          ? pathInBucket
          : 'voices/$pathInBucket';

      await supabase.storage.from('chat-voices').upload(fullPath, file);

      if (signedUrlDurationSeconds > 0) {
        final signedUrl = await supabase.storage
            .from('chat-voices')
            .createSignedUrl(fullPath, signedUrlDurationSeconds);
        if (signedUrl.isNotEmpty) return signedUrl;
      }

      final publicUrl = supabase.storage
          .from('chat-voices')
          .getPublicUrl(fullPath);
      return publicUrl;
    } on PostgrestException catch (e) {
      throw Exception("Failed to upload voice file: ${e.message}");
    } catch (e) {
      throw Exception("Failed to upload voice file: $e");
    }
  }

  /// Block a user.
  Future<void> blockUser(String userId, String blockedId) async {
    try {
      await supabase.rpc(
        'block_user',
        params: {'user_id': userId, 'blocked_id': blockedId},
      );
    } on PostgrestException catch (e) {
      throw Exception("Failed to block user: ${e.message}");
    } catch (e) {
      throw Exception("Failed to block user: $e");
    }
  }

  /// Unblock a user.
  Future<void> unblockUser(String userId, String blockedId) async {
    try {
      await supabase.rpc(
        'unblock_user',
        params: {'user_id': userId, 'blocked_id': blockedId},
      );
    } on PostgrestException catch (e) {
      throw Exception("Failed to unblock user: ${e.message}");
    } catch (e) {
      throw Exception("Failed to unblock user: $e");
    }
  }

  /// Get the list of blocked users for a given user.
  Future<List<String>> getBlockedUsers(String userId) async {
    try {
      final res = await supabase
          .from('users')
          .select('block_users')
          .eq('id', userId)
          .single();

      return (res['block_users'] as List<dynamic>?)?.cast<String>() ?? [];
    } on PostgrestException catch (e) {
      throw Exception("Failed to fetch blocked users: ${e.message}");
    } catch (e) {
      throw Exception("Failed to fetch blocked users: $e");
    }
  }

  /// Check if a user is blocked by another user.
  Future<bool> isUserBlocked(String userId, String otherUserId) async {
    try {
      final res = await supabase
          .from('users')
          .select('block_users')
          .eq('id', userId)
          .maybeSingle();

      if (res == null) return false;

      final blockedUsers =
          (res['block_users'] as List<dynamic>?)?.cast<String>() ?? [];
      return blockedUsers.contains(otherUserId);
    } on PostgrestException catch (e) {
      throw Exception("Failed to check if user is blocked: ${e.message}");
    } catch (e) {
      throw Exception("Failed to check if user is blocked: $e");
    }
  }

  /// Update typing status for a user in a chat room.
  Future<void> updateTypingStatus(
    String chatRoomId,
    String userId,
    bool isTyping,
  ) async {
    try {
      await supabase.from('typing').upsert({
        'chat_room_id': chatRoomId,
        'user_id': userId,
        'is_typing': isTyping,
      });
    } on PostgrestException catch (e) {
      throw Exception("Failed to update typing status: ${e.message}");
    } catch (e) {
      throw Exception("Failed to update typing status: $e");
    }
  }

  /// Listen to typing status updates for a chat room.
  Stream<Map<String, dynamic>> listenTypingStatus(String chatRoomId) {
    try {
      return supabase
          .from('typing')
          .stream(primaryKey: ['chat_room_id', 'user_id'])
          .eq('chat_room_id', chatRoomId)
          .map(
            (data) => data.isNotEmpty
                ? {
                    'chat_room_id': data[0]['chat_room_id'],
                    'user_id': data[0]['user_id'],
                    'is_typing': data[0]['is_typing'],
                  }
                : {},
          );
    } catch (e) {
      throw Exception("Failed to listen to typing status: $e");
    }
  }

  /// Fetch chat rooms for a user.
  Future<List<Map<String, dynamic>>> getChatRooms(String userId) async {
    try {
      final response = await supabase.from('chat_rooms').select().contains(
        'participants',
        [userId],
      );

      return (response as List<dynamic>).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw Exception("Failed to fetch chat rooms: ${e.message}");
    } catch (e) {
      throw Exception("Failed to fetch chat rooms: $e");
    }
  }

  //   /// Listen to chat room updates for a user.
  //   Stream<List<Map<String, dynamic>>> listenChatRooms(String userId) {
  //     try {
  //       return supabase
  //  .from('chat_rooms')
  //  .stream(primaryKey: ['id'])
  //           .contains('participants', [userId])
  //           .map((rooms) => rooms.cast<Map<String, dynamic>>());
  //     } catch (e) {
  //       throw Exception("Failed to listen to chat rooms: $e");
  //     }
  //   }
}
