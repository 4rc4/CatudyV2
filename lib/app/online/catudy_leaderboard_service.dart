import 'package:supabase_flutter/supabase_flutter.dart';

class CatudyOnlineLeaderboardProfile {
  const CatudyOnlineLeaderboardProfile({
    required this.userId,
    required this.displayName,
    required this.petId,
    required this.petName,
    required this.equippedPetItemId,
    required this.roomItemIds,
    required this.points,
    required this.totalMinutes,
    required this.streakDays,
    required this.sessionsCount,
    required this.favoriteCategory,
    required this.statsPublic,
  });

  factory CatudyOnlineLeaderboardProfile.fromJson(Map<String, dynamic> json) {
    return CatudyOnlineLeaderboardProfile(
      userId: _readString(json, 'user_id'),
      displayName: _readString(json, 'display_name', 'Guest Cat'),
      petId: _readString(json, 'pet_id', 'mochi'),
      petName: _readString(json, 'pet_name', 'White Cat'),
      equippedPetItemId: _readNullableString(json, 'equipped_pet_item_id'),
      roomItemIds: _readStringMap(json['room_item_ids']),
      points: _readInt(json, 'points', 0),
      totalMinutes: _readInt(json, 'total_minutes', 0),
      streakDays: _readInt(json, 'streak_days', 0),
      sessionsCount: _readInt(json, 'sessions_count', 0),
      favoriteCategory: _readString(json, 'favorite_category', ''),
      statsPublic: _readBool(json, 'stats_public', true),
    );
  }

  final String userId;
  final String displayName;
  final String petId;
  final String petName;
  final String? equippedPetItemId;
  final Map<String, String> roomItemIds;
  final int points;
  final int totalMinutes;
  final int streakDays;
  final int sessionsCount;
  final String favoriteCategory;
  final bool statsPublic;
}

class CatudyLeaderboardService {
  CatudyLeaderboardService(this._client);

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<CatudyOnlineLeaderboardProfile>> fetchTopProfiles() async {
    final rows = await _client
        .from('catudy_leaderboard')
        .select()
        .order('total_minutes', ascending: false)
        .order('points', ascending: false)
        .limit(50);
    return _profilesFromRows(rows);
  }

  Stream<List<CatudyOnlineLeaderboardProfile>> watchTopProfiles() async* {
    try {
      yield await fetchTopProfiles();
    } catch (_) {
      // Realtime may still connect even if the initial REST fetch is blocked.
    }
    yield* _client
        .from('catudy_leaderboard')
        .stream(primaryKey: ['user_id'])
        .order('total_minutes', ascending: false)
        .limit(50)
        .map(_profilesFromRows);
  }

  Future<CatudyOnlineLeaderboardProfile?> fetchProfile(String userId) async {
    final rows = await _client
        .from('catudy_public_profiles')
        .select()
        .eq('user_id', userId)
        .limit(1);
    if (rows.isEmpty) {
      return null;
    }
    return CatudyOnlineLeaderboardProfile.fromJson(rows.first);
  }

  Future<String?> upsertCurrentProfile({
    required String displayName,
    required String petId,
    required String petName,
    required String? equippedPetItemId,
    required Map<String, String> roomItemIds,
    required int points,
    required int totalMinutes,
    required int streakDays,
    required int sessionsCount,
    required String favoriteCategory,
    required bool statsPublic,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }
    await _client.rpc(
      'catudy_update_public_profile',
      params: {
        'p_display_name': displayName.trim().isEmpty
            ? 'Guest Cat'
            : displayName.trim(),
        'p_pet_id': petId.trim().isEmpty ? 'mochi' : petId.trim(),
        'p_pet_name': petName.trim().isEmpty ? 'White Cat' : petName.trim(),
        'p_equipped_pet_item_id': equippedPetItemId,
        'p_room_item_ids': roomItemIds,
        'p_stats_public': statsPublic,
      },
    );
    return userId;
  }

  Future<bool> completeFocusSession({
    required String clientSessionId,
    required String categoryId,
    required int minutes,
    required DateTime completedAt,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || clientSessionId.isEmpty || minutes <= 0) {
      return false;
    }
    final result = await _client.rpc(
      'catudy_complete_focus_session',
      params: {
        'p_client_session_id': clientSessionId,
        'p_category_id': categoryId.trim().isEmpty
            ? 'study'
            : categoryId.trim(),
        'p_minutes': minutes.clamp(1, 240).toInt(),
        'p_completed_at': completedAt.toUtc().toIso8601String(),
      },
    );
    return result == true;
  }
}

List<CatudyOnlineLeaderboardProfile> _profilesFromRows(Iterable rows) {
  final profiles = rows
      .whereType<Map>()
      .map(
        (row) => CatudyOnlineLeaderboardProfile.fromJson(
          Map<String, dynamic>.from(row),
        ),
      )
      .where((profile) => profile.userId.isNotEmpty)
      .toList();
  profiles.sort((a, b) {
    final minutes = b.totalMinutes.compareTo(a.totalMinutes);
    if (minutes != 0) {
      return minutes;
    }
    return b.points.compareTo(a.points);
  });
  return profiles;
}

String? _readNullableString(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is String && value.isNotEmpty ? value : null;
}

String _readString(
  Map<String, dynamic> json,
  String key, [
  String fallback = '',
]) {
  final value = json[key];
  return value is String && value.isNotEmpty ? value : fallback;
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

bool _readBool(Map<String, dynamic> json, String key, bool fallback) {
  final value = json[key];
  return value is bool ? value : fallback;
}

Map<String, String> _readStringMap(Object? value) {
  if (value is! Map) {
    return const {};
  }
  return {
    for (final entry in value.entries)
      if (entry.key is String && entry.value is String)
        entry.key as String: entry.value as String,
  };
}
