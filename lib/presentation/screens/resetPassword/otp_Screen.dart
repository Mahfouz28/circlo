import 'dart:async';
import 'package:chat_app/core/common/custom_text_botton.dart';
import 'package:chat_app/presentation/screens/resetPassword/set_new_passwoed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController otpController = TextEditingController();
  final StreamController<ErrorAnimationType> errorController =
      StreamController<ErrorAnimationType>();

  bool hasError = false;

  @override
  void dispose() {
    errorController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OTP Verification')),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            20.verticalSpace,
            Text(
              'Check your email',
              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
            ),
            8.verticalSpace,
            Text(
              'We have sent a reset code to your email',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey),
            ),
            30.verticalSpace,

            /// OTP Fields
            Center(
              child: PinCodeTextField(
                appContext: context,
                controller: otpController,
                length: 5,
                keyboardType: TextInputType.number,
                errorAnimationController: errorController,
                onChanged: (value) {
                  setState(() {
                    hasError = false;
                  });
                },
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8.r),
                  fieldHeight: 50.h,
                  fieldWidth: 55.w,
                  activeFillColor: Colors.white,
                  inactiveFillColor: Colors.white,
                  selectedFillColor: Colors.white,
                  activeColor: hasError ? Colors.red : Colors.blue,
                  inactiveColor: hasError ? Colors.red : Colors.grey.shade300,
                  selectedColor: hasError ? Colors.red : Colors.blue,
                  borderWidth: 2,
                ),
                backgroundColor: Colors.transparent,
              ),
            ),
            40.verticalSpace,

            /// Verify Button
            CustomButton(
              text: 'Verify Code',
              onPressed: () {
                if (otpController.text.length == 5) {
                  setState(() => hasError = false);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SetNewPasswordPage(),
                    ),
                  );
                } else {
                  setState(() => hasError = true);
                  errorController.add(ErrorAnimationType.shake);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
