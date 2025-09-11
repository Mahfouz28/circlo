import 'package:chat_app/core/common/snackBar.dart';
import 'package:chat_app/logic/cubit/profile/profile_state.dart';
import 'package:chat_app/presentation/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_app/logic/cubit/profile/profile_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;
  const EditProfileScreen({super.key, required this.userId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final userNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileCubit>().fetchUserProfile(widget.userId);
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    userNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded) {
          // Update text controllers with the latest user data
          nameController.text = state.user.fullName;
          phoneController.text = state.user.phoneNumber;
          userNameController.text = state.user.username;
          // Show success message after profile update
          AppSnackBar.show(context, message: "Profile updated successfully!");
        } else if (state is ProfileError && state.message != "User not found") {
          AppSnackBar.show(context, message: state.message, isError: true);
        } else if (state is ProfileDeleted) {
          // Navigate to LoginScreen after account deletion
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
          AppSnackBar.show(
            context,
            message: "Account deleted successfully! Please sign up again.",
            isError: false,
          );
        }
      },
      builder: (context, state) {
        if (state is ProfileLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is ProfileError) {
          return Scaffold(body: Center(child: Text("Error: ${state.message}")));
        } else if (state is ProfileLoaded) {
          final user = state.user;
          return Scaffold(
            appBar: AppBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 0),
                  const Text("Edit Profile"),
                  IconButton(
                    onPressed: () {
                      context.read<ProfileCubit>().updateUserProfile(
                        userId: widget.userId,
                        fullName: nameController.text.trim(),
                        phoneNumber: phoneController.text.trim(),
                        username: userNameController.text.trim(),
                      );
                    },
                    icon: const Icon(Icons.done, color: Colors.lightBlue),
                  ),
                ],
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      20.verticalSpace,

                      // Profile picture
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 70.r,
                              backgroundColor: const Color(0xffD9D9D9),
                              backgroundImage:
                                  (user.avatarUrl != null &&
                                      user.avatarUrl!.isNotEmpty)
                                  ? NetworkImage(
                                      "${user.avatarUrl}?t=${DateTime.now().millisecondsSinceEpoch}",
                                    )
                                  : null,
                              child: state is ProfileUploadingAvatar
                                  ? const CircularProgressIndicator(
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
                            Positioned(
                              right: 4,
                              bottom: 10,
                              child: GestureDetector(
                                onTap: () async {
                                  final source =
                                      await showModalBottomSheet<ImageSource>(
                                        context: context,
                                        builder: (_) {
                                          return SafeArea(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                ListTile(
                                                  leading: const Icon(
                                                    Icons.photo,
                                                    color: Colors.lightBlue,
                                                  ),
                                                  title: const Text(
                                                    "From Gallery",
                                                  ),
                                                  onTap: () => Navigator.pop(
                                                    context,
                                                    ImageSource.gallery,
                                                  ),
                                                ),
                                                ListTile(
                                                  leading: const Icon(
                                                    Icons.camera_alt,
                                                    color: Colors.lightBlue,
                                                  ),
                                                  title: const Text(
                                                    "Take a Photo",
                                                  ),
                                                  onTap: () => Navigator.pop(
                                                    context,
                                                    ImageSource.camera,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );

                                  if (source != null && context.mounted) {
                                    context.read<ProfileCubit>().updateAvatar(
                                      source,
                                      widget.userId,
                                    );
                                  }
                                },
                                child: const CircleAvatar(
                                  backgroundColor: Colors.lightBlue,
                                  radius: 20,
                                  child: Icon(
                                    Icons.add_a_photo,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      20.verticalSpace,
                      Center(
                        child: Column(
                          children: [
                            Text(
                              user.fullName,
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 18.sp,
                              ),
                            ),
                            Text(
                              user.username,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      30.verticalSpace,

                      // Email (non-editable)
                      Text(
                        "Your Email",
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      8.verticalSpace,
                      outlinedEmptyBox(
                        width: double.infinity,
                        height: 50.h,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.email, color: Colors.lightBlue),
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

                      20.verticalSpace,

                      // Phone Number (editable)
                      Text(
                        "Phone Number",
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      8.verticalSpace,
                      TextField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.phone,
                            color: Colors.lightBlue,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      20.verticalSpace,

                      // Full Name (editable)
                      Text(
                        "Full Name",
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      8.verticalSpace,
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.person,
                            color: Colors.lightBlue,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      20.verticalSpace,

                      // Username (editable)
                      Text(
                        "Username",
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      8.verticalSpace,
                      TextField(
                        controller: userNameController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.person,
                            color: Colors.lightBlue,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      30.verticalSpace,

                      // Delete Account Button
                      GestureDetector(
                        onTap: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text("Delete Account"),
                                content: const Text(
                                  "Are you sure you want to delete your account? This action cannot be undone.",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text("Cancel"),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.red,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text("Delete"),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmed == true && context.mounted) {
                            context.read<ProfileCubit>().deleteAccount(
                              widget.userId,
                            );
                          }
                        },
                        child: outlinedEmptyBox(
                          borderColor: Colors.red,
                          width: double.infinity,
                          height: 50.h,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                10.horizontalSpace,
                                Text(
                                  'Delete account',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
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
