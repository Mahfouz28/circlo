import 'package:equatable/equatable.dart';
import 'package:chat_app/data/model/chat_messege_model.dart';
import 'package:chat_app/data/model/chat_mode_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any action
class ChatInitial extends ChatState {}

/// Loading state while fetching data (messages/room)
class ChatLoading extends ChatState {}

/// State when chat room and messages are loaded
class ChatLoaded extends ChatState {
  final ChatRoomModel chatRoom;
  final List<ChatMessageModel> messages;
  final bool isSenderBlocked; // Current user blocked the other user
  final bool isReceiverBlocked; // Other user blocked the current user
  final bool isTyping;
  final String? typingUserId;

  ChatLoaded({
    required this.chatRoom,
    required this.messages,
    this.isSenderBlocked = false,
    this.isReceiverBlocked = false,
    this.isTyping = false,
    this.typingUserId,
  });

  ChatLoaded copyWith({
    ChatRoomModel? chatRoom,
    List<ChatMessageModel>? messages,
    bool? isSenderBlocked,
    bool? isReceiverBlocked,
    bool? isTyping,
    String? typingUserId,
  }) {
    return ChatLoaded(
      chatRoom: chatRoom ?? this.chatRoom,
      messages: messages ?? this.messages,
      isSenderBlocked: isSenderBlocked ?? this.isSenderBlocked,
      isReceiverBlocked: isReceiverBlocked ?? this.isReceiverBlocked,
      isTyping: isTyping ?? this.isTyping,
      typingUserId: typingUserId ?? this.typingUserId,
    );
  }

  @override
  List<Object?> get props => [
    chatRoom,
    messages,
    isSenderBlocked,
    isReceiverBlocked,
    isTyping,
    typingUserId,
  ];
}

/// Error state for any failures
class ChatError extends ChatState {
  final String message;

  ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State when the user is blocked
class ChatBlocked extends ChatState {
  final String blockedUserId;

  ChatBlocked(this.blockedUserId);

  @override
  List<Object?> get props => [blockedUserId];
}

/// State when the user is unblocked
class ChatUnblocked extends ChatState {
  final String otherUserId;

  ChatUnblocked(this.otherUserId);

  @override
  List<Object?> get props => [otherUserId];
}
