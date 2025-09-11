import 'package:chat_app/data/repo/auth_repo.dart';
import 'package:chat_app/data/repo/profile_repo.dart';
import 'package:chat_app/logic/cubit/profile/profile_state.dart';
import 'package:chat_app/data/model/user_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepo profileRepo;

  /// Central user data for instant updates
  UserModel? currentUser;

  ProfileCubit(this.profileRepo) : super(ProfileInitial());

  /// Fetch user profile from Supabase
  Future<void> fetchUserProfile(String userId) async {
    emit(ProfileLoading());
    try {
      final profileData = await profileRepo.getUserProfile(userId);
      if (profileData != null) {
        currentUser = profileData; // update central user
        emit(ProfileLoaded(profileData));
      } else {
        emit(ProfileError("User not found", code: "user_not_found"));
      }
    } catch (e) {
      emit(ProfileError(e.toString(), code: "fetch_error"));
    }
  }

  /// Update profile fields
  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? username,
    String? phoneNumber,
  }) async {
    emit(ProfileLoading());
    try {
      // Basic validation
      if (fullName != null && fullName.trim().isEmpty) {
        emit(ProfileError("Full name cannot be empty", code: "invalid_input"));
        return;
      }
      if (username != null && username.trim().isEmpty) {
        emit(ProfileError("Username cannot be empty", code: "invalid_input"));
        return;
      }
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
        // Basic phone number validation (e.g., length check)
        if (phoneNumber.trim().length < 7) {
          emit(ProfileError("Invalid phone number", code: "invalid_input"));
          return;
        }
      }

      await profileRepo.updateUserProfile(
        userId: userId,
        fullName: fullName,
        username: username,
        phoneNumber: phoneNumber,
      );
      await fetchUserProfile(userId);
      // Emit ProfileLoaded with isProfileUpdate flag
      if (currentUser != null) {
        emit(ProfileLoaded(currentUser!, isProfileUpdate: true));
      }
    } catch (e) {
      emit(ProfileError(e.toString(), code: "update_error"));
    }
  }

  /// Delete account
  Future<void> deleteAccount(String userId) async {
    emit(ProfileLoading());
    try {
      await profileRepo.deleteAccount(userId);
      await AuthRepository().signOut();
      currentUser = null; // clear central user
      emit(ProfileDeleted());
    } catch (e) {
      emit(ProfileError(e.toString(), code: "delete_error"));
    }
  }

  /// Pick and upload avatar, update currentUser instantly
  Future<void> updateAvatar(ImageSource source, String userId) async {
    try {
      emit(ProfileUploadingAvatar());

      final fileBytes = await profileRepo.pickImage(source);
      if (fileBytes == null) {
        emit(
          ProfileError(
            "No image selected go back and try again",
            code: "no_image_selected",
          ),
        );
        return;
      }

      final imageUrl = await profileRepo.uploadAvatar(fileBytes);

      // Update Supabase user table
      await profileRepo.updateUserProfile(
        userId: userId,
        profilePhoto: imageUrl,
      );

      // Update currentUser directly for faster UI update
      if (currentUser != null) {
        currentUser = currentUser!.copyWith(avatarUrl: imageUrl);
        emit(ProfileAvatarUpdated(imageUrl));
      }

      // Fetch updated profile to ensure consistency
      await fetchUserProfile(userId);
    } catch (e) {
      emit(
        ProfileError(
          "Failed to update avatar: $e",
          code: "avatar_update_error",
        ),
      );
    }
  }
}
