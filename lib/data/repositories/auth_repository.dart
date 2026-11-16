import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import '../supabase/supabase_client.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client})
      : _client = client ?? SupabaseManager.client;

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<Profile?> fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select('id, full_name, role, is_active')
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return Profile.fromMap(Map<String, dynamic>.from(data));
  }
}
