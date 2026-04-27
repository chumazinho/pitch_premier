import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthRepository {
  Future<UserModel?> signIn(String email, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final profileData = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', response.user!.id)
            .single();

        return UserModel.fromJson({
          ...profileData,
          'email': response.user!.email,
        });
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> signUp(String email, String password, String role) async {
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'role': role})
            .eq('id', response.user!.id);

        return UserModel(
          id: response.user!.id,
          email: response.user!.email ?? email,
          role: role,
          createdAt: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  Future<UserModel?> getCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    try {
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return UserModel.fromJson({...profileData, 'email': user.email});
    } catch (e) {
      return null;
    }
  }
}
