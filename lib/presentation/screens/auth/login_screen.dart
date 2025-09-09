import 'package:chat_app/config/image/app_svg.dart';
import 'package:chat_app/core/common/custom_text_botton.dart';
import 'package:chat_app/core/common/custom_text_field.dart';
import 'package:chat_app/core/common/snackBar.dart';
import 'package:chat_app/data/repo/auth_repo.dart';
import 'package:chat_app/logic/cubit/auth/auth_cubit.dart';
import 'package:chat_app/logic/cubit/auth/auth_state.dart';
import 'package:chat_app/presentation/screens/auth/complete_details_screen.dart';
import 'package:chat_app/presentation/screens/auth/sign_up_screen.dart';
import 'package:chat_app/presentation/screens/home/home_screen.dart';
import 'package:chat_app/logic/cubit/providers/auth_providers_cubit.dart';
import 'package:chat_app/logic/cubit/providers/auth_providers_state.dart';
import 'package:chat_app/presentation/screens/resetPassword/reseet_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_svg/svg.dart' as svgPicture;

/// Login Screen:
/// - Allows user to login using email & password
/// - Supports Google Sign-In
/// - If new user → redirects to CompleteDetailsScreen
/// - If existing user → redirects to HomePage
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers for text fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Form validation key
  final formKey = GlobalKey<FormState>();

  // Password visibility toggle
  bool isPasswordVisible = false;

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Provides AuthCubit (for email/password login)
        BlocProvider(create: (_) => AuthCubit(AuthRepository())),

        // Provides AuthProvidersCubit (for Google/Facebook login)
        BlocProvider(create: (_) => AuthProvidersCubit()),
      ],
      child: Scaffold(
        body: BlocListener<AuthProvidersCubit, AuthProvidersState>(
          listener: (context, state) {
            // ✅ Listen to AuthProviders (Google/Facebook)
            if (state is AuthProvidersSuccess) {
              if (state.user.fullName.isNotEmpty) {
                // Existing user → go to Home
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => HomePage()),
                );
              } else {
                // New user → complete details
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompleteDetailsScreen(
                      email: state.user.email,
                      fullName: state.user.fullName,
                    ),
                  ),
                );
              }
            } else if (state is AuthProvidersError) {
              // Show error from provider login
              AppSnackBar.show(context, message: state.error, isError: true);
            }
          },
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              // ✅ Listen to AuthCubit (Email/Password)
              if (state is AuthSuccess) {
                // Login successful → go to Home
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                );
                AppSnackBar.show(context, message: "Login Successful!");
              } else if (state is AuthFailure) {
                // Show error if login fails
                AppSnackBar.show(context, message: state.error, isError: true);
              }
            },
            builder: (context, state) {
              return Stack(
                children: [
                  Form(
                    key: formKey,
                    child: Padding(
                      padding: EdgeInsets.all(28.r),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 69.h),

                            // Title
                            Text(
                              'Welcome Back',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),

                            SizedBox(height: 20.h),

                            // Subtitle
                            Text(
                              'Sign in to continue',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.grey),
                            ),

                            SizedBox(height: 20.h),

                            /// Email TextField
                            CustomTextFormField(
                              hintText: 'Email',
                              prefixIcon: const Icon(Icons.email_outlined),
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: 20.h),

                            /// Password TextField
                            CustomTextFormField(
                              hintText: 'Password',
                              obscureText: !isPasswordVisible,
                              controller: passwordController,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    isPasswordVisible = !isPasswordVisible;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            12.verticalSpace,
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ReseetPasswordScreen(),
                                    ),
                                  );
                                },
                                child: Text('Forget Password?'),
                              ),
                            ),

                            SizedBox(height: 10.h),

                            /// Login Button
                            CustomButton(
                              text: state is AuthLoading
                                  ? "Signing in..."
                                  : "Sign in",
                              onPressed: state is AuthLoading
                                  ? () {}
                                  : () {
                                      if (formKey.currentState!.validate()) {
                                        context.read<AuthCubit>().signIn(
                                          email: emailController.text.trim(),
                                          password: passwordController.text
                                              .trim(),
                                        );
                                      }
                                    },
                            ),

                            SizedBox(height: 20.h),

                            /// Sign up link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Don\'t have an account?',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SignUpScreen(),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text('Sign up'),
                                ),
                              ],
                            ),

                            SizedBox(height: 20.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40.r),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey.shade200,
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                    ),
                                    child: const Text(
                                      'or',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey.shade200,
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 40.h),

                            /// Social Login (Facebook + Google)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Facebook (not implemented yet)
                                GestureDetector(
                                  onTap: () {
                                    AppSnackBar.show(
                                      context,
                                      message: 'Coming Soon!',
                                    );
                                  },
                                  child: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 30,
                                    child: SvgPicture.asset(
                                      AppSvg.facebook,
                                      height: 50,
                                      width: 50,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16.w),

                                // Google Sign-In
                                BlocBuilder<
                                  AuthProvidersCubit,
                                  AuthProvidersState
                                >(
                                  builder: (context, state) {
                                    return InkWell(
                                      onTap: state is AuthProvidersLoading
                                          ? null
                                          : () {
                                              context
                                                  .read<AuthProvidersCubit>()
                                                  .signInWithGoogle();
                                            },
                                      borderRadius: BorderRadius.circular(8),
                                      child: state is AuthProvidersLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.blue,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : svgPicture.SvgPicture.asset(
                                              AppSvg.google,
                                              height: 40,
                                              width: 50,
                                            ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  /// Overlay loading indicator during login
                  if (state is AuthLoading)
                    Container(
                      color: Colors.black.withOpacity(0.4),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.blue),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
