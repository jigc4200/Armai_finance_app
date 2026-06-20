import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository() : _client = SupabaseService.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    return await _client
        .from('users')
        .select()
        .eq('id', userId)
        .single();
  }

  Future<void> signInWithMagicLink(String email) async {
    await _client.auth.signInWithOtp(email: email);
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> sendMagicLink(String email) async {
    await _client.auth.signInWithOtp(email: email);
  }
}
