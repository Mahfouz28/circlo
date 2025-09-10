import 'package:supabase_flutter/supabase_flutter.dart';

final subabase = Supabase.instance.client;

class ResetPasswordRepo {
  Future<void> resetPassword(String email) async {
    try {
      subabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.chatapp://reset-callback',
      );
    } catch (e) {
      print("Error sending reset email: $e");

      throw Exception("Failed to reset password");
    }
  }

  Future<void> updatePassword(String newPassword) async {
    final response = await subabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );

    if (response.user == null) {
      throw Exception("Failed to update password");
    }
  }
}
