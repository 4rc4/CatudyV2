import 'dart:async';

import 'package:flutter/foundation.dart';
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

class CatudyAuthLocalizedException implements Exception {
  const CatudyAuthLocalizedException(this.copyKey, [this.debugMessage]);

  final String copyKey;
  final String? debugMessage;

  @override
  String toString() => debugMessage ?? copyKey;
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

  Future<CatudyAuthSession> updateDisplayName(String displayName) async {
    final response = await _client.auth.updateUser(
      UserAttributes(data: {'display_name': _cleanName(displayName)}),
    );
    final user = response.user;
    if (user == null) {
      throw StateError('Display name update did not return a user.');
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

  Future<void> deleteCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return;
    }
    final Object? deleted;
    try {
      deleted = await _client.rpc('catudy_delete_current_user');
    } on PostgrestException catch (error) {
      final copyKey = _accountDeletionErrorCopyKey(error);
      if (copyKey != null) {
        throw CatudyAuthLocalizedException(copyKey, error.toString());
      }
      rethrow;
    }
    if (deleted != true) {
      throw StateError('Account deletion was not completed.');
    }
    try {
      await _client.auth.signOut();
    } catch (_) {
      // The Supabase session may already be invalid after deleting auth.users.
    }
  }

  String? _accountDeletionErrorCopyKey(PostgrestException error) {
    final code = error.code?.toLowerCase();
    final text = [
      error.message,
      error.code,
      error.details,
      error.hint,
    ].whereType<Object>().join(' ').toLowerCase();

    if (code == 'pgrst202' || text.contains('could not find the function')) {
      return 'auth.deleteSetupError';
    }
    if (code == '42501' ||
        text.contains('permission denied') ||
        text.contains('insufficient privilege')) {
      return 'auth.deleteSetupError';
    }
    if (text.contains('authentication required') ||
        text.contains('jwt') ||
        text.contains('token') ||
        text.contains('session')) {
      return 'auth.sessionExpired';
    }
    return null;
  }

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    final opened = await _client.auth.signInWithOAuth(
      provider,
      redirectTo: kIsWeb ? null : 'io.supabase.catudy://login-callback/',
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
