import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:chat_app/presentation/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

class DoneScreen extends StatefulWidget {
  const DoneScreen({super.key});

  @override
  State<DoneScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<DoneScreen> {
  @override
  void initState() {
    super.initState();

    // Navigate after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Lottie.asset(
                'assets/lottie/Done Blue.json',
                width: 200,
                height: 200,
              ),
            ),
            AnimatedTextKit(
              repeatForever: false,
              animatedTexts: [
                TypewriterAnimatedText(
                  curve: Curves.easeIn,
                  cursor: '',
                  'Your Password Has Been Updated , you can now log in',
                  textAlign: TextAlign.center,
                  textStyle: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  speed: const Duration(milliseconds: 50),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
