import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chat_app/data/model/user_model.dart';

class ProfileRepo {
  final supabase = Supabase.instance.client;

  ///  جلب بروفايل المستخدم
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final data = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        return UserModel.fromSupabase(data);
      }
      return null;
    } on PostgrestException catch (e) {
      throw Exception("Database error [${e.code}]: ${e.message}");
    } catch (e) {
      throw Exception("Failed to load profile: $e");
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? username,
    String? phoneNumber,
    String? profilePhoto,
  }) async {
    final updates = <String, dynamic>{};

    if (fullName != null) updates['full_name'] = fullName;
    if (username != null) updates['username'] = username;
    if (phoneNumber != null) updates['phone_number'] = phoneNumber;
    if (profilePhoto != null) updates['avatar_url'] = profilePhoto;

    await supabase.from('users').update(updates).eq('id', userId);
  }

  ///  حذف الحساب من جدول users + Supabase Auth + SignOut
  Future<bool> deleteAccount(String userId) async {
    try {
      await supabase.from('users').delete().eq('id', userId);

      await supabase.auth.signOut();

      return true;
    } on PostgrestException catch (e) {
      throw Exception("Database error [${e.code}]: ${e.message}");
    } on AuthException catch (e) {
      throw Exception("Auth error: ${e.message}");
    } catch (e) {
      throw Exception("Unexpected error deleting account: $e");
    }
  }

  /// Pick image from phone (gallery or camera)
  Future<Uint8List?> pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final file = await picker.pickImage(source: source);
    if (file == null) return null;
    return await file.readAsBytes();
  }

  /// Upload image to Supabase and return public URL
  Future<String> uploadAvatar(Uint8List fileBytes) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final fileName = '${user.id}.png';

    await supabase.storage
        .from('avatars')
        .uploadBinary(
          fileName,
          fileBytes,
          fileOptions: const FileOptions(upsert: true),
        );

    final publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

    // Update user row in table users
    await supabase
        .from('users')
        .update({'avatar_url': publicUrl})
        .eq('id', user.id);

    return publicUrl;
  }
}
