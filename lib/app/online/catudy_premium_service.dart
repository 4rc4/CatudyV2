import 'package:supabase_flutter/supabase_flutter.dart';

import '../premium/catudy_premium_models.dart';

class CatudyPremiumSnapshot {
  const CatudyPremiumSnapshot({
    required this.entitlement,
    required this.issuedBuddyPasses,
    required this.redemption,
    required this.grantedCosmeticIds,
  });

  final PremiumEntitlement entitlement;
  final List<BuddyPass> issuedBuddyPasses;
  final BuddyPassRedemption redemption;
  final Set<String> grantedCosmeticIds;
}

class CatudyPremiumService {
  CatudyPremiumService(this._client);

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<CatudyPremiumSnapshot?> fetchCurrentState() async {
    final userId = currentUserId;
    if (userId == null) {
      return null;
    }

    final entitlementRows = await _client
        .from('catudy_premium_entitlements')
        .select('source,activated_at,expires_at')
        .eq('user_id', userId)
        .limit(1);
    final passRows = await _client
        .from('catudy_buddy_passes')
        .select('code,created_at,expires_at,redeemed_by_user_id,redeemed_at')
        .eq('sender_user_id', userId)
        .order('created_at', ascending: true);
    final redemptionRows = await _client
        .from('catudy_buddy_pass_redemptions')
        .select('buddy_pass_code,redeemed_at')
        .eq('user_id', userId)
        .limit(1);
    final rewardRows = await _client
        .from('catudy_reward_grants')
        .select('reward_key')
        .eq('user_id', userId);

    final entitlement = entitlementRows.isEmpty
        ? const PremiumEntitlement.inactive()
        : PremiumEntitlement.fromJson(
            _normalizeEntitlementRow(entitlementRows.first),
          );
    final passes = passRows
        .whereType<Map>()
        .map((row) => BuddyPass.fromJson(_normalizeBuddyPassRow(row)))
        .where((pass) => pass.code.isNotEmpty)
        .toList();
    final redemption = redemptionRows.isEmpty
        ? const BuddyPassRedemption(code: '', redeemedAt: null)
        : BuddyPassRedemption.fromJson(
            _normalizeRedemptionRow(redemptionRows.first),
          );
    return CatudyPremiumSnapshot(
      entitlement: entitlement,
      issuedBuddyPasses: passes,
      redemption: redemption,
      grantedCosmeticIds: rewardRows
          .whereType<Map>()
          .map((row) => row['reward_key'])
          .whereType<String>()
          .toSet(),
    );
  }

  Future<BuddyPass?> createBuddyPass() async {
    if (currentUserId == null) {
      return null;
    }
    final result = await _client.rpc('catudy_create_buddy_pass');
    final row = switch (result) {
      final List rows when rows.isNotEmpty && rows.first is Map =>
        rows.first as Map,
      final Map row => row,
      _ => null,
    };
    if (row == null) {
      return null;
    }
    return BuddyPass.fromJson(_normalizeBuddyPassRow(row));
  }

  Future<bool> redeemBuddyPass(String code) async {
    if (currentUserId == null) {
      return false;
    }
    final result = await _client.rpc(
      'catudy_redeem_buddy_pass',
      params: {'pass_code': code.trim().toUpperCase()},
    );
    return result == true;
  }
}

Map<String, dynamic> _normalizeEntitlementRow(Map row) => {
  'source': row['source'],
  'activatedAt': row['activated_at'],
  'expiresAt': row['expires_at'],
};

Map<String, dynamic> _normalizeBuddyPassRow(Map row) => {
  'code': row['code'],
  'createdAt': row['created_at'],
  'expiresAt': row['expires_at'],
  'redeemedByUserId': row['redeemed_by_user_id'],
  'redeemedAt': row['redeemed_at'],
};

Map<String, dynamic> _normalizeRedemptionRow(Map row) => {
  'code': row['buddy_pass_code'],
  'redeemedAt': row['redeemed_at'],
};
