import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:chat_app/core/common/custom_text_botton.dart';
import 'package:chat_app/core/common/custom_text_field.dart';
import 'package:chat_app/core/common/snackBar.dart';
import 'package:chat_app/data/repo/reset_password_repo.dart';
import 'package:chat_app/presentation/screens/resetPassword/set_new_passwoed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReseetPasswordScreen extends StatefulWidget {
  const ReseetPasswordScreen({super.key});

  @override
  State<ReseetPasswordScreen> createState() => _ReseetPasswordScreenState();
}

class _ReseetPasswordScreenState extends State<ReseetPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinkListener();
  }

  void _initDeepLinkListener() {
    _appLinks = AppLinks();

    Future<void> _handleUri(Uri uri) async {
      debugPrint("🔗 Received link: $uri");

      if (uri.toString().contains('reset-callback')) {
        // tokens بتيجي في fragment بعد علامة #
        final params = Uri.splitQueryString(uri.fragment);
        final accessToken = params["access_token"];
        final refreshToken = params["refresh_token"];

        if (accessToken != null && refreshToken != null) {
          try {
            await Supabase.instance.client.auth.setSession(refreshToken);
            debugPrint("✅ Session restored with Supabase");
          } catch (e) {
            debugPrint("❌ Error setting session: $e");
          }
        }

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SetNewPasswordPage()),
          );
        }
      }
    }

    // لو اللينك جالك قبل ما الابلكيشن يفتح
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleUri(uri);
    });

    // لو اللينك جالك وانت فاتح الابلكيشن
    _appLinks.uriLinkStream.listen((uri) {
      if (uri != null) _handleUri(uri);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.r),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                20.verticalSpace,
                const Text(
                  'Forgot Password',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                5.verticalSpace,
                const Text(
                  'Please enter your email to reset the password',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                  ),
                ),
                20.verticalSpace,
                const Text(
                  'Your Email',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                10.verticalSpace,
                CustomTextFormField(
                  controller: emailController,
                  hintText: 'Enter your email',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your email';
                    }
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                40.verticalSpace,
                CustomButton(
                  text: 'Reset Password',
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        await ResetPasswordRepo().resetPassword(
                          emailController.text.trim(),
                        );

                        AppSnackBar.show(
                          context,
                          message: 'Password reset link sent!',
                        );
                      } on Exception catch (e) {
                        AppSnackBar.show(
                          context,
                          message: e.toString(),
                          isError: true,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
