import 'package:chat_app/data/model/user_model.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserModel user;
  final bool isProfileUpdate; // Flag to indicate profile field update
  ProfileLoaded(this.user, {this.isProfileUpdate = false});
}

class ProfileUploadingAvatar extends ProfileState {}

class ProfileAvatarUpdated extends ProfileState {
  final String avatarUrl;
  ProfileAvatarUpdated(this.avatarUrl);
}

class ProfileDeleted extends ProfileState {}

class ProfileError extends ProfileState {
  final String message;
  final String? code;
  ProfileError(this.message, {this.code});
}
