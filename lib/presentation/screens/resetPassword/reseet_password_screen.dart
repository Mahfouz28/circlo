import 'package:chat_app/core/common/custom_text_botton.dart';
import 'package:chat_app/core/common/custom_text_field.dart';
import 'package:chat_app/core/common/snackBar.dart';
import 'package:chat_app/presentation/screens/resetPassword/otp_Screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReseetPasswordScreen extends StatelessWidget {
  ReseetPasswordScreen({super.key});

  final TextEditingController emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
                Text(
                  'Forgot Password',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                5.verticalSpace,
                Text(
                  'Please enter your email to reset the password',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                  ),
                ),
                20.verticalSpace,
                Text(
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
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      AppSnackBar.show(
                        context,
                        message: 'Password reset link sent!',
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OTPScreen()),
                      );
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
