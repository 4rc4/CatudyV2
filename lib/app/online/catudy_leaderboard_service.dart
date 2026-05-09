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
      petName: _readString(json, 'pet_name', 'Mochi'),
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

  Stream<List<CatudyOnlineLeaderboardProfile>> watchTopProfiles() {
    return _client
        .from('catudy_leaderboard')
        .stream(primaryKey: ['user_id'])
        .order('points', ascending: false)
        .limit(50)
        .map((rows) {
          final profiles = rows
              .map(CatudyOnlineLeaderboardProfile.fromJson)
              .where((profile) => profile.userId.isNotEmpty)
              .toList();
          profiles.sort((a, b) {
            final points = b.points.compareTo(a.points);
            if (points != 0) {
              return points;
            }
            return b.totalMinutes.compareTo(a.totalMinutes);
          });
          return profiles;
        });
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
    await _client.from('catudy_leaderboard').upsert({
      'user_id': userId,
      'display_name': displayName.trim().isEmpty
          ? 'Guest Cat'
          : displayName.trim(),
      'pet_id': petId,
      'pet_name': petName.trim().isEmpty ? 'Mochi' : petName.trim(),
      'equipped_pet_item_id': equippedPetItemId,
      'room_item_ids': roomItemIds,
      'points': points,
      'total_minutes': totalMinutes,
      'streak_days': streakDays,
      'sessions_count': sessionsCount,
      'favorite_category': favoriteCategory,
      'stats_public': statsPublic,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
    return userId;
  }
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
