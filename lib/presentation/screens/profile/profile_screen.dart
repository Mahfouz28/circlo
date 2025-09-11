import 'package:chat_app/core/common/snackbar.dart';
import 'package:chat_app/presentation/screens/profile/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_app/logic/cubit/profile/profile_cubit.dart';
import 'package:chat_app/logic/cubit/profile/profile_state.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().fetchUserProfile(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [SizedBox(width: 0), Text("Profile"), SizedBox(width: 60)],
        ),
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            AppSnackBar.show(context, message: state.message, isError: true);

            // Navigate safely
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(userId: widget.userId),
                ),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileLoaded) {
            final user = state.user;
            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              children: [
                                SizedBox(
                                  height: 139.h,
                                  width: 139.w,
                                  child: CircleAvatar(
                                    radius: 70.r,
                                    backgroundColor: const Color(0xffD9D9D9),
                                    backgroundImage:
                                        (user.avatarUrl != null &&
                                            user.avatarUrl!.isNotEmpty)
                                        ? NetworkImage(user.avatarUrl!)
                                        : null,
                                    child:
                                        (context.watch<ProfileCubit>().state
                                            is ProfileUploadingAvatar)
                                        ? CircularProgressIndicator(
                                            color: Colors.lightBlue,
                                          )
                                        : (user.avatarUrl == null ||
                                              user.avatarUrl!.isEmpty)
                                        ? Text(
                                            user.fullName[0].toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 40.sp,
                                              color: Colors.black,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  right: 2,
                                  bottom: 20,
                                  child: GestureDetector(
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditProfileScreen(
                                                userId: widget.userId,
                                              ),
                                        ),
                                      );

                                      // Refresh profile if EditProfileScreen returns true
                                      if (result == true) {
                                        context
                                            .read<ProfileCubit>()
                                            .fetchUserProfile(widget.userId);
                                      }
                                    },
                                    child: CircleAvatar(
                                      backgroundColor: Colors.lightBlue,
                                      child: Icon(
                                        Icons.edit,
                                        size: 26.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              user.fullName,
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user.username,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      14.verticalSpace,
                      Text(
                        'Your Email',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      12.verticalSpace,
                      outlinedEmptyBox(
                        width: double.infinity,
                        height: 50.h,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Icon(Icons.email, color: Colors.lightBlue),
                              8.horizontalSpace,
                              Text(
                                user.email,
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      14.verticalSpace,
                      Text(
                        'Phone Number',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      12.verticalSpace,
                      outlinedEmptyBox(
                        width: double.infinity,
                        height: 50.h,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Icon(Icons.phone, color: Colors.lightBlue),
                              8.horizontalSpace,
                              Text(
                                user.phoneNumber,
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      14.verticalSpace,
                      Text(
                        'Full Name',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      12.verticalSpace,
                      outlinedEmptyBox(
                        width: double.infinity,
                        height: 50.h,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Icon(Icons.person, color: Colors.lightBlue),
                              8.horizontalSpace,
                              Text(
                                user.fullName,
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      20.verticalSpace,
                      Text(
                        'Username',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      12.verticalSpace,
                      outlinedEmptyBox(
                        width: double.infinity,
                        height: 50.h,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Icon(Icons.person, color: Colors.lightBlue),
                              8.horizontalSpace,
                              Text(
                                user.username,
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Default fallback
          return const Center(child: Text("No data"));
        },
      ),
    );
  }
}

Widget outlinedEmptyBox({
  double width = 200,
  double height = 120,
  double borderRadius = 12,
  double borderWidth = 1,
  Color borderColor = Colors.lightBlue,
  required Widget child,
}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: borderWidth),
    ),
    child: child,
  );
}
