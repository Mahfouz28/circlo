import 'dart:core';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:chat_app/core/common/snackBar.dart';
import 'package:chat_app/data/model/chat_messege_model.dart';
import 'package:chat_app/data/repo/chat_repo.dart';
import 'package:chat_app/logic/cubit/chat/chat_cubit.dart';
import 'package:chat_app/logic/cubit/chat/chat_status.dart';
import 'package:chat_app/presentation/screens/home/blocked_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatMessageScreen extends StatefulWidget {
  const ChatMessageScreen({super.key, this.receiverId, this.receiverName});

  final String? receiverId;
  final String? receiverName;

  @override
  State<ChatMessageScreen> createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final chatRepo = ChatRepo();

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      AppSnackBar.show(
        context,
        message: "User not authenticated",
        isError: true,
      );
      return;
    }
    context.read<ChatCubit>().loadChat(currentUserId, widget.receiverId!);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.receiverName ?? "";

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(.2),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : "?",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            12.horizontalSpace,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                BlocBuilder<ChatCubit, ChatState>(
                  builder: (context, state) {
                    if (state is ChatBlocked) {
                      return const Text(
                        "Blocked",
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      );
                    }
                    return const Text(
                      "Online",
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              final currentUserId =
                  Supabase.instance.client.auth.currentUser?.id;
              if (currentUserId == null) {
                AppSnackBar.show(
                  context,
                  message: "User not authenticated",
                  isError: true,
                );
                return;
              }

              if (value == "block") {
                await context.read<ChatCubit>().blockUser(
                  currentUserId,
                  widget.receiverId!,
                );
                AppSnackBar.show(
                  context,
                  message: "User blocked",
                  isError: true,
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlockedPage(
                      currentUserId: currentUserId,
                      blockedUserId: widget.receiverId!,
                      blockedUserName: widget.receiverName!,
                    ),
                  ),
                );
              } else if (value == "unblock") {
                await context.read<ChatCubit>().unblockUser(
                  currentUserId,
                  widget.receiverId!,
                );
                AppSnackBar.show(
                  context,
                  message: "User unblocked",
                  isError: false,
                );
                await context.read<ChatCubit>().loadChat(
                  currentUserId,
                  widget.receiverId!,
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "block", child: Text("Block User")),
              const PopupMenuItem(
                value: "unblock",
                child: Text("Unblock User"),
              ),
            ],
            icon: const Icon(Icons.more_vert_rounded),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) {
                if (state is ChatInitial || state is ChatLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ChatBlocked) {
                  return const Center(
                    child: Text(
                      "This user is blocked. You cannot send or receive messages.",
                      style: TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  );
                } else if (state is ChatLoaded) {
                  final messages = state.messages;

                  if (messages.isEmpty) {
                    return Center(
                      child: AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            'Say Hi 👋',
                            cursor: '',
                            textStyle: const TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                            speed: const Duration(milliseconds: 200),
                          ),
                        ],
                        repeatForever: true,
                      ),
                    );
                  }

                  final currentUserId =
                      Supabase.instance.client.auth.currentUser!.id;

                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final reversedMessages = messages.reversed.toList();
                      final msg = reversedMessages[index];
                      final isMe = msg.senderId == currentUserId;

                      if (!isMe && !msg.seenBy.contains(currentUserId)) {
                        context.read<ChatCubit>().markAllAsRead(
                          state.chatRoom.id,
                          currentUserId,
                        );
                      }

                      return MessageBubble(
                        chatMessage: msg,
                        isMe: isMe,
                        showTime: true,
                      );
                    },
                  );
                } else if (state is ChatError) {
                  return Center(child: Text("Error: ${state.message}"));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          SafeArea(
            child: BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) {
                if (state is ChatBlocked) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "🚫 You blocked this user. Unblock to send messages.",
                      style: TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          minLines: 1,
                          maxLines: null,
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: "Type a message...",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: () {
                          if (_messageController.text.trim().isEmpty) return;

                          final currentState = context.read<ChatCubit>().state;
                          if (currentState is ChatLoaded) {
                            context.read<ChatCubit>().sendMessage(
                              currentUserId:
                                  Supabase.instance.client.auth.currentUser!.id,
                              otherUserId: widget.receiverId!,
                              type: 'text',
                              content: _messageController.text.trim(),
                            );
                            _messageController.clear();
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.chatMessage,
    required this.isMe,
    required this.showTime,
  });

  final ChatMessageModel chatMessage;
  final bool isMe;
  final bool showTime;

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.grey[700],
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              chatMessage.content,
              style: const TextStyle(color: Colors.white),
            ),
            if (showTime)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(chatMessage.createdAt),
                    style: TextStyle(fontSize: 8.sp, color: Colors.white70),
                  ),
                  if (isMe) ...[
                    SizedBox(width: 8.w),
                    Icon(
                      chatMessage.status.name == "sent"
                          ? Icons.done_outlined
                          : chatMessage.status.name == "delivered"
                          ? Icons.done_all_outlined
                          : Icons.done_all_outlined,
                      size: 16.sp,
                      color: chatMessage.status.name == "read"
                          ? Colors.lightBlueAccent
                          : Colors.white70,
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
