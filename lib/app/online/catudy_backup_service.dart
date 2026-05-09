import 'package:supabase_flutter/supabase_flutter.dart';

class CatudyBackupSnapshot {
  const CatudyBackupSnapshot({
    required this.stateVersion,
    required this.data,
    required this.clientUpdatedAt,
  });

  final int stateVersion;
  final Map<String, dynamic> data;
  final DateTime clientUpdatedAt;
}

class CatudyBackupService {
  CatudyBackupService(this._client);

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<CatudyBackupSnapshot?> fetchCurrentBackup() async {
    final userId = currentUserId;
    if (userId == null) {
      return null;
    }
    final rows = await _client
        .from('catudy_user_backups')
        .select('state_version,data,client_updated_at')
        .eq('user_id', userId)
        .limit(1);
    if (rows.isEmpty) {
      return null;
    }
    final row = Map<String, dynamic>.from(rows.first);
    final data = row['data'];
    return CatudyBackupSnapshot(
      stateVersion: _readInt(row, 'state_version', 1),
      data: data is Map ? Map<String, dynamic>.from(data) : const {},
      clientUpdatedAt:
          DateTime.tryParse('${row['client_updated_at']}') ?? DateTime.now(),
    );
  }

  Future<void> upsertCurrentBackup({
    required Map<String, dynamic> data,
    required DateTime clientUpdatedAt,
    int stateVersion = 2,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      return;
    }
    await _client.from('catudy_user_backups').upsert({
      'user_id': userId,
      'state_version': stateVersion,
      'data': data,
      'client_updated_at': clientUpdatedAt.toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
  }
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
