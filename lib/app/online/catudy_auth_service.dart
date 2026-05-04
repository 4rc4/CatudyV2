import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class CatudyAuthSession {
  const CatudyAuthSession({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.provider,
    required this.anonymous,
  });

  factory CatudyAuthSession.fromUser(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final provider = user.appMetadata['provider'] as String? ?? 'email';
    final name =
        metadata['display_name'] as String? ??
        metadata['full_name'] as String? ??
        metadata['name'] as String? ??
        user.email ??
        'Guest Cat';
    return CatudyAuthSession(
      userId: user.id,
      email: user.email,
      displayName: name,
      provider: provider,
      anonymous: user.isAnonymous,
    );
  }

  final String userId;
  final String? email;
  final String displayName;
  final String provider;
  final bool anonymous;
}

class CatudyAuthService {
  CatudyAuthService(this._client);

  final SupabaseClient _client;

  CatudyAuthSession? get currentSession {
    final user = _client.auth.currentUser;
    return user == null ? null : CatudyAuthSession.fromUser(user);
  }

  Stream<CatudyAuthSession?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((state) {
      final user = state.session?.user;
      return user == null ? null : CatudyAuthSession.fromUser(user);
    });
  }

  Future<CatudyAuthSession> signInAsGuest(String displayName) async {
    final response = await _client.auth.signInAnonymously(
      data: {'display_name': _cleanName(displayName)},
    );
    final user = response.user;
    if (user == null) {
      throw StateError('Guest login did not return a user.');
    }
    return CatudyAuthSession.fromUser(user);
  }

  Future<CatudyAuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw StateError('Email login did not return a user.');
    }
    return CatudyAuthSession.fromUser(user);
  }

  Future<CatudyAuthSession> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': _cleanName(displayName)},
    );
    final user = response.user;
    if (user == null) {
      throw StateError('Email sign up did not return a user.');
    }
    return CatudyAuthSession.fromUser(user);
  }

  Future<void> signInWithGoogle() {
    return _signInWithOAuth(OAuthProvider.google);
  }

  Future<void> signInWithApple() {
    return _signInWithOAuth(OAuthProvider.apple);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    final opened = await _client.auth.signInWithOAuth(
      provider,
      redirectTo: 'io.supabase.catudy://login-callback/',
    );
    if (!opened) {
      throw StateError('OAuth browser could not be opened.');
    }
  }

  String _cleanName(String value) {
    final clean = value.trim();
    return clean.isEmpty ? 'Guest Cat' : clean;
  }
}
