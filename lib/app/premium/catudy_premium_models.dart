import 'package:flutter/material.dart';

enum PremiumSource { none, subscription, buddyPass }

class PremiumEntitlement {
  const PremiumEntitlement({
    required this.source,
    required this.activatedAt,
    required this.expiresAt,
  });

  const PremiumEntitlement.inactive()
    : source = PremiumSource.none,
      activatedAt = null,
      expiresAt = null;

  factory PremiumEntitlement.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PremiumEntitlement.inactive();
    }
    final source = switch (json['source']) {
      'subscription' => PremiumSource.subscription,
      'buddyPass' => PremiumSource.buddyPass,
      _ => PremiumSource.none,
    };
    return PremiumEntitlement(
      source: source,
      activatedAt: _readNullableDate(json['activatedAt']),
      expiresAt: _readNullableDate(json['expiresAt']),
    );
  }

  final PremiumSource source;
  final DateTime? activatedAt;
  final DateTime? expiresAt;

  bool get active =>
      source != PremiumSource.none &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  Map<String, dynamic> toJson() => {
    'source': switch (source) {
      PremiumSource.none => 'none',
      PremiumSource.subscription => 'subscription',
      PremiumSource.buddyPass => 'buddyPass',
    },
    'activatedAt': activatedAt?.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
  };
}

class BuddyPass {
  const BuddyPass({
    required this.code,
    required this.createdAt,
    required this.expiresAt,
    required this.redeemedByUserId,
    required this.redeemedAt,
  });

  factory BuddyPass.fromJson(Map<String, dynamic> json) {
    return BuddyPass(
      code: _readString(json, 'code'),
      createdAt: _readDate(json, 'createdAt'),
      expiresAt: _readDate(json, 'expiresAt'),
      redeemedByUserId: _readNullableString(json, 'redeemedByUserId'),
      redeemedAt: _readNullableDate(json['redeemedAt']),
    );
  }

  final String code;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? redeemedByUserId;
  final DateTime? redeemedAt;

  bool get redeemed => redeemedAt != null;
  bool get active => !redeemed && expiresAt.isAfter(DateTime.now());

  BuddyPass copyWith({String? redeemedByUserId, DateTime? redeemedAt}) {
    return BuddyPass(
      code: code,
      createdAt: createdAt,
      expiresAt: expiresAt,
      redeemedByUserId: redeemedByUserId ?? this.redeemedByUserId,
      redeemedAt: redeemedAt ?? this.redeemedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'redeemedByUserId': redeemedByUserId,
    'redeemedAt': redeemedAt?.toIso8601String(),
  };
}

class BuddyPassRedemption {
  const BuddyPassRedemption({required this.code, required this.redeemedAt});

  factory BuddyPassRedemption.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const BuddyPassRedemption(code: '', redeemedAt: null);
    }
    return BuddyPassRedemption(
      code: _readString(json, 'code'),
      redeemedAt: _readNullableDate(json['redeemedAt']),
    );
  }

  final String code;
  final DateTime? redeemedAt;

  bool get used => code.isNotEmpty && redeemedAt != null;

  Map<String, dynamic> toJson() => {
    'code': code,
    'redeemedAt': redeemedAt?.toIso8601String(),
  };
}

enum Rarity { common, rare, epic, legendary, mythic }

extension RarityX on Rarity {
  String get code => switch (this) {
    Rarity.common => 'common',
    Rarity.rare => 'rare',
    Rarity.epic => 'epic',
    Rarity.legendary => 'legendary',
    Rarity.mythic => 'mythic',
  };

  int get shardValue => switch (this) {
    Rarity.common => 5,
    Rarity.rare => 12,
    Rarity.epic => 24,
    Rarity.legendary => 48,
    Rarity.mythic => 90,
  };
}

Rarity rarityFromCode(String code) => switch (code) {
  'rare' => Rarity.rare,
  'epic' => Rarity.epic,
  'legendary' => Rarity.legendary,
  'mythic' => Rarity.mythic,
  _ => Rarity.common,
};

enum LootCrateType { cat, room, style }

class CosmeticItem {
  const CosmeticItem({
    required this.id,
    required this.name,
    required this.description,
    required this.slot,
    required this.rarity,
    required this.accent,
    required this.icon,
    required this.crateType,
    required this.directPrice,
    required this.premiumOnly,
    required this.seasonal,
    this.assetPath,
    this.animated = false,
  });

  final String id;
  final String name;
  final String description;
  final String slot;
  final Rarity rarity;
  final Color accent;
  final IconData icon;
  final LootCrateType crateType;
  final int? directPrice;
  final bool premiumOnly;
  final bool seasonal;
  final String? assetPath;
  final bool animated;
}

class LootPool {
  const LootPool({
    required this.id,
    required this.name,
    required this.itemIds,
    required this.seasonal,
    required this.premiumOnly,
  });

  final String id;
  final String name;
  final List<String> itemIds;
  final bool seasonal;
  final bool premiumOnly;
}

class LootCrate {
  const LootCrate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.poolId,
    required this.price,
    required this.seasonal,
    required this.premiumOnly,
  });

  final String id;
  final String name;
  final String description;
  final LootCrateType type;
  final String poolId;
  final int price;
  final bool seasonal;
  final bool premiumOnly;
}

class ShardWallet {
  const ShardWallet({required this.shards});

  factory ShardWallet.fromJson(Map<String, dynamic>? json) {
    return ShardWallet(shards: _readInt(json, 'shards', 0));
  }

  final int shards;

  ShardWallet copyWith({int? shards}) =>
      ShardWallet(shards: shards ?? this.shards);

  Map<String, dynamic> toJson() => {'shards': shards};
}

class PityState {
  const PityState({required this.opensSinceRare, required this.opensSinceEpic});

  factory PityState.fromJson(Map<String, dynamic>? json) {
    return PityState(
      opensSinceRare: _readInt(json, 'opensSinceRare', 0),
      opensSinceEpic: _readInt(json, 'opensSinceEpic', 0),
    );
  }

  final int opensSinceRare;
  final int opensSinceEpic;

  PityState copyWith({int? opensSinceRare, int? opensSinceEpic}) => PityState(
    opensSinceRare: opensSinceRare ?? this.opensSinceRare,
    opensSinceEpic: opensSinceEpic ?? this.opensSinceEpic,
  );

  Map<String, dynamic> toJson() => {
    'opensSinceRare': opensSinceRare,
    'opensSinceEpic': opensSinceEpic,
  };
}

enum SeasonRewardKind { gold, crate, cosmetic }

class SeasonReward {
  const SeasonReward({
    required this.id,
    required this.title,
    required this.thresholdMinutes,
    required this.kind,
    required this.payload,
    required this.premiumOnly,
  });

  final String id;
  final String title;
  final int thresholdMinutes;
  final SeasonRewardKind kind;
  final String payload;
  final bool premiumOnly;
}

class SeasonRewardTrack {
  const SeasonRewardTrack({required this.rewards});

  final List<SeasonReward> rewards;
}

class Season {
  const Season({
    required this.id,
    required this.name,
    required this.description,
    required this.startsAt,
    required this.endsAt,
    required this.freeTrack,
    required this.premiumTrack,
  });

  final String id;
  final String name;
  final String description;
  final DateTime startsAt;
  final DateTime endsAt;
  final SeasonRewardTrack freeTrack;
  final SeasonRewardTrack premiumTrack;

  bool get active {
    final now = DateTime.now();
    return !now.isBefore(startsAt) && now.isBefore(endsAt);
  }

  int get targetMinutes {
    final thresholds = [
      ...freeTrack.rewards.map((reward) => reward.thresholdMinutes),
      ...premiumTrack.rewards.map((reward) => reward.thresholdMinutes),
    ];
    return thresholds.isEmpty ? 0 : thresholds.reduce((a, b) => a >= b ? a : b);
  }
}

class SeasonProgress {
  const SeasonProgress({
    required this.seasonId,
    required this.focusMinutes,
    required this.claimedRewardIds,
  });

  factory SeasonProgress.fromJson(Map<String, dynamic>? json) {
    return SeasonProgress(
      seasonId: _readString(json, 'seasonId'),
      focusMinutes: _readInt(json, 'focusMinutes', 0),
      claimedRewardIds: _readStringList(json?['claimedRewardIds']).toSet(),
    );
  }

  final String seasonId;
  final int focusMinutes;
  final Set<String> claimedRewardIds;

  SeasonProgress copyWith({
    String? seasonId,
    int? focusMinutes,
    Set<String>? claimedRewardIds,
  }) {
    return SeasonProgress(
      seasonId: seasonId ?? this.seasonId,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      claimedRewardIds: claimedRewardIds ?? this.claimedRewardIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'seasonId': seasonId,
    'focusMinutes': focusMinutes,
    'claimedRewardIds': claimedRewardIds.toList(),
  };
}

class CoachRecommendation {
  const CoachRecommendation({
    required this.categoryId,
    required this.minutes,
    required this.headline,
    required this.reason,
    required this.basedOnHistory,
    required this.sessionsConsidered,
  });

  final String categoryId;
  final int minutes;
  final String headline;
  final String reason;
  final bool basedOnHistory;
  final int sessionsConsidered;
}

class EconomyBalance {
  const EconomyBalance({
    required this.premiumGoldBonusBasisPoints,
    required this.rarePityThreshold,
    required this.epicPityThreshold,
  });

  static const launch = EconomyBalance(
    premiumGoldBonusBasisPoints: 1500,
    rarePityThreshold: 6,
    epicPityThreshold: 18,
  );

  final int premiumGoldBonusBasisPoints;
  final int rarePityThreshold;
  final int epicPityThreshold;
}

String _readString(Map<String, dynamic>? json, String key) {
  final value = json?[key];
  return value is String ? value : '';
}

String? _readNullableString(Map<String, dynamic>? json, String key) {
  final value = json?[key];
  return value is String && value.isNotEmpty ? value : null;
}

DateTime _readDate(Map<String, dynamic>? json, String key) {
  final value = json?[key];
  return value is String
      ? DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0)
      : DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _readNullableDate(Object? value) {
  return value is String ? DateTime.tryParse(value) : null;
}

int _readInt(Map<String, dynamic>? json, String key, int fallback) {
  final value = json?[key];
  return value is int
      ? value
      : value is num
      ? value.toInt()
      : fallback;
}

List<String> _readStringList(Object? value) {
  return value is List ? value.whereType<String>().toList() : const [];
}
