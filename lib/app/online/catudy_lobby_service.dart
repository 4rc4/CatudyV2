import 'dart:async';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

class CatudyOnlineLobby {
  const CatudyOnlineLobby({
    required this.id,
    required this.code,
    required this.ownerUserId,
    required this.categoryId,
    required this.durationMinutes,
    required this.status,
    required this.startedAt,
    required this.pausedAt,
    required this.pausedSeconds,
    required this.pauseReason,
    required this.breakVoteRound,
  });

  factory CatudyOnlineLobby.fromJson(Map<String, dynamic> json) {
    return CatudyOnlineLobby(
      id: _readString(json, 'id'),
      code: _readString(json, 'code'),
      ownerUserId: _readString(json, 'owner_user_id'),
      categoryId: _readString(json, 'category_id', 'study'),
      durationMinutes: _readInt(json, 'duration_minutes', 25),
      status: _readString(json, 'status', 'waiting'),
      startedAt: _readDate(json['started_at']),
      pausedAt: _readDate(json['paused_at']),
      pausedSeconds: _readInt(json, 'paused_seconds', 0),
      pauseReason: _readNullableString(json, 'pause_reason'),
      breakVoteRound: _readInt(json, 'break_vote_round', 0),
    );
  }

  final String id;
  final String code;
  final String ownerUserId;
  final String categoryId;
  final int durationMinutes;
  final String status;
  final DateTime? startedAt;
  final DateTime? pausedAt;
  final int pausedSeconds;
  final String? pauseReason;
  final int breakVoteRound;

  bool get isRunning => status == 'running' && startedAt != null;
  bool get isPaused => pausedAt != null;
}

class CatudyOnlineLobbyMember {
  const CatudyOnlineLobbyMember({
    required this.id,
    required this.lobbyId,
    required this.userId,
    required this.displayName,
    required this.petId,
    required this.petName,
    required this.equippedPetItemId,
    required this.ready,
    required this.owner,
    required this.connected,
    required this.breakVote,
  });

  factory CatudyOnlineLobbyMember.fromJson(Map<String, dynamic> json) {
    return CatudyOnlineLobbyMember(
      id: _readString(json, 'id'),
      lobbyId: _readString(json, 'lobby_id'),
      userId: _readString(json, 'user_id'),
      displayName: _readString(json, 'display_name', 'Guest Cat'),
      petId: _readString(json, 'pet_id', 'mochi'),
      petName: _readString(json, 'pet_name', 'White Cat'),
      equippedPetItemId: _readNullableString(json, 'equipped_pet_item_id'),
      ready: _readBool(json, 'ready'),
      owner: _readBool(json, 'owner'),
      connected: _readBool(json, 'connected', true),
      breakVote: _readNullableBool(json, 'break_vote'),
    );
  }

  final String id;
  final String lobbyId;
  final String userId;
  final String displayName;
  final String petId;
  final String petName;
  final String? equippedPetItemId;
  final bool ready;
  final bool owner;
  final bool connected;
  final bool? breakVote;
}

class CatudyLobbyJoinResult {
  const CatudyLobbyJoinResult({
    required this.lobby,
    required this.userId,
    required this.owner,
  });

  final CatudyOnlineLobby lobby;
  final String userId;
  final bool owner;
}

class CatudySupabaseLobbyService {
  CatudySupabaseLobbyService(this._client);

  final SupabaseClient _client;
  final _random = Random.secure();

  Future<CatudyLobbyJoinResult> createLobby({
    required String displayName,
    required String petId,
    required String petName,
    required String? equippedPetItemId,
    required String categoryId,
    required int durationMinutes,
  }) async {
    var userId = await _ensureAnonymousUser(displayName);
    Object? lastError;
    var recoveredAuth = false;
    for (var attempt = 0; attempt < 6; attempt++) {
      final code = _generateCode();
      try {
        final lobby = await _callLobbyRpc(
          'catudy_create_lobby',
          {
            'p_code': code,
            'p_display_name': displayName,
            'p_pet_id': petId,
            'p_pet_name': petName,
            'p_equipped_pet_item_id': equippedPetItemId,
            'p_category_id': categoryId,
            'p_duration_minutes': durationMinutes,
          },
        );
        return CatudyLobbyJoinResult(lobby: lobby, userId: userId, owner: true);
      } catch (error) {
        lastError = error;
        if (_isAuthError(error) && !recoveredAuth) {
          recoveredAuth = true;
          userId = await _resetAnonymousUser(displayName);
          continue;
        }
        if (!_isUniqueViolation(error)) {
          throw StateError('Lobby could not be created: ${_errorText(error)}');
        }
      }
    }
    throw StateError(
      'Lobby code could not be reserved: ${_errorText(lastError)}',
    );
  }

  Future<CatudyLobbyJoinResult> joinLobby({
    required String code,
    required String displayName,
    required String petId,
    required String petName,
    required String? equippedPetItemId,
  }) async {
    var userId = await _ensureAnonymousUser(displayName);
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final lobby = await _callLobbyRpc(
          'catudy_join_lobby',
          {
            'p_code': code.trim().toUpperCase(),
            'p_display_name': displayName,
            'p_pet_id': petId,
            'p_pet_name': petName,
            'p_equipped_pet_item_id': equippedPetItemId,
          },
        );
        final owner = lobby.ownerUserId == userId;
        return CatudyLobbyJoinResult(
          lobby: lobby,
          userId: userId,
          owner: owner,
        );
      } catch (error) {
        if (attempt == 0 && _isAuthError(error)) {
          userId = await _resetAnonymousUser(displayName);
          continue;
        }
        rethrow;
      }
    }
    throw StateError('Lobby could not be joined.');
  }

  Stream<CatudyOnlineLobby> watchLobby(String lobbyId) {
    return _client
        .from('catudy_lobbies')
        .stream(primaryKey: ['id'])
        .eq('id', lobbyId)
        .map((rows) => rows.map(CatudyOnlineLobby.fromJson).first);
  }

  Stream<List<CatudyOnlineLobbyMember>> watchMembers(String lobbyId) {
    return _client
        .from('catudy_lobby_members')
        .stream(primaryKey: ['id'])
        .eq('lobby_id', lobbyId)
        .order('joined_at', ascending: true)
        .map((rows) => rows.map(CatudyOnlineLobbyMember.fromJson).toList());
  }

  Future<void> setReady({
    required String lobbyId,
    required String userId,
    required bool ready,
  }) async {
    await _client.rpc(
      'catudy_set_lobby_ready',
      params: {'p_lobby_id': lobbyId, 'p_ready': ready},
    );
  }

  Future<void> setBreakVote({
    required String lobbyId,
    required String userId,
    required bool approved,
  }) async {
    await submitBreakVote(
      lobbyId: lobbyId,
      userId: userId,
      approved: approved,
    );
  }

  Future<void> submitBreakVote({
    required String lobbyId,
    required String userId,
    required bool approved,
  }) async {
    await _client.rpc(
      'catudy_submit_lobby_break_vote',
      params: {'target_lobby_id': lobbyId, 'approved': approved},
    );
  }

  Future<void> startLobby({
    required String lobbyId,
    required String ownerUserId,
    required String categoryId,
    required int durationMinutes,
  }) async {
    await _client.rpc(
      'catudy_start_lobby',
      params: {
        'p_lobby_id': lobbyId,
        'p_category_id': categoryId,
        'p_duration_minutes': durationMinutes,
      },
    );
  }

  Future<void> pauseLobby({
    required String lobbyId,
    required String ownerUserId,
    required String reason,
  }) async {
    await _client.rpc(
      'catudy_pause_lobby',
      params: {'p_lobby_id': lobbyId, 'p_reason': reason},
    );
  }

  Future<void> resumeLobby({
    required String lobbyId,
    required String ownerUserId,
    required int pausedSeconds,
  }) async {
    await _client.rpc(
      'catudy_resume_lobby',
      params: {
        'p_lobby_id': lobbyId,
        'p_paused_seconds': pausedSeconds.clamp(0, 86400 * 30).toInt(),
      },
    );
  }

  Future<void> finishLobby({
    required String lobbyId,
    required String ownerUserId,
  }) async {
    await _client.rpc(
      'catudy_finish_lobby',
      params: {'p_lobby_id': lobbyId},
    );
  }

  Future<void> leaveLobby({
    required String lobbyId,
    required String userId,
  }) async {
    await _client.rpc(
      'catudy_leave_lobby',
      params: {'p_lobby_id': lobbyId},
    );
  }

  Future<String> _ensureAnonymousUser(String displayName) async {
    final current = _client.auth.currentUser;
    if (current != null) {
      return current.id;
    }
    return _signInAnonymous(displayName);
  }

  Future<String> _resetAnonymousUser(String displayName) async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      // A stale browser session should not block creating a fresh guest user.
    }
    return _signInAnonymous(displayName);
  }

  Future<String> _signInAnonymous(String displayName) async {
    await _client.auth.signInAnonymously(
      data: {'display_name': displayName.trim()},
    );
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Supabase anonymous sign-in did not return a user.');
    }
    return user.id;
  }

  Future<CatudyOnlineLobby> _callLobbyRpc(
    String functionName,
    Map<String, Object?> params,
  ) async {
    final result = await _client.rpc(functionName, params: params);
    if (result is Map<String, dynamic>) {
      return CatudyOnlineLobby.fromJson(result);
    }
    if (result is Map) {
      return CatudyOnlineLobby.fromJson(Map<String, dynamic>.from(result));
    }
    if (result is List && result.isNotEmpty && result.first is Map) {
      return CatudyOnlineLobby.fromJson(
        Map<String, dynamic>.from(result.first as Map),
      );
    }
    throw StateError('Lobby RPC returned an unexpected response.');
  }

  String _generateCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      6,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    ).join();
  }
}

String _readString(
  Map<String, dynamic> json,
  String key, [
  String fallback = '',
]) {
  final value = json[key];
  return value is String && value.isNotEmpty ? value : fallback;
}

String? _readNullableString(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is String && value.isNotEmpty ? value : null;
}

int _readInt(Map<String, dynamic> json, String key, int fallback) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return fallback;
}

bool _readBool(Map<String, dynamic> json, String key, [bool fallback = false]) {
  final value = json[key];
  return value is bool ? value : fallback;
}

bool? _readNullableBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is bool ? value : null;
}

DateTime? _readDate(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value)?.toLocal();
}

bool _isUniqueViolation(Object error) {
  if (error is PostgrestException) {
    return error.code == '23505';
  }
  return '$error'.contains('duplicate key');
}

bool _isAuthError(Object error) {
  if (error is AuthException) {
    return true;
  }
  final text = '$error'.toLowerCase();
  return text.contains('jwt') ||
      text.contains('unauthorized') ||
      text.contains('invalid token') ||
      text.contains('session');
}

String _errorText(Object? error) {
  if (error == null) {
    return 'unknown error';
  }
  if (error is PostgrestException) {
    return error.message;
  }
  if (error is AuthException) {
    return error.message;
  }
  return '$error';
}
