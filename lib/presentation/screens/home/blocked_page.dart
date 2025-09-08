import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_app/data/repo/chat_repo.dart';
import 'package:chat_app/logic/cubit/chat/chat_cubit.dart';
import 'package:chat_app/presentation/screens/chat/chat_messge_screen.dart';
import 'package:chat_app/services_locator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

class BlockedPage extends StatelessWidget {
  final String currentUserId;
  final String blockedUserId;
  final String blockedUserName;

  const BlockedPage({
    super.key,
    required this.currentUserId,
    required this.blockedUserId,
    required this.blockedUserName,
  });

  Future<void> _unblockAndNavigate(BuildContext context) async {
    final chatRepo = sl<ChatRepo>();

    try {
      // unblock logic (adjust according to your schema)
      await chatRepo.unblockUser(currentUserId, blockedUserId);

      // then navigate to chat screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) =>
                ChatCubit(chatRepo)..loadChat(currentUserId, blockedUserId),
            child: ChatMessageScreen(
              receiverId: blockedUserId,
              receiverName: blockedUserName,
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to unblock: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Blocked User")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              160.verticalSpace,
              Center(
                child: Lottie.asset(
                  'assets/lottie/Cancel Bubbles.json',
                  repeat: false,
                ),
              ),
              Spacer(),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: blockedUserName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text:
                          " is blocked, you cant send or receive messages from this user.",
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => _unblockAndNavigate(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                ),
                child: const Text(
                  "Unblock",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              40.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}
