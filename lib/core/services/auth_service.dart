import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  // Sign in an existing user.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  // Register a new user and store their name as user metadata.
  Future<AuthResponse> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  // Request a password recovery email.
  Future<void> sendPasswordResetEmail(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }

  // Sign out the current user.
  Future<void> signOut() {
    return _client.auth.signOut();
  }
}
