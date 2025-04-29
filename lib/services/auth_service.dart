import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _currentUser;
  bool _isArtist = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isArtist => _isArtist;

  AuthService() {
    _initialize();
  }

  void _initialize() async {
    _currentUser = _supabase.auth.currentUser;
    if (_currentUser != null) {
      await _checkArtistStatus();
    }
    _supabase.auth.onAuthStateChange.listen((data) {
      _currentUser = data.session?.user;
      if (_currentUser != null) {
        _checkArtistStatus();
      } else {
        _isArtist = false;
      }
      notifyListeners();
    });
  }

  Future<void> _checkArtistStatus() async {
    if (_currentUser == null) return;

    try {
      final response =
          await _supabase
              .from('artist_profiles')
              .select()
              .eq('user_id', _currentUser!.id)
              .single()
              .execute();

      _isArtist = response.data != null;
      notifyListeners();
    } catch (e) {
      _isArtist = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _supabase.from('profiles').insert({
          'id': response.user!.id,
          'email': email,
          'full_name': name,
          'created_at': DateTime.now().toIso8601String(),
        });
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> signOut() async {
    try {
      await _supabase.auth.signOut();
      _currentUser = null;
      _isArtist = false;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> upgradeToArtist({
    required String bio,
    String? website,
    String? socialMedia,
  }) async {
    if (_currentUser == null) return false;

    try {
      await _supabase.from('artist_profiles').insert({
        'user_id': _currentUser!.id,
        'bio': bio,
        'website': website,
        'social_media': socialMedia,
        'created_at': DateTime.now().toIso8601String(),
        'subscription_status': 'active',
      });

      _isArtist = true;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
