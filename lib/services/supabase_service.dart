import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient _supabase;

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal() {
    _supabase = Supabase.instance.client;
  }

  SupabaseClient get client => _supabase;

  // Authentication methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return _supabase.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get current user session
  Session? get currentUser => _supabase.auth.currentSession;

  // Get current user
  User? get user => _supabase.auth.currentUser;
}