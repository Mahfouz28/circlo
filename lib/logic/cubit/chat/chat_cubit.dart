import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_app/data/repo/chat_repo.dart';
import 'package:chat_app/data/model/chat_messege_model.dart';
import 'chat_status.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepo chatRepo;
  StreamSubscription<List<ChatMessageModel>>? _messagesSub;
  StreamSubscription<Map<String, dynamic>>? _typingSub;

  ChatCubit(this.chatRepo) : super(ChatInitial());

  /// Load chat room + messages
  Future<void> loadChat(String currentUserId, String otherUserId) async {
    emit(ChatLoading());
    try {
      final chatRoom = await chatRepo.getOrCreateRoom(
        currentUserId,
        otherUserId,
      );
      final messages = await chatRepo.getMessages(chatRoom.id);

      final isSenderBlocked = await chatRepo.isUserBlocked(
        currentUserId,
        otherUserId,
      );
      final isReceiverBlocked = await chatRepo.isUserBlocked(
        otherUserId,
        currentUserId,
      );

      emit(
        ChatLoaded(
          chatRoom: chatRoom,
          messages: messages,
          isSenderBlocked: isSenderBlocked,
          isReceiverBlocked: isReceiverBlocked,
        ),
      );

      _subscribeToMessages(chatRoom.id);
      _subscribeToTyping(chatRoom.id);
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  /// Subscribe to messages
  void _subscribeToMessages(String chatRoomId) {
    _messagesSub?.cancel();
    _messagesSub = chatRepo.listenMessages(chatRoomId).listen((messages) {
      final currentState = state;
      if (currentState is ChatLoaded) {
        emit(currentState.copyWith(messages: messages));
      }
    });
  }

  /// Subscribe to typing updates
  void _subscribeToTyping(String chatRoomId) {
    _typingSub?.cancel();
    _typingSub = chatRepo.listenTypingStatus(chatRoomId).listen((typingData) {
      final currentState = state;
      if (currentState is ChatLoaded && typingData.isNotEmpty) {
        emit(
          currentState.copyWith(
            isTyping: typingData['is_typing'] ?? false,
            typingUserId: typingData['user_id'],
          ),
        );
      }
    });
  }

  /// Send a new message
  Future<void> sendMessage({
    required String content,
    required String type,
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      final currentState = state;
      if (currentState is ChatLoaded) {
        await chatRepo.sendMessage(
          chatRoomId: currentState.chatRoom.id,
          senderId: currentUserId,
          receiverId: otherUserId,
          content: content,
          type: type,
        );
      }
    } catch (e) {
      emit(ChatError("Failed to send message: $e"));
    }
  }

  /// Update typing status
  Future<void> updateTyping(
    String chatRoomId,
    String userId,
    bool isTyping,
  ) async {
    await chatRepo.updateTypingStatus(chatRoomId, userId, isTyping);
  }

  Future<void> blockUser(String userId, String blockedId) async {
    try {
      await chatRepo.blockUser(userId, blockedId);
      final currentState = state;
      if (currentState is ChatLoaded) {
        emit(currentState.copyWith(isSenderBlocked: true));
      }
    } catch (e) {
      emit(ChatError("Failed to block user: $e"));
    }
  }

  Future<void> unblockUser(String userId, String blockedId) async {
    try {
      await chatRepo.unblockUser(userId, blockedId);
      final currentState = state;
      if (currentState is ChatLoaded) {
        emit(currentState.copyWith(isSenderBlocked: false));
      }
    } catch (e) {
      emit(ChatError("Failed to unblock user: $e"));
    }
  }

  /// Mark all messages as read
  Future<void> markAllAsRead(String chatRoomId, String userId) async {
    await chatRepo.markAllAsRead(chatRoomId, userId);
  }

  @override
  Future<void> close() {
    _messagesSub?.cancel();
    _typingSub?.cancel();
    return super.close();
  }
}
