import 'package:supabase_flutter/supabase_flutter.dart';

class CatudyOnlineFriendRequest {
  const CatudyOnlineFriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.createdAt,
  });

  factory CatudyOnlineFriendRequest.fromJson(Map<String, dynamic> json) {
    return CatudyOnlineFriendRequest(
      id: _readString(json, 'id'),
      fromUserId: _readString(json, 'requester_user_id'),
      toUserId: _readString(json, 'receiver_user_id'),
      createdAt:
          DateTime.tryParse(_readString(json, 'created_at')) ?? DateTime.now(),
    );
  }

  final String id;
  final String fromUserId;
  final String toUserId;
  final DateTime createdAt;
}

class CatudySocialService {
  CatudySocialService(this._client);

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Stream<List<CatudyOnlineFriendRequest>> watchPendingRequests() {
    return _client
        .from('catudy_friend_requests')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .map(CatudyOnlineFriendRequest.fromJson)
              .where(
                (request) =>
                    request.id.isNotEmpty &&
                    request.fromUserId.isNotEmpty &&
                    request.toUserId.isNotEmpty,
              )
              .toList(),
        );
  }

  Stream<List<String>> watchFriendIds() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value(const []);
    }
    return _client
        .from('catudy_friends')
        .stream(primaryKey: ['owner_user_id', 'friend_user_id'])
        .eq('owner_user_id', userId)
        .map(
          (rows) => rows
              .map((row) => _readString(row, 'friend_user_id'))
              .where((id) => id.isNotEmpty)
              .toList(),
        );
  }

  Future<void> sendFriendRequest(String receiverUserId) async {
    final userId = currentUserId;
    if (userId == null) {
      throw StateError('Sign in before sending friend requests.');
    }
    await _client.from('catudy_friend_requests').insert({
      'requester_user_id': userId,
      'receiver_user_id': receiverUserId,
      'status': 'pending',
    });
  }

  Future<void> acceptFriendRequest(String requestId) async {
    await _client
        .from('catudy_friend_requests')
        .update({
          'status': 'accepted',
          'responded_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', requestId);
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await _client
        .from('catudy_friend_requests')
        .update({
          'status': 'rejected',
          'responded_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', requestId);
  }

  Future<void> removeFriend(String friendUserId) async {
    final userId = currentUserId;
    if (userId == null) {
      return;
    }
    await _client
        .from('catudy_friends')
        .delete()
        .eq('owner_user_id', userId)
        .eq('friend_user_id', friendUserId);
  }
}

String _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is String ? value : '';
}
