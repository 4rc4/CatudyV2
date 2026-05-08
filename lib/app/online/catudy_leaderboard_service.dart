import 'package:supabase_flutter/supabase_flutter.dart';

class CatudyOnlineLeaderboardProfile {
  const CatudyOnlineLeaderboardProfile({
    required this.userId,
    required this.displayName,
    required this.petId,
    required this.points,
    required this.totalMinutes,
    required this.streakDays,
  });

  factory CatudyOnlineLeaderboardProfile.fromJson(Map<String, dynamic> json) {
    return CatudyOnlineLeaderboardProfile(
      userId: _readString(json, 'user_id'),
      displayName: _readString(json, 'display_name', 'Guest Cat'),
      petId: _readString(json, 'pet_id', 'mochi'),
      points: _readInt(json, 'points', 0),
      totalMinutes: _readInt(json, 'total_minutes', 0),
      streakDays: _readInt(json, 'streak_days', 0),
    );
  }

  final String userId;
  final String displayName;
  final String petId;
  final int points;
  final int totalMinutes;
  final int streakDays;
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

  Future<String?> upsertCurrentProfile({
    required String displayName,
    required String petId,
    required int points,
    required int totalMinutes,
    required int streakDays,
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
      'points': points,
      'total_minutes': totalMinutes,
      'streak_days': streakDays,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
    return userId;
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
