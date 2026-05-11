import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../localization/catudy_copy.dart';
import '../online/catudy_auth_service.dart';
import '../online/catudy_backup_service.dart';
import '../online/catudy_leaderboard_service.dart';
import '../online/catudy_lobby_service.dart';
import '../online/catudy_social_service.dart';
import '../storage/catudy_local_storage.dart';
import '../theme/catudy_colors.dart';

final catudyDemoStore = CatudyDemoStore();

class FocusCategory {
  const FocusCategory({
    required this.id,
    required this.name,
    required this.color,
    this.updatedAt,
  });

  factory FocusCategory.fromJson(Map<String, dynamic> json) {
    return FocusCategory(
      id: _readString(json, 'id', 'study'),
      name: _readString(json, 'name', 'Study'),
      color: Color(_readInt(json, 'color', CatudyColors.violet.toARGB32())),
      updatedAt: _readNullableDate(json, 'updatedAt'),
    );
  }

  final String id;
  final String name;
  final Color color;
  final DateTime? updatedAt;

  FocusCategory copyWith({String? name, DateTime? updatedAt}) {
    return FocusCategory(
      id: id,
      name: name ?? this.name,
      color: color,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color.toARGB32(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };
}

class FocusRecord {
  const FocusRecord({
    required this.id,
    required this.categoryId,
    required this.minutes,
    required this.createdAt,
    required this.updatedAt,
    required this.manual,
    required this.note,
    required this.gold,
    this.todoId,
  });

  factory FocusRecord.fromJson(Map<String, dynamic> json) {
    final categoryId = _readString(json, 'categoryId', 'study');
    final minutes = _readInt(json, 'minutes', 25);
    final createdAt = _readDate(json, 'createdAt', DateTime.now());
    final manual = _readBool(json, 'manual', false);
    final note = _readString(json, 'note', 'Focus session');
    final todoId = _readNullableString(json, 'todoId');
    return FocusRecord(
      id: _readString(
        json,
        'id',
        _legacyEntityId('focus', [
          categoryId,
          minutes,
          createdAt.toIso8601String(),
          manual,
          note,
          todoId ?? '',
        ]),
      ),
      categoryId: categoryId,
      minutes: minutes,
      createdAt: createdAt,
      updatedAt: _readDate(json, 'updatedAt', createdAt),
      manual: manual,
      note: note,
      gold: _readInt(json, 'gold', 0),
      todoId: todoId,
    );
  }

  final String id;
  final String categoryId;
  final int minutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool manual;
  final String note;
  final int gold;
  final String? todoId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'categoryId': categoryId,
    'minutes': minutes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'manual': manual,
    'note': note,
    'gold': gold,
    'todoId': todoId,
  };
}

class CalendarTodo {
  const CalendarTodo({
    required this.id,
    required this.title,
    required this.date,
    required this.hour,
    required this.minute,
    required this.done,
    required this.updatedAt,
  });

  factory CalendarTodo.fromJson(Map<String, dynamic> json) {
    final id = _readString(
      json,
      'id',
      DateTime.now().microsecondsSinceEpoch.toString(),
    );
    final date = _readDate(json, 'date', DateTime.now());
    return CalendarTodo(
      id: id,
      title: _readString(json, 'title', 'Hatırlatma'),
      date: date,
      hour: _readInt(json, 'hour', 9).clamp(0, 23),
      minute: _readInt(json, 'minute', 0).clamp(0, 59),
      done: _readBool(json, 'done', false),
      updatedAt: _readDate(json, 'updatedAt', date),
    );
  }

  final String id;
  final String title;
  final DateTime date;
  final int hour;
  final int minute;
  final bool done;
  final DateTime updatedAt;

  DateTime get scheduledAt =>
      DateTime(date.year, date.month, date.day, hour, minute);

  CalendarTodo copyWith({bool? done, DateTime? updatedAt}) {
    return CalendarTodo(
      id: id,
      title: title,
      date: date,
      hour: hour,
      minute: minute,
      done: done ?? this.done,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
    'hour': hour,
    'minute': minute,
    'done': done,
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class ActiveFocusSession {
  const ActiveFocusSession({
    required this.categoryId,
    required this.durationMinutes,
    required this.startedAt,
    required this.lobbyMode,
    this.todoId,
  });

  factory ActiveFocusSession.fromJson(Map<String, dynamic> json) {
    return ActiveFocusSession(
      categoryId: _readString(json, 'categoryId', 'study'),
      durationMinutes: _readInt(json, 'durationMinutes', 25),
      startedAt: _readDate(json, 'startedAt', DateTime.now()),
      lobbyMode: _readBool(json, 'lobbyMode', false),
      todoId: _readNullableString(json, 'todoId'),
    );
  }

  final String categoryId;
  final int durationMinutes;
  final DateTime startedAt;
  final bool lobbyMode;
  final String? todoId;

  DateTime get plannedEndAt =>
      startedAt.add(Duration(minutes: durationMinutes));

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'durationMinutes': durationMinutes,
    'startedAt': startedAt.toIso8601String(),
    'lobbyMode': lobbyMode,
    'todoId': todoId,
  };
}

class DailyGoalProgress {
  const DailyGoalProgress({
    required this.goalMinutes,
    required this.completedMinutes,
  });

  final int goalMinutes;
  final int completedMinutes;

  int get remainingMinutes => (goalMinutes - completedMinutes).clamp(0, 10000);

  double get ratio =>
      goalMinutes <= 0 ? 0 : (completedMinutes / goalMinutes).clamp(0.0, 1.0);

  bool get completed => goalMinutes > 0 && completedMinutes >= goalMinutes;
}

class CatudyAchievement {
  const CatudyAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.progress,
    required this.target,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int progress;
  final int target;

  bool get unlocked => progress >= target;
  double get ratio => target <= 0 ? 1 : (progress / target).clamp(0.0, 1.0);
}

class CatudyCelebration {
  const CatudyCelebration({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
  });

  final String id;
  final String title;
  final String body;
  final IconData icon;
}

class SocialChallenge {
  const SocialChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.targetMinutes,
    required this.currentMinutes,
    required this.participants,
  });

  final String id;
  final String title;
  final String description;
  final int targetMinutes;
  final int currentMinutes;
  final int participants;

  int get remainingMinutes => (targetMinutes - currentMinutes).clamp(0, 10000);
  double get ratio =>
      targetMinutes <= 0 ? 0 : (currentMinutes / targetMinutes).clamp(0.0, 1.0);
  bool get completed => currentMinutes >= targetMinutes;
}

enum FriendAddResult { added, alreadyFriend, self, notFound, empty }

enum FriendRequestActionResult {
  sent,
  alreadyFriend,
  alreadyPending,
  self,
  notFound,
  blocked,
  empty,
}

class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: _readString(
        json,
        'id',
        DateTime.now().microsecondsSinceEpoch.toString(),
      ),
      fromUserId: _readString(json, 'fromUserId', ''),
      toUserId: _readString(json, 'toUserId', ''),
      createdAt: _readDate(json, 'createdAt', DateTime.now()),
    );
  }

  final String id;
  final String fromUserId;
  final String toUserId;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromUserId': fromUserId,
    'toUserId': toUserId,
    'createdAt': createdAt.toIso8601String(),
  };
}

class UnlockablePet {
  const UnlockablePet({
    required this.id,
    required this.name,
    required this.requiredPoints,
    required this.description,
    required this.accent,
  });

  final String id;
  final String name;
  final int requiredPoints;
  final String description;
  final Color accent;
}

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.slot,
    required this.rarity,
    required this.accent,
    required this.icon,
    this.assetPath,
  });

  final String id;
  final String name;
  final String description;
  final int price;
  final String slot;
  final String rarity;
  final Color accent;
  final IconData icon;
  final String? assetPath;

  bool get isRoomFurniture => slot.startsWith('room_');

  int get rewardBoostBasisPoints =>
      isRoomFurniture ? price.clamp(0, 800).toInt() : 0;
}

class LobbyMember {
  const LobbyMember({
    required this.userId,
    required this.name,
    required this.ready,
    required this.owner,
    required this.connected,
    required this.breakVote,
  });

  final String userId;
  final String name;
  final bool ready;
  final bool owner;
  final bool connected;
  final bool? breakVote;
}

class FocusRecommendation {
  const FocusRecommendation({
    required this.categoryId,
    required this.minutes,
    required this.basedOnHistory,
    required this.sessionsConsidered,
  });

  final String categoryId;
  final int minutes;
  final bool basedOnHistory;
  final int sessionsConsidered;
}

class LeaderboardProfile {
  const LeaderboardProfile({
    required this.userId,
    required this.name,
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
    required this.currentUser,
  });

  final String userId;
  final String name;
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
  final bool currentUser;
}

class CatudyDemoStore extends ChangeNotifier {
  CatudyDemoStore({CatudyLocalStorage storage = const CatudyLocalStorage()})
    : _storage = storage {
    _applyDefaults();
  }

  static const supportedLanguageCodes = ['tr', 'en'];

  final CatudyLocalStorage _storage;
  CatudyAuthService? _authService;
  CatudyBackupService? _backupService;
  CatudySupabaseLobbyService? _lobbyService;
  CatudyLeaderboardService? _leaderboardService;
  CatudySocialService? _socialService;
  StreamSubscription<CatudyAuthSession?>? _authSubscription;
  StreamSubscription<CatudyOnlineLobby>? _onlineLobbySubscription;
  StreamSubscription<List<CatudyOnlineLobbyMember>>? _onlineMembersSubscription;
  StreamSubscription<List<CatudyOnlineLeaderboardProfile>>?
  _leaderboardSubscription;
  StreamSubscription<List<CatudyOnlineFriendRequest>>?
  _friendRequestsSubscription;
  StreamSubscription<List<String>>? _friendsSubscription;
  StreamSubscription<List<String>>? _blockedUsersSubscription;
  void Function(String name, String languageCode)? _friendRequestNotifier;
  final _knownIncomingFriendRequestIds = <String>{};
  Future<void>? _loadFuture;
  bool _loaded = false;
  bool _restoredCompletedSession = false;
  List<LobbyMember>? _onlineLobbyMembers;
  List<LeaderboardProfile>? _onlineLeaderboardProfiles;
  final _fetchedProfiles = <String, LeaderboardProfile>{};
  final _profileFetches = <String>{};
  Timer? _leaderboardSyncTimer;
  Timer? _backupSyncTimer;
  Timer? _focusCompletionTimer;
  Future<void>? _backupMergeFuture;
  String? _lastBackupMergedUserId;
  bool _backupMergeInProgress = false;
  String? _explicitGuestUserId;
  bool _explicitGuestSignInPending = false;
  Future<void> Function()? _notificationSync;
  final _pendingCelebrations = <CatudyCelebration>[];

  final categories = <FocusCategory>[];
  final durations = <int>[15, 25, 40, 60];
  final history = <FocusRecord>[];
  final todos = <CalendarTodo>[];
  final friendUserIds = <String>{};
  final friendRequests = <FriendRequest>[];
  final blockedUserIds = <String>{};
  final reportedUserIds = <String>{};
  final ownedItems = <String>{};
  final equippedRoomItemIds = <String, String>{};
  final unlockedPetIds = <String>{};
  final _pendingUnlockedPetIds = <String>[];

  final unlockablePets = <UnlockablePet>[
    const UnlockablePet(
      id: 'mochi',
      name: 'Mochi',
      requiredPoints: 0,
      description: 'Başlangıç odak dostu.',
      accent: CatudyColors.violet,
    ),
    const UnlockablePet(
      id: 'miso',
      name: 'Miso',
      requiredPoints: 1000,
      description: '1000 odak puanında kilidi açılır.',
      accent: CatudyColors.coral,
    ),
    const UnlockablePet(
      id: 'luna',
      name: 'Luna',
      requiredPoints: 2500,
      description: '2500 odak puanında kilidi açılır.',
      accent: CatudyColors.teal,
    ),
  ];

  final shopItems = <ShopItem>[
    const ShopItem(
      id: 'violet_collar',
      name: 'Violet Collar',
      description: 'A soft profile cosmetic for Mochi.',
      price: 80,
      slot: 'pet',
      rarity: 'common',
      accent: CatudyColors.violet,
      icon: Icons.workspace_premium_rounded,
    ),
    const ShopItem(
      id: 'focus_badge',
      name: 'Focus Badge',
      description: 'Shown on your public profile.',
      price: 120,
      slot: 'profile',
      rarity: 'rare',
      accent: CatudyColors.teal,
      icon: Icons.military_tech_rounded,
    ),
    const ShopItem(
      id: 'sunny_hat',
      name: 'Sunny Hat',
      description: 'A warm cosmetic for Pet Room.',
      price: 160,
      slot: 'pet',
      rarity: 'rare',
      accent: CatudyColors.teal,
      icon: Icons.wb_sunny_rounded,
    ),
    const ShopItem(
      id: 'soft_study_nook',
      name: 'Yumuşak Çalışma Alanı',
      description: 'Mochi için minderli, alçak bir çalışma köşesi.',
      price: 110,
      slot: 'room_study',
      rarity: 'common',
      accent: CatudyColors.teal,
      icon: Icons.auto_stories_rounded,
      assetPath: 'assets/room/corner_study_desk_v1.png',
    ),
    const ShopItem(
      id: 'moonlit_study_nook',
      name: 'Ay Işıklı Çalışma Alanı',
      description: 'Odak seanslarında defter ve ışığıyla öne çıkan alan.',
      price: 240,
      slot: 'room_study',
      rarity: 'rare',
      accent: CatudyColors.violet,
      icon: Icons.lightbulb_rounded,
      assetPath: 'assets/room/corner_study_desk_moonlit_v1.png',
    ),
    const ShopItem(
      id: 'cloud_nap_bed',
      name: 'Bulut Yatak',
      description: 'Odanın sağ köşesine yerleşen yumuşak uyku alanı.',
      price: 150,
      slot: 'room_bed',
      rarity: 'common',
      accent: CatudyColors.lavender,
      icon: Icons.bed_rounded,
      assetPath: 'assets/room/corner_cat_bed_v1.png',
    ),
    const ShopItem(
      id: 'warm_den_bed',
      name: 'Sıcak Yuva Yatağı',
      description: 'Daha derin gölgeli, konforlu bir pet yatağı.',
      price: 260,
      slot: 'room_bed',
      rarity: 'rare',
      accent: CatudyColors.coral,
      icon: Icons.weekend_rounded,
      assetPath: 'assets/room/corner_cat_bed_warm_v1.png',
    ),
    const ShopItem(
      id: 'glow_lantern',
      name: 'Parlayan Oda Lambası',
      description: 'Odanın derinliğini güçlendiren küçük bir ışık.',
      price: 130,
      slot: 'room_decor',
      rarity: 'common',
      accent: CatudyColors.yellow,
      icon: Icons.emoji_objects_rounded,
      assetPath: 'assets/room/corner_right_shelf_lights_v1.png',
    ),
    const ShopItem(
      id: 'tiny_library_shelf',
      name: 'Mini Kitaplık',
      description: 'Çalışma alanının arkasına küçük kitap rafları ekler.',
      price: 190,
      slot: 'room_shelf',
      rarity: 'rare',
      accent: CatudyColors.tealDark,
      icon: Icons.menu_book_rounded,
      assetPath: 'assets/room/corner_bookcase_v1.png',
    ),
  ];

  String selectedCategoryId = 'study';
  int selectedDurationMinutes = 25;
  int gold = 0;
  int focusPoints = 0;
  int streakDays = 0;
  int petMood = 80;
  int petHunger = 20;
  int petEnergy = 75;
  String displayName = 'Guest Cat';
  bool authBusy = false;
  String? authUserId;
  String? authEmail;
  String? authProvider;
  String? authError;
  String apiBaseUrl = 'http://127.0.0.1:5099';
  String profileShareBaseUrl = '';
  bool offlineMode = true;
  bool dndReminder = true;
  bool notifications = true;
  bool dailyGoalReminderEnabled = true;
  bool publicStatsVisible = true;
  bool introTourSeen = false;
  String languageCode = 'tr';
  String themeModeCode = 'system';
  int dailyGoalMinutes = 90;
  int dailyGoalReminderHour = 18;
  int dailyGoalReminderMinute = 0;
  String? selectedTodoId;
  String? visitedProfileUserId;
  String? visitedRoomUserId;
  bool currentUserReady = false;
  bool lobbyStarted = false;
  bool lobbyBusy = false;
  bool onlineLobbyOwner = false;
  String? onlineLobbyId;
  String? onlineLobbyUserId;
  String? onlineLobbyCode;
  String? lobbyError;
  bool? localBreakVote;
  ActiveFocusSession? activeSession;
  FocusRecord? lastResult;
  DateTime selectedCalendarDate = DateTime.now();
  String selectedPetId = 'mochi';
  String petName = 'Mochi';
  bool petNameChosen = false;
  String profileAvatarId = 'catudy';
  String? customProfileImageBase64;
  String? equippedPetItemId = 'violet_collar';
  String? equippedProfileItemId;
  DateTime stateUpdatedAt = DateTime.now();

  bool get isLoaded => _loaded;

  FocusCategory get selectedCategory => _categoryById(selectedCategoryId);

  int get todayMinutes {
    final now = DateTime.now();
    return history
        .where(
          (item) =>
              item.createdAt.year == now.year &&
              item.createdAt.month == now.month &&
              item.createdAt.day == now.day,
        )
        .fold(0, (total, item) => total + item.minutes);
  }

  int get weeklyMinutes => minutesInRange(
    DateTime.now().subtract(const Duration(days: 6)),
    DateTime.now(),
  );

  DailyGoalProgress get todayGoalProgress => DailyGoalProgress(
    goalMinutes: dailyGoalMinutes,
    completedMinutes: todayMinutes,
  );

  int get totalFocusMinutes =>
      history.fold(0, (total, item) => total + item.minutes);

  int get sessionsCount => history.where((item) => !item.manual).length;

  double get moodDecayMultiplier =>
      (1 - (ownedItems.length * 0.08)).clamp(0.45, 1.0);

  Iterable<ShopItem> get roomFurnitureItems =>
      shopItems.where((item) => item.isRoomFurniture);

  Iterable<ShopItem> get equippedRoomItems sync* {
    for (final id in equippedRoomItemIds.values) {
      final item = shopItemById(id);
      if (item != null && item.isRoomFurniture && ownedItems.contains(id)) {
        yield item;
      }
    }
  }

  int get focusRewardBoostBasisPoints {
    final total = equippedRoomItems.fold<int>(
      0,
      (sum, item) => sum + item.rewardBoostBasisPoints,
    );
    return total.clamp(0, 800).toInt();
  }

  double get focusRewardBoostPercent => focusRewardBoostBasisPoints / 100;

  bool get onlineLobbyAvailable => _lobbyService != null;

  bool get onlineAuthAvailable => _authService != null;

  bool get isAuthenticated => authUserId != null;

  String get publicUserId => _currentLeaderboardUserId;

  String get publicUserCode => displayUserId(_currentLeaderboardUserId);

  String displayUserId(String userId) => _formatDisplayUserId(userId);

  bool get needsAuth => onlineAuthAvailable && !isAuthenticated;

  bool get hasOnlineLobby => onlineLobbyId != null;

  String? get lobbyJoinCode => onlineLobbyCode;

  int get connectedLobbyMemberCount =>
      lobbyMembers.where((member) => member.connected).length;

  String? get lobbyStartBlockReason {
    if (!hasOnlineLobby) {
      return null;
    }
    if (!onlineLobbyOwner) {
      return t('lobby.onlyOwnerCanStart');
    }
    final connected = lobbyMembers.where((member) => member.connected).toList();
    if (connected.length < 2) {
      return t('lobby.waitForSecondMember');
    }
    if (connected.any((member) => !member.ready)) {
      return t('lobby.waitForReady');
    }
    return null;
  }

  bool get canStartLobby {
    if (!hasOnlineLobby) {
      return false;
    }
    final connected = lobbyMembers.where((member) => member.connected).toList();
    return onlineLobbyOwner &&
        connected.length >= 2 &&
        connected.every((member) => member.ready);
  }

  int get breakVoteApproveCount =>
      lobbyMembers.where((member) => member.breakVote == true).length;

  int get breakVoteRejectCount =>
      lobbyMembers.where((member) => member.breakVote == false).length;

  int get breakVoteTotalCount => breakVoteApproveCount + breakVoteRejectCount;

  bool? get currentUserBreakVote {
    final userId = onlineLobbyUserId ?? 'local';
    for (final member in lobbyMembers) {
      if (member.userId == userId) {
        return member.breakVote;
      }
    }
    return null;
  }

  UnlockablePet get selectedPet => unlockablePets.firstWhere(
    (item) => item.id == selectedPetId,
    orElse: () => unlockablePets.first,
  );

  String get petDisplayName {
    final clean = petName.trim();
    return clean.isEmpty ? selectedPet.name : clean;
  }

  List<String> get petNameSuggestions {
    final base = selectedPet.name;
    final localized = languageCode == 'en'
        ? const ['Nova', 'Mochi', 'Pip']
        : const ['Mochi', 'Pamuk', 'Pati'];
    return [
      base,
      ...localized.where((name) => name.toLowerCase() != base.toLowerCase()),
    ].take(3).toList();
  }

  FocusRecommendation get focusRecommendation {
    final records = history
        .where((item) => !item.manual && item.minutes > 0)
        .toList();
    if (records.isEmpty) {
      return FocusRecommendation(
        categoryId: selectedCategoryId,
        minutes: selectedDurationMinutes.clamp(15, 60).toInt(),
        basedOnHistory: false,
        sessionsConsidered: 0,
      );
    }

    final now = DateTime.now();
    final categoryScores = <String, double>{};
    for (final record in records) {
      final ageDays = now.difference(record.createdAt).inDays.clamp(0, 60);
      final recency = (60 - ageDays) / 60;
      categoryScores[record.categoryId] =
          (categoryScores[record.categoryId] ?? 0) +
          record.minutes +
          10 +
          (recency * 18);
    }
    final categoryId = categoryScores.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
    final categoryRecords = records
        .where((item) => item.categoryId == categoryId)
        .toList();
    var weightedMinutes = 0.0;
    var weightTotal = 0.0;
    for (final record in categoryRecords) {
      final ageDays = now.difference(record.createdAt).inDays.clamp(0, 60);
      final recency = (60 - ageDays) / 60;
      final weight = 1 + recency + (record.minutes >= 25 ? 0.25 : 0);
      weightedMinutes += record.minutes * weight;
      weightTotal += weight;
    }
    final rawMinutes = weightTotal == 0
        ? selectedDurationMinutes.toDouble()
        : weightedMinutes / weightTotal;
    final rounded = ((rawMinutes / 5).round() * 5).clamp(10, 120).toInt();
    return FocusRecommendation(
      categoryId: categoryId,
      minutes: rounded,
      basedOnHistory: true,
      sessionsConsidered: categoryRecords.length,
    );
  }

  CalendarTodo? get selectedFocusTodo {
    final id = selectedTodoId;
    if (id == null) {
      return null;
    }
    for (final todo in todos) {
      if (todo.id == id && !todo.done) {
        return todo;
      }
    }
    return null;
  }

  List<CalendarTodo> get openFocusTasks {
    final now = DateTime.now();
    final horizon = now.add(const Duration(days: 7));
    final items = todos
        .where(
          (item) =>
              !item.done &&
              !item.scheduledAt.isBefore(
                DateTime(now.year, now.month, now.day),
              ) &&
              !item.scheduledAt.isAfter(horizon),
        )
        .toList();
    items.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return items;
  }

  List<CatudyAchievement> get achievements {
    final nonManual = history.where((item) => !item.manual).toList();
    final categoryCounts = <String, int>{};
    for (final record in nonManual) {
      categoryCounts[record.categoryId] =
          (categoryCounts[record.categoryId] ?? 0) + 1;
    }
    final maxCategorySessions = categoryCounts.values.fold(
      0,
      (max, value) => value > max ? value : max,
    );
    final completedTasks = todos.where((item) => item.done).length;
    return [
      CatudyAchievement(
        id: 'first_focus',
        title: languageCode == 'en' ? 'First focus' : 'İlk odak',
        description: languageCode == 'en'
            ? 'Complete your first real focus session.'
            : 'İlk gerçek odak seansını tamamla.',
        icon: Icons.flag_rounded,
        progress: nonManual.length,
        target: 1,
      ),
      CatudyAchievement(
        id: 'daily_goal',
        title: languageCode == 'en' ? 'Daily target' : 'Günlük hedef',
        description: languageCode == 'en'
            ? 'Reach your daily focus target once.'
            : 'Günlük odak hedefini bir kez tamamla.',
        icon: Icons.track_changes_rounded,
        progress: todayGoalProgress.completed ? 1 : 0,
        target: 1,
      ),
      CatudyAchievement(
        id: 'five_category_sessions',
        title: languageCode == 'en' ? 'Category rhythm' : 'Kategori ritmi',
        description: languageCode == 'en'
            ? 'Complete 5 sessions in any one category.'
            : 'Herhangi bir kategoride 5 seans tamamla.',
        icon: Icons.category_rounded,
        progress: maxCategorySessions,
        target: 5,
      ),
      CatudyAchievement(
        id: 'seven_day_streak',
        title: languageCode == 'en' ? '7-day streak' : '7 gün seri',
        description: languageCode == 'en'
            ? 'Keep your focus streak for 7 days.'
            : 'Odak serini 7 güne taşıyan rozeti aç.',
        icon: Icons.local_fire_department_rounded,
        progress: streakDays,
        target: 7,
      ),
      CatudyAchievement(
        id: 'ten_hours',
        title: languageCode == 'en' ? '10 focus hours' : '10 saat odak',
        description: languageCode == 'en'
            ? 'Record 600 total focus minutes.'
            : 'Toplam 600 odak dakikasi kaydet.',
        icon: Icons.timer_rounded,
        progress: totalFocusMinutes,
        target: 600,
      ),
      CatudyAchievement(
        id: 'task_finisher',
        title: languageCode == 'en' ? 'Task finisher' : 'Görev bitirici',
        description: languageCode == 'en'
            ? 'Complete 5 planned tasks.'
            : '5 planlı görevi tamamla.',
        icon: Icons.task_alt_rounded,
        progress: completedTasks,
        target: 5,
      ),
    ];
  }

  List<CatudyAchievement> get unlockedAchievements =>
      achievements.where((item) => item.unlocked).toList();

  CatudyCelebration? takePendingCelebration() {
    if (_pendingCelebrations.isEmpty) {
      return null;
    }
    return _pendingCelebrations.removeAt(0);
  }

  int get bestStreakDays {
    final focusDays =
        history
            .where((item) => !item.manual && item.minutes > 0)
            .map(
              (item) => DateTime(
                item.createdAt.year,
                item.createdAt.month,
                item.createdAt.day,
              ),
            )
            .toSet()
            .toList()
          ..sort();
    if (focusDays.isEmpty) {
      return 0;
    }
    var best = 1;
    var current = 1;
    for (var i = 1; i < focusDays.length; i++) {
      final diff = focusDays[i].difference(focusDays[i - 1]).inDays;
      if (diff == 1) {
        current += 1;
      } else if (diff > 1) {
        current = 1;
      }
      if (current > best) {
        best = current;
      }
    }
    return best > streakDays ? best : streakDays;
  }

  List<int> get lastSevenDayMinutes {
    final now = DateTime.now();
    return [
      for (var i = 6; i >= 0; i--)
        minutesForDay(now.subtract(Duration(days: i))),
    ];
  }

  SocialChallenge get weeklySocialChallenge => SocialChallenge(
    id: 'weekly_300',
    title: languageCode == 'en' ? 'Weekly focus crew' : 'Haftalık odak ekibi',
    description: languageCode == 'en'
        ? 'Reach 300 minutes this week and compare progress with the board.'
        : 'Bu hafta 300 dakikaya ulaş ve ilerlemeyi sıralama ile karşılaştır.',
    targetMinutes: 300,
    currentMinutes: weeklyMinutes,
    participants: socialProfiles.length.clamp(1, 99).toInt(),
  );

  List<LeaderboardProfile> get friendProfiles {
    final friends = socialProfiles
        .where(
          (profile) =>
              friendUserIds.contains(profile.userId) &&
              !blockedUserIds.contains(profile.userId),
        )
        .toList();
    friends.sort((a, b) => b.points.compareTo(a.points));
    return friends;
  }

  List<FriendRequest> get incomingFriendRequests {
    final currentId = _currentLeaderboardUserId;
    final requests = friendRequests
        .where((request) => request.toUserId == currentId)
        .toList();
    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return requests;
  }

  List<FriendRequest> get outgoingFriendRequests {
    final currentId = _currentLeaderboardUserId;
    final requests = friendRequests
        .where((request) => request.fromUserId == currentId)
        .toList();
    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return requests;
  }

  List<LeaderboardProfile> get socialProfiles {
    final profiles = [...leaderboardProfiles];
    for (final profile in _fetchedProfiles.values) {
      if (!profiles.any((item) => item.userId == profile.userId)) {
        profiles.add(profile);
      }
    }
    if (kDebugMode && profiles.length <= 1) {
      profiles.addAll(_demoSocialProfiles());
    }
    final visible = profiles
        .where((profile) => !blockedUserIds.contains(profile.userId))
        .toList();
    visible.sort((a, b) => b.points.compareTo(a.points));
    return visible;
  }

  LeaderboardProfile? get visitedProfile {
    final userId = visitedProfileUserId;
    if (userId == null) {
      return null;
    }
    for (final profile in socialProfiles) {
      if (profile.userId == userId) {
        return profile;
      }
    }
    return _fetchedProfiles[userId];
  }

  LeaderboardProfile? get visitedRoomProfile {
    final userId = visitedRoomUserId;
    if (userId == null) {
      return null;
    }
    for (final profile in socialProfiles) {
      if (profile.userId == userId) {
        return profile;
      }
    }
    return null;
  }

  List<LeaderboardProfile> get leaderboardProfiles {
    final currentId = _currentLeaderboardUserId;
    final online = _onlineLeaderboardProfiles;
    final profiles = online == null || online.isEmpty
        ? <LeaderboardProfile>[_localLeaderboardProfile(currentId)]
        : <LeaderboardProfile>[
            for (final profile in online)
              LeaderboardProfile(
                userId: profile.userId,
                name: profile.name,
                petId: profile.petId,
                petName: profile.petName,
                equippedPetItemId: profile.equippedPetItemId,
                roomItemIds: profile.roomItemIds,
                points: profile.points,
                totalMinutes: profile.totalMinutes,
                streakDays: profile.streakDays,
                sessionsCount: profile.sessionsCount,
                favoriteCategory: profile.favoriteCategory,
                statsPublic: profile.statsPublic,
                currentUser: profile.userId == currentId,
              ),
          ];
    if (!profiles.any((profile) => profile.userId == currentId)) {
      profiles.add(_localLeaderboardProfile(currentId));
    }
    profiles.sort((a, b) => b.points.compareTo(a.points));
    return profiles;
  }

  String get _currentLeaderboardUserId => authUserId ?? 'local';

  LeaderboardProfile _profileFromOnline(
    CatudyOnlineLeaderboardProfile profile,
    String currentId,
  ) {
    return LeaderboardProfile(
      userId: profile.userId,
      name: profile.displayName,
      petId: profile.petId,
      petName: profile.petName,
      equippedPetItemId: profile.equippedPetItemId,
      roomItemIds: profile.roomItemIds,
      points: profile.points,
      totalMinutes: profile.totalMinutes,
      streakDays: profile.streakDays,
      sessionsCount: profile.sessionsCount,
      favoriteCategory: profile.favoriteCategory,
      statsPublic: profile.statsPublic,
      currentUser: profile.userId == currentId,
    );
  }

  LeaderboardProfile _localLeaderboardProfile(String userId) {
    return LeaderboardProfile(
      userId: userId,
      name: displayName,
      petId: selectedPetId,
      petName: petDisplayName,
      equippedPetItemId: equippedPetItemId,
      roomItemIds: Map<String, String>.from(equippedRoomItemIds),
      points: focusPoints,
      totalMinutes: totalFocusMinutes,
      streakDays: streakDays,
      sessionsCount: sessionsCount,
      favoriteCategory: favoriteCategory.name,
      statsPublic: publicStatsVisible,
      currentUser: true,
    );
  }

  List<LeaderboardProfile> _demoSocialProfiles() {
    return [
      LeaderboardProfile(
        userId: 'demo-ada',
        name: languageCode == 'en' ? 'Ada' : 'Ada',
        petId: 'miso',
        petName: 'Miso',
        equippedPetItemId: 'sunny_hat',
        roomItemIds: const {
          'room_study': 'soft_study_nook',
          'room_bed': 'cloud_nap_bed',
          'room_decor': 'glow_lantern',
        },
        points: 1280,
        totalMinutes: 840,
        streakDays: 6,
        sessionsCount: 21,
        favoriteCategory: languageCode == 'en' ? 'Reading' : 'Okuma',
        statsPublic: true,
        currentUser: false,
      ),
      LeaderboardProfile(
        userId: 'demo-deniz',
        name: languageCode == 'en' ? 'Deniz' : 'Deniz',
        petId: 'luna',
        petName: 'Luna',
        equippedPetItemId: null,
        roomItemIds: const {
          'room_study': 'moonlit_study_nook',
          'room_bed': 'warm_den_bed',
          'room_shelf': 'tiny_library_shelf',
        },
        points: 940,
        totalMinutes: 610,
        streakDays: 4,
        sessionsCount: 15,
        favoriteCategory: languageCode == 'en' ? 'Study' : 'Ders',
        statsPublic: true,
        currentUser: false,
      ),
    ];
  }

  LeaderboardProfile? profileByUserId(String userId) {
    if (blockedUserIds.contains(userId)) {
      return null;
    }
    for (final profile in socialProfiles) {
      if (profile.userId == userId) {
        return profile;
      }
    }
    return null;
  }

  void ensurePublicProfile(String userId) {
    final clean = userId.trim();
    if (clean.isEmpty ||
        blockedUserIds.contains(clean) ||
        profileByUserId(clean) != null ||
        _profileFetches.contains(clean)) {
      return;
    }
    final service = _leaderboardService;
    if (service == null) {
      return;
    }
    _profileFetches.add(clean);
    unawaited(
      service
          .fetchProfile(clean)
          .then((profile) {
            if (profile == null) {
              return;
            }
            _fetchedProfiles[clean] = _profileFromOnline(
              profile,
              _currentLeaderboardUserId,
            );
            notifyListeners();
          })
          .whenComplete(() => _profileFetches.remove(clean))
          .catchError((Object _) {}),
    );
  }

  FocusCategory get favoriteCategory {
    if (history.isEmpty) {
      return selectedCategory;
    }
    final totals = <String, int>{};
    for (final record in history) {
      totals[record.categoryId] =
          (totals[record.categoryId] ?? 0) + record.minutes;
    }
    final best = totals.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return _categoryById(best.key);
  }

  List<LobbyMember> get lobbyMembers {
    final online = _onlineLobbyMembers;
    if (online != null) {
      return online;
    }
    if (!hasOnlineLobby && !lobbyStarted) {
      return const [];
    }
    return [
      LobbyMember(
        userId: onlineLobbyUserId ?? 'local',
        name: displayName,
        ready: currentUserReady,
        owner: true,
        connected: true,
        breakVote: localBreakVote,
      ),
    ];
  }

  List<CalendarTodo> todosForDay(DateTime day) {
    final items = todos
        .where(
          (item) =>
              item.date.year == day.year &&
              item.date.month == day.month &&
              item.date.day == day.day,
        )
        .toList();
    items.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return items;
  }

  List<UnlockablePet> consumeUnlockedPets() {
    final unlocked = _pendingUnlockedPetIds
        .map((id) => unlockablePets.firstWhere((item) => item.id == id))
        .toList();
    _pendingUnlockedPetIds.clear();
    return unlocked;
  }

  Future<void> load() {
    return _loadFuture ??= _loadFromStorage();
  }

  void configureNotificationSync(Future<void> Function() sync) {
    _notificationSync = sync;
    _syncNotifications();
  }

  void attachAuthService(CatudyAuthService service) {
    _authService = service;
    final session = service.currentSession;
    if (_shouldDiscardAnonymousSession(session)) {
      unawaited(service.signOut().catchError((Object _) {}));
      _applyAuthSession(null);
    } else {
      _applyAuthSession(session);
    }
    _watchSocialState();
    unawaited(_authSubscription?.cancel());
    _authSubscription = service.authStateChanges.listen((session) {
      if (_shouldDiscardAnonymousSession(session)) {
        unawaited(service.signOut().catchError((Object _) {}));
        _applyAuthSession(null);
      } else {
        _applyAuthSession(session);
      }
      _commit(touchState: false);
      _watchSocialState();
      _mergeBackupForCurrentUser();
    }, onError: _setAuthError);
    notifyListeners();
    unawaited(_save());
    _mergeBackupForCurrentUser();
  }

  bool _shouldDiscardAnonymousSession(CatudyAuthSession? session) {
    return session?.anonymous == true &&
        !_explicitGuestSignInPending &&
        _explicitGuestUserId != session?.userId;
  }

  void attachLobbyService(CatudySupabaseLobbyService service) {
    _lobbyService = service;
    offlineMode = false;
    notifyListeners();
    unawaited(_save());
  }

  void attachBackupService(CatudyBackupService service) {
    _backupService = service;
    _mergeBackupForCurrentUser();
  }

  void attachLeaderboardService(CatudyLeaderboardService service) {
    _leaderboardService = service;
    unawaited(_leaderboardSubscription?.cancel());
    unawaited(_refreshOnlineLeaderboard());
    _leaderboardSubscription = service.watchTopProfiles().listen(
      (profiles) {
        _applyOnlineLeaderboardProfiles(profiles);
      },
      onError: (_) {
        unawaited(_refreshOnlineLeaderboard());
      },
    );
    _scheduleLeaderboardSync(immediate: true);
  }

  void _applyOnlineLeaderboardProfiles(
    List<CatudyOnlineLeaderboardProfile> profiles,
  ) {
    final currentId = _currentLeaderboardUserId;
    _onlineLeaderboardProfiles = profiles
        .map((profile) => _profileFromOnline(profile, currentId))
        .toList();
    notifyListeners();
  }

  Future<void> _refreshOnlineLeaderboard() async {
    final service = _leaderboardService;
    if (service == null) {
      return;
    }
    try {
      final profiles = await service.fetchTopProfiles();
      if (_leaderboardService == service) {
        _applyOnlineLeaderboardProfiles(profiles);
      }
    } catch (_) {
      // Keep the last known list visible when realtime/fetch briefly fails.
    }
  }

  void attachSocialService(CatudySocialService service) {
    _socialService = service;
    _watchSocialState();
  }

  void configureSocialNotifications({
    void Function(String name, String languageCode)? onFriendRequest,
  }) {
    _friendRequestNotifier = onFriendRequest;
  }

  void _watchSocialState() {
    final service = _socialService;
    if (service == null || authUserId == null) {
      return;
    }
    unawaited(_friendRequestsSubscription?.cancel());
    unawaited(_friendsSubscription?.cancel());
    unawaited(_blockedUsersSubscription?.cancel());
    _friendRequestsSubscription = service.watchPendingRequests().listen((
      requests,
    ) {
      _notifyNewIncomingFriendRequests(requests);
      friendRequests
        ..clear()
        ..addAll(
          requests.map(
            (request) => FriendRequest(
              id: request.id,
              fromUserId: request.fromUserId,
              toUserId: request.toUserId,
              createdAt: request.createdAt,
            ),
          ),
        );
      notifyListeners();
    }, onError: (_) {});
    _friendsSubscription = service.watchFriendIds().listen((ids) {
      friendUserIds
        ..clear()
        ..addAll(ids);
      notifyListeners();
    }, onError: (_) {});
    _blockedUsersSubscription = service.watchBlockedIds().listen((ids) {
      blockedUserIds
        ..clear()
        ..addAll(ids);
      friendUserIds.removeWhere(blockedUserIds.contains);
      notifyListeners();
    }, onError: (_) {});
  }

  void _notifyNewIncomingFriendRequests(
    List<CatudyOnlineFriendRequest> requests,
  ) {
    final currentId = _currentLeaderboardUserId;
    final incoming = requests
        .where((request) => request.toUserId == currentId)
        .toList();
    final nextIds = incoming.map((request) => request.id).toSet();
    final notifier = _friendRequestNotifier;
    if (notifications && notifier != null) {
      for (final request in incoming) {
        if (!_knownIncomingFriendRequestIds.contains(request.id)) {
          final profile = profileByUserId(request.fromUserId);
          notifier(profile?.name ?? request.fromUserId, languageCode);
        }
      }
    }
    _knownIncomingFriendRequestIds
      ..clear()
      ..addAll(nextIds);
  }

  String? consumeInitialRestoreRoute() {
    if (activeSession != null) {
      return '/focus/timer';
    }
    if (_restoredCompletedSession) {
      _restoredCompletedSession = false;
      return '/focus/result';
    }
    return null;
  }

  bool get hasPendingFocusResult => _restoredCompletedSession;

  String? consumeFocusNavigationRoute() {
    refreshActiveFocusState();
    if (activeSession != null) {
      return '/focus/timer';
    }
    if (_restoredCompletedSession) {
      _restoredCompletedSession = false;
      _commit(touchState: false);
      return '/focus/result';
    }
    return null;
  }

  void refreshActiveFocusState() {
    _completeExpiredRestoredSession(DateTime.now(), persist: true);
  }

  int remainingSeconds(DateTime now) {
    final session = activeSession;
    if (session == null) {
      return 0;
    }
    final planned = session.durationMinutes * 60;
    final elapsed = now.difference(session.startedAt).inSeconds;
    return (planned - elapsed).clamp(0, planned);
  }

  int minutesForDay(DateTime day) {
    return recordsForDay(day).fold(0, (sum, item) => sum + item.minutes);
  }

  List<FocusRecord> recordsForDay(DateTime day) {
    return history
        .where(
          (item) =>
              item.createdAt.year == day.year &&
              item.createdAt.month == day.month &&
              item.createdAt.day == day.day,
        )
        .toList();
  }

  int minutesInRange(DateTime start, DateTime end) {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return history
        .where(
          (item) =>
              !item.createdAt.isBefore(startDay) &&
              !item.createdAt.isAfter(endDay),
        )
        .fold(0, (sum, item) => sum + item.minutes);
  }

  void selectCalendarDate(DateTime date) {
    selectedCalendarDate = DateTime(date.year, date.month, date.day);
    _commit();
  }

  CalendarTodo? addTodoReminder({
    required DateTime date,
    required TimeOfDay time,
    required String title,
  }) {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      return null;
    }
    final todo = CalendarTodo(
      id: _newEntityId('todo'),
      title: cleanTitle,
      date: DateTime(date.year, date.month, date.day),
      hour: time.hour,
      minute: time.minute,
      done: false,
      updatedAt: DateTime.now(),
    );
    todos.add(todo);
    _commit();
    return todo;
  }

  void toggleTodo(String id) {
    final index = todos.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }
    todos[index] = todos[index].copyWith(done: !todos[index].done);
    if (todos[index].done && selectedTodoId == id) {
      selectedTodoId = null;
    }
    _commit();
  }

  void selectTodoForFocus(String? id) {
    if (id == null) {
      selectedTodoId = null;
      _commit();
      return;
    }
    selectedTodoId = todos.any((item) => item.id == id && !item.done)
        ? id
        : null;
    _commit();
  }

  void toggleFriend(String userId) {
    if (userId == _currentLeaderboardUserId) {
      return;
    }
    if (friendUserIds.contains(userId)) {
      removeFriend(userId);
    } else {
      friendUserIds.add(userId);
      _commit();
    }
  }

  void removeFriend(String userId) {
    friendUserIds.remove(userId);
    final service = _socialService;
    if (service != null && authUserId != null) {
      unawaited(service.removeFriend(userId).catchError((Object _) {}));
    }
    _commit();
  }

  void unblockUser(String userId) {
    if (!blockedUserIds.remove(userId)) {
      return;
    }
    final service = _socialService;
    if (service != null && authUserId != null) {
      unawaited(service.unblockUser(userId).catchError((Object _) {}));
    }
    _commit();
  }

  String blockedUserLabel(String userId) {
    final fetched = _fetchedProfiles[userId];
    if (fetched != null) {
      return fetched.name;
    }
    for (final profile in leaderboardProfiles) {
      if (profile.userId == userId) {
        return profile.name;
      }
    }
    for (final profile in _demoSocialProfiles()) {
      if (profile.userId == userId) {
        return profile.name;
      }
    }
    return displayUserId(userId);
  }

  void sendDemoIncomingFriendRequest(String fromUserId) {
    final currentId = _currentLeaderboardUserId;
    if (fromUserId == currentId ||
        friendUserIds.contains(fromUserId) ||
        friendRequests.any(
          (request) =>
              request.fromUserId == fromUserId && request.toUserId == currentId,
        )) {
      return;
    }
    friendRequests.add(
      FriendRequest(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        fromUserId: fromUserId,
        toUserId: currentId,
        createdAt: DateTime.now(),
      ),
    );
    _commit();
  }

  FriendRequestActionResult sendFriendRequestByQuery(String query) {
    final clean = query.trim();
    if (clean.isEmpty) {
      return FriendRequestActionResult.empty;
    }
    final userId = _resolveUserIdQuery(clean);
    if (userId == null) {
      return FriendRequestActionResult.notFound;
    }
    return sendFriendRequest(userId);
  }

  String? _resolveUserIdQuery(String query) {
    final clean = query.trim();
    final normalized = clean.toUpperCase();
    final profiles = <LeaderboardProfile>[
      ...socialProfiles,
      ..._fetchedProfiles.values,
      ..._demoSocialProfiles(),
    ];
    for (final profile in profiles) {
      if (profile.userId == clean ||
          displayUserId(profile.userId).toUpperCase() == normalized) {
        return profile.userId;
      }
    }
    if (_looksLikeUuid(clean) || clean.startsWith('demo-')) {
      return clean;
    }
    return null;
  }

  FriendRequestActionResult sendFriendRequest(String userId) {
    final currentId = _currentLeaderboardUserId;
    final match = profileByUserId(userId);
    if (blockedUserIds.contains(userId)) {
      return FriendRequestActionResult.blocked;
    }
    if (userId == currentId || match?.currentUser == true) {
      return FriendRequestActionResult.self;
    }
    if (friendUserIds.contains(userId)) {
      return FriendRequestActionResult.alreadyFriend;
    }
    if (friendRequests.any(
      (request) =>
          (request.fromUserId == currentId && request.toUserId == userId) ||
          (request.fromUserId == userId && request.toUserId == currentId),
    )) {
      return FriendRequestActionResult.alreadyPending;
    }
    friendRequests.add(
      FriendRequest(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        fromUserId: currentId,
        toUserId: userId,
        createdAt: DateTime.now(),
      ),
    );
    final service = _socialService;
    if (service != null && authUserId != null) {
      unawaited(service.sendFriendRequest(userId).catchError((Object _) {}));
    }
    _commit();
    return FriendRequestActionResult.sent;
  }

  void acceptFriendRequest(String requestId) {
    final index = friendRequests.indexWhere(
      (request) => request.id == requestId,
    );
    if (index == -1) {
      return;
    }
    final request = friendRequests.removeAt(index);
    final currentId = _currentLeaderboardUserId;
    if (request.toUserId == currentId) {
      friendUserIds.add(request.fromUserId);
      final service = _socialService;
      if (service != null && authUserId != null) {
        unawaited(
          service.acceptFriendRequest(requestId).catchError((Object _) {}),
        );
      }
    }
    _commit();
  }

  void rejectFriendRequest(String requestId) {
    friendRequests.removeWhere((request) => request.id == requestId);
    final service = _socialService;
    if (service != null && authUserId != null) {
      unawaited(
        service.rejectFriendRequest(requestId).catchError((Object _) {}),
      );
    }
    _commit();
  }

  void cancelFriendRequest(String requestId) {
    friendRequests.removeWhere((request) => request.id == requestId);
    final service = _socialService;
    if (service != null && authUserId != null) {
      unawaited(
        service.cancelFriendRequest(requestId).catchError((Object _) {}),
      );
    }
    _commit();
  }

  void blockUser(String userId) {
    if (userId == _currentLeaderboardUserId) {
      return;
    }
    blockedUserIds.add(userId);
    friendUserIds.remove(userId);
    friendRequests.removeWhere(
      (request) => request.fromUserId == userId || request.toUserId == userId,
    );
    if (visitedProfileUserId == userId) {
      visitedProfileUserId = null;
    }
    if (visitedRoomUserId == userId) {
      visitedRoomUserId = null;
    }
    final service = _socialService;
    if (service != null && authUserId != null) {
      unawaited(service.blockUser(userId).catchError((Object _) {}));
    }
    _commit();
  }

  void reportUser(String userId) {
    if (userId == _currentLeaderboardUserId) {
      return;
    }
    reportedUserIds.add(userId);
    final service = _socialService;
    if (service != null && authUserId != null) {
      unawaited(service.reportUser(userId).catchError((Object _) {}));
    }
    _commit();
  }

  FriendAddResult addFriendByQuery(String query) {
    final clean = query.trim();
    if (clean.isEmpty) {
      return FriendAddResult.empty;
    }

    LeaderboardProfile? match;
    for (final profile in socialProfiles) {
      if (profile.userId == clean) {
        match = profile;
        break;
      }
    }

    if (match == null) {
      return FriendAddResult.notFound;
    }
    if (match.userId == _currentLeaderboardUserId || match.currentUser) {
      return FriendAddResult.self;
    }
    if (friendUserIds.contains(match.userId)) {
      return FriendAddResult.alreadyFriend;
    }
    friendUserIds.add(match.userId);
    _commit();
    return FriendAddResult.added;
  }

  void visitProfile(String userId) {
    visitedProfileUserId = userId;
    ensurePublicProfile(userId);
    _commit();
  }

  void visitPetRoom(String userId) {
    visitedRoomUserId = userId;
    ensurePublicProfile(userId);
    _commit();
  }

  void clearVisitedRoom() {
    if (visitedRoomUserId == null) {
      return;
    }
    visitedRoomUserId = null;
    _commit();
  }

  void clearVisitedProfile() {
    if (visitedProfileUserId == null) {
      return;
    }
    visitedProfileUserId = null;
    _commit();
  }

  void selectCategory(String id) {
    selectedCategoryId = categories.any((item) => item.id == id)
        ? id
        : categories.first.id;
    _commit();
  }

  void addCategory(String name, Color color) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      return;
    }
    final id = cleanName.toLowerCase().replaceAll(' ', '_');
    if (categories.any((item) => item.id == id || item.name == cleanName)) {
      selectedCategoryId = categories
          .firstWhere((item) => item.id == id || item.name == cleanName)
          .id;
      _commit();
      return;
    }
    categories.add(
      FocusCategory(
        id: id,
        name: cleanName,
        color: color,
        updatedAt: DateTime.now(),
      ),
    );
    selectedCategoryId = id;
    _commit();
  }

  void selectDuration(int minutes) {
    selectedDurationMinutes = minutes;
    _commit();
  }

  void updateDailyGoal(int minutes) {
    dailyGoalMinutes = minutes.clamp(15, 720).toInt();
    _commit();
  }

  void updateDailyGoalReminder({
    required bool enabled,
    required TimeOfDay time,
  }) {
    dailyGoalReminderEnabled = enabled;
    dailyGoalReminderHour = time.hour;
    dailyGoalReminderMinute = time.minute;
    _commit();
    _syncNotifications();
  }

  void prepareRecommendedFocus() {
    final recommendation = focusRecommendation;
    selectCategory(recommendation.categoryId);
    selectedDurationMinutes = recommendation.minutes;
    _commit();
  }

  void startFocus({bool lobbyMode = false}) {
    final focusTodo = selectedFocusTodo;
    activeSession = ActiveFocusSession(
      categoryId: selectedCategoryId,
      durationMinutes: selectedDurationMinutes,
      startedAt: DateTime.now(),
      lobbyMode: lobbyMode,
      todoId: focusTodo?.id,
    );
    lastResult = null;
    selectedTodoId = focusTodo?.id;
    localBreakVote = null;
    _restoredCompletedSession = false;
    if (lobbyMode) {
      lobbyStarted = true;
    }
    _commit();
    _scheduleActiveFocusCompletion();
    _syncNotifications();
  }

  void cancelFocus() {
    activeSession = null;
    lobbyStarted = false;
    currentUserReady = false;
    localBreakVote = null;
    _restoredCompletedSession = false;
    _focusCompletionTimer?.cancel();
    _commit();
    _syncNotifications();
  }

  FocusRecord completeFocus() {
    if (activeSession == null && lastResult != null) {
      return lastResult!;
    }
    final record = _completeCurrentSession(completedAt: DateTime.now());
    _restoredCompletedSession = false;
    _focusCompletionTimer?.cancel();
    _commit();
    _syncNotifications();
    return record;
  }

  void addManualEntry({
    required String categoryId,
    required int minutes,
    required String note,
    DateTime? date,
  }) {
    final targetDate = date ?? selectedCalendarDate;
    final now = DateTime.now();
    history.insert(
      0,
      FocusRecord(
        id: _newEntityId('focus'),
        categoryId: categoryId,
        minutes: minutes,
        createdAt: DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          now.hour,
          now.minute,
        ),
        updatedAt: now,
        manual: true,
        note: note.trim().isEmpty ? 'Manuel kayıt' : note.trim(),
        gold: 0,
      ),
    );
    petMood = (petMood + 3).clamp(0, 100);
    petEnergy = (petEnergy + 1).clamp(0, 100);
    _commit();
  }

  bool buyItem(String id) {
    final item = shopItems.firstWhere((entry) => entry.id == id);
    if (ownedItems.contains(id) || gold < item.price) {
      return false;
    }
    gold -= item.price;
    ownedItems.add(id);
    if (item.isRoomFurniture) {
      equippedRoomItemIds[item.slot] = id;
    }
    petMood = (petMood + 6).clamp(0, 100);
    _commit();
    return true;
  }

  void selectPet(String id) {
    if (!unlockedPetIds.contains(id)) {
      return;
    }
    selectedPetId = id;
    _commit();
  }

  void equipItem(String id) {
    if (!ownedItems.contains(id)) {
      return;
    }
    final item = shopItems.firstWhere((entry) => entry.id == id);
    if (item.isRoomFurniture) {
      equippedRoomItemIds[item.slot] = id;
    } else if (item.slot == 'pet') {
      equippedPetItemId = id;
    } else {
      equippedProfileItemId = id;
    }
    _commit();
  }

  Future<void> signInAsGuest() async {
    final service = _authService;
    if (service == null) {
      authError = t('auth.offlineUnavailable');
      _commit(touchState: false);
      return;
    }
    _resetLocalProfileIdentity();
    await _runAuthAction(
      () => service.signInAsGuest(displayName),
      explicitGuest: true,
    );
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final service = _authService;
    if (service == null) {
      authError = t('auth.offlineUnavailable');
      _commit(touchState: false);
      return;
    }
    await _runAuthAction(
      () => service.signInWithEmail(email: email, password: password),
    );
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final service = _authService;
    if (service == null) {
      authError = t('auth.offlineUnavailable');
      _commit(touchState: false);
      return;
    }
    final cleanName = displayName.trim();
    if (cleanName.isEmpty) {
      authError = t('auth.displayNameRequired');
      _commit(touchState: false);
      return;
    }
    await _runAuthAction(() async {
      final session = await service.signUpWithEmail(
        email: email,
        password: password,
        displayName: cleanName,
      );
      return CatudyAuthSession(
        userId: session.userId,
        email: session.email,
        displayName: cleanName,
        provider: session.provider,
        anonymous: session.anonymous,
      );
    });
  }

  Future<void> signInWithGoogle() async {
    final service = _authService;
    if (service == null) {
      authError = t('auth.offlineUnavailable');
      _commit(touchState: false);
      return;
    }
    await _runAuthVoidAction(service.signInWithGoogle);
  }

  Future<void> signInWithApple() async {
    final service = _authService;
    if (service == null) {
      authError = t('auth.offlineUnavailable');
      _commit(touchState: false);
      return;
    }
    await _runAuthVoidAction(service.signInWithApple);
  }

  Future<void> signOut() async {
    final service = _authService;
    if (service == null) {
      return;
    }
    authBusy = true;
    authError = null;
    _commit(touchState: false);
    try {
      await service.signOut();
      _explicitGuestUserId = null;
      _applyAuthSession(null);
      _resetLocalProfileIdentity();
    } catch (error) {
      _setAuthError(error);
      return;
    }
    authBusy = false;
    _commit(touchState: false);
  }

  void toggleReady() {
    currentUserReady = !currentUserReady;
    _commit();
    final lobbyId = onlineLobbyId;
    final userId = onlineLobbyUserId;
    final service = _lobbyService;
    if (service != null && lobbyId != null && userId != null) {
      unawaited(
        service
            .setReady(lobbyId: lobbyId, userId: userId, ready: currentUserReady)
            .catchError((Object error) {
              _setLobbyError(error);
              return null;
            }),
      );
    }
  }

  void startLobbySession() {
    currentUserReady = true;
    final lobbyId = onlineLobbyId;
    final userId = onlineLobbyUserId;
    final service = _lobbyService;
    if (service != null && lobbyId != null && userId != null) {
      final blockedReason = lobbyStartBlockReason;
      if (blockedReason != null) {
        lobbyError = blockedReason;
        _commit();
        return;
      }
      lobbyBusy = true;
      lobbyError = null;
      _commit();
      unawaited(
        service
            .startLobby(
              lobbyId: lobbyId,
              ownerUserId: userId,
              categoryId: selectedCategoryId,
              durationMinutes: selectedDurationMinutes,
            )
            .then((_) {
              lobbyBusy = false;
              _commit();
            })
            .catchError((Object error) {
              _setLobbyError(error);
              return null;
            }),
      );
      return;
    }
    startFocus(lobbyMode: true);
  }

  Future<void> createOnlineLobby() async {
    final service = _lobbyService;
    if (service == null) {
      _startDemoLobby();
      return;
    }
    lobbyBusy = true;
    lobbyError = null;
    _onlineLobbyMembers = null;
    _commit();
    try {
      final result = await service.createLobby(
        displayName: displayName,
        categoryId: selectedCategoryId,
        durationMinutes: selectedDurationMinutes,
      );
      _activateOnlineLobby(result);
    } catch (error) {
      _setLobbyError(error);
    }
  }

  Future<void> joinOnlineLobby(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      lobbyError = t('lobby.enterCode');
      _commit();
      return;
    }
    final service = _lobbyService;
    if (service == null) {
      _startDemoLobby();
      return;
    }
    lobbyBusy = true;
    lobbyError = null;
    _onlineLobbyMembers = null;
    _commit();
    try {
      final result = await service.joinLobby(
        code: cleanCode,
        displayName: displayName,
      );
      _activateOnlineLobby(result);
    } catch (error) {
      _setLobbyError(error);
    }
  }

  void leaveOnlineLobby() {
    final service = _lobbyService;
    final lobbyId = onlineLobbyId;
    final userId = onlineLobbyUserId;
    unawaited(_onlineLobbySubscription?.cancel());
    unawaited(_onlineMembersSubscription?.cancel());
    _onlineLobbySubscription = null;
    _onlineMembersSubscription = null;
    if (service != null && lobbyId != null && userId != null) {
      unawaited(
        service
            .leaveLobby(lobbyId: lobbyId, userId: userId)
            .catchError(_setLobbyError),
      );
    }
    onlineLobbyId = null;
    onlineLobbyUserId = null;
    onlineLobbyCode = null;
    onlineLobbyOwner = false;
    _onlineLobbyMembers = null;
    currentUserReady = false;
    lobbyStarted = false;
    lobbyBusy = false;
    lobbyError = null;
    localBreakVote = null;
    _commit();
  }

  void _startDemoLobby() {
    onlineLobbyId = null;
    onlineLobbyUserId = null;
    onlineLobbyCode = null;
    onlineLobbyOwner = false;
    _onlineLobbyMembers = null;
    lobbyError = t('lobby.demoMode');
    currentUserReady = false;
    lobbyStarted = false;
    localBreakVote = null;
    _commit();
  }

  void _activateOnlineLobby(CatudyLobbyJoinResult result) {
    onlineLobbyId = result.lobby.id;
    onlineLobbyUserId = result.userId;
    onlineLobbyCode = result.lobby.code;
    onlineLobbyOwner = result.owner;
    currentUserReady = result.owner;
    selectedCategoryId = result.lobby.categoryId;
    selectedDurationMinutes = result.lobby.durationMinutes;
    offlineMode = false;
    lobbyBusy = false;
    lobbyError = null;
    localBreakVote = null;
    _applyOnlineLobby(result.lobby);
    _watchOnlineLobby(result.lobby.id);
    _commit();
  }

  void _watchOnlineLobby(String lobbyId) {
    final service = _lobbyService;
    if (service == null) {
      return;
    }
    unawaited(_onlineLobbySubscription?.cancel());
    unawaited(_onlineMembersSubscription?.cancel());
    _onlineLobbySubscription = service.watchLobby(lobbyId).listen((lobby) {
      _applyOnlineLobby(lobby);
      _commit();
    }, onError: _setLobbyError);
    _onlineMembersSubscription = service.watchMembers(lobbyId).listen((
      members,
    ) {
      _onlineLobbyMembers = members
          .map(
            (member) => LobbyMember(
              userId: member.userId,
              name: member.displayName,
              ready: member.ready,
              owner: member.owner,
              connected: member.connected,
              breakVote: member.breakVote,
            ),
          )
          .toList();
      final userId = onlineLobbyUserId;
      if (userId != null) {
        for (final member in members) {
          if (member.userId == userId) {
            currentUserReady = member.ready;
            onlineLobbyOwner = member.owner;
            break;
          }
        }
      }
      _commit();
    }, onError: _setLobbyError);
  }

  void _applyOnlineLobby(CatudyOnlineLobby lobby) {
    onlineLobbyCode = lobby.code;
    selectedCategoryId = categories.any((item) => item.id == lobby.categoryId)
        ? lobby.categoryId
        : selectedCategoryId;
    selectedDurationMinutes = lobby.durationMinutes;
    if (lobby.isRunning) {
      final startedAt = lobby.startedAt!;
      final current = activeSession;
      if (current == null ||
          !current.lobbyMode ||
          current.startedAt != startedAt ||
          current.durationMinutes != lobby.durationMinutes ||
          current.categoryId != lobby.categoryId) {
        activeSession = ActiveFocusSession(
          categoryId: lobby.categoryId,
          durationMinutes: lobby.durationMinutes,
          startedAt: startedAt,
          lobbyMode: true,
        );
      }
      lobbyStarted = true;
    }
  }

  void _setLobbyError(Object error) {
    lobbyBusy = false;
    lobbyError = _friendlyError(error, 'lobby.genericError');
    notifyListeners();
    unawaited(_save());
  }

  Future<void> _runAuthAction(
    Future<CatudyAuthSession> Function() action, {
    bool explicitGuest = false,
  }) async {
    authBusy = true;
    authError = null;
    if (explicitGuest) {
      _explicitGuestSignInPending = true;
    }
    _commit(touchState: false);
    try {
      final session = await action();
      if (session.anonymous && explicitGuest) {
        _explicitGuestUserId = session.userId;
      } else if (!session.anonymous) {
        _explicitGuestUserId = null;
      }
      _applyAuthSession(session);
    } catch (error) {
      _setAuthError(error);
      return;
    } finally {
      if (explicitGuest) {
        _explicitGuestSignInPending = false;
      }
    }
    authBusy = false;
    _commit(touchState: false);
  }

  Future<void> _runAuthVoidAction(Future<void> Function() action) async {
    authBusy = true;
    authError = null;
    _commit(touchState: false);
    try {
      await action();
    } catch (error) {
      _setAuthError(error);
      return;
    }
    authBusy = false;
    _commit(touchState: false);
  }

  void _applyAuthSession(CatudyAuthSession? session) {
    authUserId = session?.userId;
    authEmail = session?.email;
    authProvider = session?.anonymous == true ? 'guest' : session?.provider;
    authError = null;
    authBusy = false;
    if (session == null) {
      _lastBackupMergedUserId = null;
      _backupSyncTimer?.cancel();
      return;
    }
    if (!session.anonymous) {
      _explicitGuestUserId = null;
    }
    final sessionName = session.displayName.trim();
    if (sessionName.isNotEmpty) {
      final keepLocalName =
          !session.anonymous &&
          sessionName == 'Guest Cat' &&
          displayName.trim().isNotEmpty &&
          displayName.trim() != 'Guest Cat';
      if (!keepLocalName) {
        displayName = sessionName;
      }
    }
    _mergeBackupForCurrentUser();
  }

  void _resetLocalProfileIdentity() {
    displayName = 'Guest Cat';
    profileAvatarId = 'catudy';
    customProfileImageBase64 = null;
    petName = selectedPet.name;
    petNameChosen = false;
    equippedProfileItemId = null;
  }

  void _setAuthError(Object error) {
    authBusy = false;
    authError = _friendlyError(error, 'auth.genericError');
    notifyListeners();
    unawaited(_save());
  }

  String _friendlyError(Object error, String fallbackKey) {
    final text = '$error'.toLowerCase();
    if (text.contains('network') ||
        text.contains('socket') ||
        text.contains('timeout') ||
        text.contains('failed host lookup')) {
      return t('error.network');
    }
    if (text.contains('invalid') ||
        text.contains('unauthorized') ||
        text.contains('password') ||
        text.contains('email')) {
      return t('error.auth');
    }
    return t(fallbackKey);
  }

  void _syncAuthDisplayName() {
    final service = _authService;
    if (service == null || authUserId == null) {
      return;
    }
    unawaited(
      service.updateDisplayName(displayName).then(_applyAuthSession).catchError(
        (Object error) {
          _setAuthError(error);
          return null;
        },
      ),
    );
  }

  void submitBreakVote(bool approved) {
    final lobbyId = onlineLobbyId;
    final userId = onlineLobbyUserId;
    final service = _lobbyService;
    if (service != null && lobbyId != null && userId != null) {
      unawaited(
        service
            .setBreakVote(lobbyId: lobbyId, userId: userId, approved: approved)
            .catchError((Object error) {
              _setLobbyError(error);
              return null;
            }),
      );
    } else {
      localBreakVote = approved;
      if (approved) {
        petMood = (petMood + 2).clamp(0, 100);
      }
    }
    _commit();
  }

  void markIntroTourSeen() {
    introTourSeen = true;
    _commit();
  }

  void updateProfile({
    required String name,
    required String avatarId,
    String? customAvatarBase64,
  }) {
    final cleanName = name.trim();
    final syncDisplayName =
        cleanName.isNotEmpty && cleanName != displayName && isAuthenticated;
    if (cleanName.isNotEmpty) {
      displayName = cleanName;
    }
    profileAvatarId = avatarId;
    customProfileImageBase64 = customAvatarBase64;
    _commit();
    if (syncDisplayName) {
      _syncAuthDisplayName();
    }
  }

  void updatePetName(String name) {
    final cleanName = name.trim();
    petName = cleanName.isEmpty ? selectedPet.name : cleanName;
    petNameChosen = true;
    _commit();
  }

  void updateLanguage(String language) {
    final nextLanguageCode = _normalizeLanguageCode(language);
    final languageChanged = nextLanguageCode != languageCode;
    languageCode = nextLanguageCode;
    if (languageChanged) {
      _localizeDefaultCategories();
      _commit(touchState: false);
      _syncNotifications();
    }
  }

  void updateSettings({
    required String name,
    required String apiUrl,
    required bool dnd,
    required bool petNotifications,
    String? profileShareUrl,
    bool? profileStatsVisible,
    String? language,
    String? themeMode,
  }) {
    final cleanName = name.trim();
    final syncDisplayName =
        cleanName.isNotEmpty && cleanName != displayName && isAuthenticated;
    displayName = cleanName.isEmpty ? displayName : cleanName;
    apiBaseUrl = apiUrl.trim().isEmpty ? apiBaseUrl : apiUrl.trim();
    if (profileShareUrl != null) {
      profileShareBaseUrl = _normalizeBaseUrl(profileShareUrl);
    }
    if (profileStatsVisible != null) {
      publicStatsVisible = profileStatsVisible;
    }
    dndReminder = dnd;
    notifications = petNotifications;
    final nextLanguageCode = _normalizeLanguageCode(language);
    final languageChanged = nextLanguageCode != languageCode;
    languageCode = nextLanguageCode;
    if (languageChanged) {
      _localizeDefaultCategories();
    }
    themeModeCode = switch (themeMode) {
      'light' => 'light',
      'dark' => 'dark',
      _ => 'system',
    };
    _commit();
    if (languageChanged) {
      _syncNotifications();
    }
    if (syncDisplayName) {
      _syncAuthDisplayName();
    }
  }

  void loadDemoWallet() {
    gold = gold < 5000 ? 5000 : gold;
    focusPoints = focusPoints < 2500 ? 2500 : focusPoints;
    _unlockEligiblePets();
    _commit();
  }

  String _normalizeBaseUrl(String value) {
    final clean = value.trim();
    if (clean.isEmpty) {
      return '';
    }
    final withScheme = clean.contains('://') ? clean : 'https://$clean';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return clean;
    }
    final path = uri.path == '/'
        ? ''
        : uri.path.endsWith('/') && uri.path.length > 1
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;
    return Uri(
      scheme: uri.scheme,
      userInfo: uri.userInfo,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: path,
    ).toString();
  }

  String categoryName(String id) => _categoryById(id).name;

  Color categoryColor(String id) => _categoryById(id).color;

  ShopItem? shopItemById(String id) {
    for (final item in shopItems) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  ShopItem? roomItemForSlot(String slot, {LeaderboardProfile? profile}) {
    final id = profile?.roomItemIds[slot] ?? equippedRoomItemIds[slot];
    if (id == null || (profile == null && !ownedItems.contains(id))) {
      return null;
    }
    final item = shopItemById(id);
    return item != null && item.slot == slot && item.isRoomFurniture
        ? item
        : null;
  }

  ShopItem? equippedPetItemForProfile(LeaderboardProfile? profile) {
    final id = profile?.equippedPetItemId ?? equippedPetItemId;
    if (id == null || (profile == null && !ownedItems.contains(id))) {
      return null;
    }
    return shopItemById(id);
  }

  double rewardBoostPercentFor(ShopItem item) =>
      item.rewardBoostBasisPoints / 100;

  String itemName(ShopItem item) {
    final key = 'item.${item.id}.name';
    final value = t(key);
    return value == key ? item.name : value;
  }

  String itemDescription(ShopItem item) {
    final key = 'item.${item.id}.description';
    final value = t(key);
    return value == key ? item.description : value;
  }

  String t(String key, [Map<String, Object?> values = const {}]) {
    return CatudyCopy.text(languageCode, key, values);
  }

  Future<void> _loadFromStorage() async {
    try {
      final state = await _storage.readState();
      if (state != null) {
        _restoreFromJson(state);
      }
      _completeExpiredRestoredSession(DateTime.now());
    } catch (_) {
      _applyDefaults();
    }
    _loaded = true;
    notifyListeners();
    await _save();
  }

  void _commit({bool touchState = true}) {
    if (touchState && !_backupMergeInProgress) {
      stateUpdatedAt = DateTime.now();
    }
    notifyListeners();
    unawaited(_save());
    _scheduleLeaderboardSync();
    _scheduleBackupSync();
  }

  void _syncNotifications() {
    final sync = _notificationSync;
    if (sync == null) {
      return;
    }
    unawaited(sync().catchError((Object _) {}));
  }

  void _scheduleLeaderboardSync({bool immediate = false}) {
    _leaderboardSyncTimer?.cancel();
    final service = _leaderboardService;
    if (service == null || authUserId == null) {
      return;
    }
    _leaderboardSyncTimer = Timer(
      immediate ? Duration.zero : const Duration(seconds: 2),
      () {
        unawaited(
          service
              .upsertCurrentProfile(
                displayName: displayName,
                petId: selectedPetId,
                petName: petDisplayName,
                equippedPetItemId: equippedPetItemId,
                roomItemIds: Map<String, String>.from(equippedRoomItemIds),
                points: focusPoints,
                totalMinutes: totalFocusMinutes,
                streakDays: streakDays,
                sessionsCount: sessionsCount,
                favoriteCategory: favoriteCategory.name,
                statsPublic: publicStatsVisible,
              )
              .then((_) => _refreshOnlineLeaderboard())
              .catchError((Object _) {
                return null;
              }),
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_loaded) {
      return;
    }
    await _storage.writeState(_toJson());
  }

  void _mergeBackupForCurrentUser() {
    final service = _backupService;
    final userId = authUserId;
    if (service == null || userId == null) {
      _lastBackupMergedUserId = null;
      _backupSyncTimer?.cancel();
      return;
    }
    if (_lastBackupMergedUserId == userId) {
      _scheduleBackupSync(immediate: true);
      return;
    }
    if (_backupMergeFuture != null) {
      return;
    }
    _backupMergeFuture = _runBackupMerge(service, userId).whenComplete(() {
      _backupMergeFuture = null;
    });
  }

  Future<void> _runBackupMerge(
    CatudyBackupService service,
    String userId,
  ) async {
    try {
      final snapshot = await service.fetchCurrentBackup();
      if (authUserId != userId) {
        return;
      }
      if (snapshot != null && snapshot.data.isNotEmpty) {
        final merged = mergeCatudyBackupStates(_toJson(), snapshot.data);
        _backupMergeInProgress = true;
        try {
          _restoreFromJson(merged);
          if (authProvider == 'guest') {
            _explicitGuestUserId = userId;
          }
          if (_lobbyService != null) {
            offlineMode = false;
          }
          _completeExpiredRestoredSession(DateTime.now());
        } finally {
          _backupMergeInProgress = false;
        }
        notifyListeners();
        await _save();
      }
      _lastBackupMergedUserId = userId;
      _scheduleBackupSync(immediate: true);
    } catch (_) {
      _lastBackupMergedUserId = null;
    }
  }

  void _scheduleBackupSync({bool immediate = false}) {
    _backupSyncTimer?.cancel();
    final service = _backupService;
    if (service == null ||
        authUserId == null ||
        _lastBackupMergedUserId != authUserId ||
        _backupMergeInProgress) {
      return;
    }
    _backupSyncTimer = Timer(
      immediate ? Duration.zero : const Duration(seconds: 4),
      () {
        unawaited(
          service
              .upsertCurrentBackup(
                data: _toJson(),
                clientUpdatedAt: stateUpdatedAt,
              )
              .catchError((Object _) {}),
        );
      },
    );
  }

  FocusRecord _completeCurrentSession({required DateTime completedAt}) {
    final goalWasCompleted = todayGoalProgress.completed;
    final unlockedBefore = unlockedAchievements
        .map((achievement) => achievement.id)
        .toSet();
    final session =
        activeSession ??
        ActiveFocusSession(
          categoryId: selectedCategoryId,
          durationMinutes: selectedDurationMinutes,
          startedAt: DateTime.now(),
          lobbyMode: false,
        );
    final plannedSeconds = session.durationMinutes * 60;
    final elapsedSeconds = completedAt
        .difference(session.startedAt)
        .inSeconds
        .clamp(0, plannedSeconds);
    final actualMinutes = (elapsedSeconds ~/ 60).clamp(
      0,
      session.durationMinutes,
    );
    final reward = _rewardForMinutes(actualMinutes);
    final record = FocusRecord(
      id: _newEntityId('focus'),
      categoryId: session.categoryId,
      minutes: actualMinutes,
      createdAt: completedAt,
      updatedAt: completedAt,
      manual: false,
      note: actualMinutes < session.durationMinutes
          ? (session.lobbyMode
                ? 'Early lobby focus session'
                : 'Early focus session')
          : (session.lobbyMode ? 'Lobby focus session' : 'Focus session'),
      gold: reward,
      todoId: session.todoId,
    );
    history.insert(0, record);
    final todoId = session.todoId;
    if (todoId != null) {
      final index = todos.indexWhere((item) => item.id == todoId);
      if (index != -1) {
        todos[index] = todos[index].copyWith(done: true);
      }
    }
    gold += reward;
    focusPoints += reward;
    streakDays = streakDays < 1 ? 1 : streakDays;
    petMood = (petMood + 8).clamp(0, 100);
    petHunger = (petHunger + 4).clamp(0, 100);
    petEnergy = (petEnergy - 6).clamp(0, 100);
    _unlockEligiblePets();
    _queueCompletionCelebrations(
      record: record,
      goalWasCompleted: goalWasCompleted,
      unlockedBefore: unlockedBefore,
    );
    activeSession = null;
    selectedTodoId = null;
    lobbyStarted = false;
    currentUserReady = false;
    lastResult = record;
    return record;
  }

  void _queueCompletionCelebrations({
    required FocusRecord record,
    required bool goalWasCompleted,
    required Set<String> unlockedBefore,
  }) {
    final goalCompleted = todayGoalProgress.completed;
    if (!goalWasCompleted && goalCompleted) {
      _pendingCelebrations.add(
        CatudyCelebration(
          id: 'daily_goal_${record.id}',
          title: t('celebration.dailyGoalTitle'),
          body: t('celebration.dailyGoalBody', {'minutes': dailyGoalMinutes}),
          icon: Icons.track_changes_rounded,
        ),
      );
    }
    for (final achievement in unlockedAchievements) {
      if (unlockedBefore.contains(achievement.id)) {
        continue;
      }
      if (achievement.id == 'daily_goal' &&
          !goalWasCompleted &&
          goalCompleted) {
        continue;
      }
      _pendingCelebrations.add(
        CatudyCelebration(
          id: 'achievement_${achievement.id}_${record.id}',
          title: t('celebration.achievementTitle'),
          body: t('celebration.achievementBody', {
            'achievement': achievement.title,
          }),
          icon: achievement.icon,
        ),
      );
    }
  }

  int _rewardForMinutes(int minutes) {
    if (minutes <= 0) {
      return 0;
    }
    final bonus = ((minutes * focusRewardBoostBasisPoints) / 10000).round();
    return minutes + bonus;
  }

  void _scheduleActiveFocusCompletion() {
    _focusCompletionTimer?.cancel();
    final session = activeSession;
    if (session == null) {
      return;
    }
    final now = DateTime.now();
    if (!session.plannedEndAt.isAfter(now)) {
      _completeExpiredRestoredSession(now, persist: true);
      return;
    }
    _focusCompletionTimer = Timer(
      session.plannedEndAt.difference(now),
      () => _completeExpiredRestoredSession(DateTime.now(), persist: true),
    );
  }

  void _completeExpiredRestoredSession(DateTime now, {bool persist = false}) {
    final session = activeSession;
    if (session == null) {
      return;
    }
    if (session.plannedEndAt.isAfter(now)) {
      _scheduleActiveFocusCompletion();
      return;
    }
    _focusCompletionTimer?.cancel();
    _completeCurrentSession(completedAt: session.plannedEndAt);
    _restoredCompletedSession = true;
    if (persist) {
      _commit();
    }
  }

  void _applyDefaults() {
    languageCode = _defaultLanguageCode();
    categories
      ..clear()
      ..addAll(_defaultCategories(languageCode));
    history
      ..clear()
      ..addAll(_defaultHistory());
    todos.clear();
    friendUserIds.clear();
    friendRequests.clear();
    blockedUserIds.clear();
    reportedUserIds.clear();
    _fetchedProfiles.clear();
    _profileFetches.clear();
    ownedItems
      ..clear()
      ..add('violet_collar');
    equippedRoomItemIds.clear();
    unlockedPetIds
      ..clear()
      ..add('mochi');
    _pendingUnlockedPetIds.clear();
    selectedCategoryId = 'study';
    selectedDurationMinutes = 25;
    gold = 0;
    focusPoints = 0;
    streakDays = 0;
    petMood = 80;
    petHunger = 20;
    petEnergy = 75;
    displayName = 'Guest Cat';
    authBusy = false;
    authUserId = null;
    authEmail = null;
    authProvider = null;
    authError = null;
    _explicitGuestUserId = null;
    _explicitGuestSignInPending = false;
    apiBaseUrl = 'http://127.0.0.1:5099';
    profileShareBaseUrl = '';
    offlineMode = true;
    dndReminder = true;
    notifications = true;
    dailyGoalReminderEnabled = true;
    publicStatsVisible = true;
    introTourSeen = false;
    themeModeCode = 'system';
    dailyGoalMinutes = 90;
    dailyGoalReminderHour = 18;
    dailyGoalReminderMinute = 0;
    selectedTodoId = null;
    visitedProfileUserId = null;
    visitedRoomUserId = null;
    currentUserReady = false;
    lobbyStarted = false;
    lobbyBusy = false;
    onlineLobbyOwner = false;
    onlineLobbyId = null;
    onlineLobbyUserId = null;
    onlineLobbyCode = null;
    lobbyError = null;
    localBreakVote = null;
    _onlineLobbyMembers = null;
    _onlineLeaderboardProfiles = null;
    _pendingCelebrations.clear();
    activeSession = null;
    _focusCompletionTimer?.cancel();
    lastResult = null;
    selectedCalendarDate = DateTime.now();
    selectedPetId = 'mochi';
    petName = 'Mochi';
    petNameChosen = false;
    profileAvatarId = 'catudy';
    customProfileImageBase64 = null;
    equippedPetItemId = 'violet_collar';
    equippedProfileItemId = null;
    stateUpdatedAt = DateTime.now();
    _restoredCompletedSession = false;
  }

  void _restoreFromJson(Map<String, dynamic> json) {
    stateUpdatedAt = _readDate(json, 'stateUpdatedAt', DateTime.now());
    languageCode = _normalizeLanguageCode(
      _readString(json, 'languageCode', _defaultLanguageCode()),
    );
    categories
      ..clear()
      ..addAll(_readMapList(json['categories']).map(FocusCategory.fromJson));
    if (categories.isEmpty) {
      categories.addAll(_defaultCategories(languageCode));
    }

    history
      ..clear()
      ..addAll(_readMapList(json['history']).map(FocusRecord.fromJson));
    todos
      ..clear()
      ..addAll(_readMapList(json['todos']).map(CalendarTodo.fromJson));
    friendUserIds
      ..clear()
      ..addAll(_readStringList(json['friendUserIds']));
    friendRequests
      ..clear()
      ..addAll(
        _readMapList(json['friendRequests']).map(FriendRequest.fromJson),
      );
    _fetchedProfiles.clear();
    _profileFetches.clear();
    blockedUserIds
      ..clear()
      ..addAll(_readStringList(json['blockedUserIds']));
    reportedUserIds
      ..clear()
      ..addAll(_readStringList(json['reportedUserIds']));

    selectedCategoryId = _readString(json, 'selectedCategoryId', 'study');
    if (!categories.any((item) => item.id == selectedCategoryId)) {
      selectedCategoryId = categories.first.id;
    }
    selectedDurationMinutes = _readInt(json, 'selectedDurationMinutes', 25);
    gold = _readInt(json, 'gold', 0);
    focusPoints = _readInt(json, 'focusPoints', 0);
    streakDays = _readInt(json, 'streakDays', 0);
    petMood = _readInt(json, 'petMood', 80).clamp(0, 100);
    petHunger = _readInt(json, 'petHunger', 20).clamp(0, 100);
    petEnergy = _readInt(json, 'petEnergy', 75).clamp(0, 100);
    displayName = _readString(json, 'displayName', 'Guest Cat');
    final explicitGuestUserId = json['explicitGuestUserId'];
    _explicitGuestUserId =
        explicitGuestUserId is String && explicitGuestUserId.isNotEmpty
        ? explicitGuestUserId
        : null;
    authBusy = false;
    authError = null;
    apiBaseUrl = _readString(json, 'apiBaseUrl', 'http://127.0.0.1:5099');
    profileShareBaseUrl = _readString(json, 'profileShareBaseUrl', '');
    offlineMode = _readBool(json, 'offlineMode', true);
    dndReminder = _readBool(json, 'dndReminder', true);
    notifications = _readBool(json, 'notifications', true);
    dailyGoalReminderEnabled = _readBool(
      json,
      'dailyGoalReminderEnabled',
      true,
    );
    publicStatsVisible = _readBool(json, 'publicStatsVisible', true);
    introTourSeen = _readBool(json, 'introTourSeen', false);
    dailyGoalMinutes = _readInt(
      json,
      'dailyGoalMinutes',
      90,
    ).clamp(15, 720).toInt();
    dailyGoalReminderHour = _readInt(
      json,
      'dailyGoalReminderHour',
      18,
    ).clamp(0, 23).toInt();
    dailyGoalReminderMinute = _readInt(
      json,
      'dailyGoalReminderMinute',
      0,
    ).clamp(0, 59).toInt();
    selectedTodoId = _readNullableString(json, 'selectedTodoId');
    if (!todos.any((item) => item.id == selectedTodoId && !item.done)) {
      selectedTodoId = null;
    }
    visitedProfileUserId = _readNullableString(json, 'visitedProfileUserId');
    visitedRoomUserId = _readNullableString(json, 'visitedRoomUserId');
    _localizeDefaultCategories();
    themeModeCode = switch (_readString(json, 'themeModeCode', 'system')) {
      'light' => 'light',
      'dark' => 'dark',
      _ => 'system',
    };
    currentUserReady = _readBool(json, 'currentUserReady', false);
    lobbyStarted = _readBool(json, 'lobbyStarted', false);
    lobbyBusy = false;
    onlineLobbyOwner = false;
    onlineLobbyId = null;
    onlineLobbyUserId = null;
    onlineLobbyCode = null;
    lobbyError = null;
    _onlineLobbyMembers = null;
    selectedCalendarDate = _readDate(
      json,
      'selectedCalendarDate',
      DateTime.now(),
    );

    ownedItems
      ..clear()
      ..addAll(_readStringList(json['ownedItems']));
    if (ownedItems.isEmpty) {
      ownedItems.add('violet_collar');
    }
    unlockedPetIds
      ..clear()
      ..addAll(_readStringList(json['unlockedPetIds']));
    if (unlockedPetIds.isEmpty) {
      unlockedPetIds.add('mochi');
    }
    selectedPetId = _readString(json, 'selectedPetId', 'mochi');
    if (!unlockedPetIds.contains(selectedPetId)) {
      selectedPetId = 'mochi';
    }
    petName = _readString(json, 'petName', selectedPet.name);
    petNameChosen = _readBool(json, 'petNameChosen', false);
    profileAvatarId = _readString(json, 'profileAvatarId', 'catudy');
    customProfileImageBase64 = _readNullableString(
      json,
      'customProfileImageBase64',
    );
    equippedPetItemId = _readNullableString(json, 'equippedPetItemId');
    equippedProfileItemId = _readNullableString(json, 'equippedProfileItemId');
    equippedRoomItemIds
      ..clear()
      ..addAll(_readStringMap(json['equippedRoomItemIds']));
    if (equippedPetItemId != null && !ownedItems.contains(equippedPetItemId)) {
      equippedPetItemId = null;
    }
    if (equippedProfileItemId != null &&
        !ownedItems.contains(equippedProfileItemId)) {
      equippedProfileItemId = null;
    }
    _normalizeRoomEquipment();

    final activeJson = _readNullableMap(json['activeSession']);
    activeSession = activeJson == null
        ? null
        : ActiveFocusSession.fromJson(activeJson);
    final resultJson = _readNullableMap(json['lastResult']);
    lastResult = resultJson == null ? null : FocusRecord.fromJson(resultJson);
    _removeLegacySeedHistory();
  }

  void _removeLegacySeedHistory() {
    history.removeWhere(
      (item) =>
          item.note == 'Pomodoro review' ||
          item.note == 'Prototype planning' ||
          item.note == 'Manual reading log',
    );
    if (history.isEmpty && gold == 180 && focusPoints == 420) {
      gold = 0;
      focusPoints = 0;
      streakDays = 0;
      lastResult = null;
    }
  }

  void _unlockEligiblePets() {
    for (final pet in unlockablePets) {
      if (focusPoints >= pet.requiredPoints &&
          !unlockedPetIds.contains(pet.id)) {
        unlockedPetIds.add(pet.id);
        _pendingUnlockedPetIds.add(pet.id);
      }
    }
  }

  Map<String, dynamic> _toJson() => {
    'version': 2,
    'stateUpdatedAt': stateUpdatedAt.toIso8601String(),
    'categories': categories.map((item) => item.toJson()).toList(),
    'history': history.map((item) => item.toJson()).toList(),
    'todos': todos.map((item) => item.toJson()).toList(),
    'friendUserIds': friendUserIds.toList(),
    'friendRequests': friendRequests.map((item) => item.toJson()).toList(),
    'blockedUserIds': blockedUserIds.toList(),
    'reportedUserIds': reportedUserIds.toList(),
    'selectedCategoryId': selectedCategoryId,
    'selectedDurationMinutes': selectedDurationMinutes,
    'gold': gold,
    'focusPoints': focusPoints,
    'streakDays': streakDays,
    'petMood': petMood,
    'petHunger': petHunger,
    'petEnergy': petEnergy,
    'displayName': displayName,
    'explicitGuestUserId': _explicitGuestUserId,
    'apiBaseUrl': apiBaseUrl,
    'profileShareBaseUrl': profileShareBaseUrl,
    'offlineMode': offlineMode,
    'dndReminder': dndReminder,
    'notifications': notifications,
    'dailyGoalReminderEnabled': dailyGoalReminderEnabled,
    'publicStatsVisible': publicStatsVisible,
    'introTourSeen': introTourSeen,
    'languageCode': languageCode,
    'themeModeCode': themeModeCode,
    'dailyGoalMinutes': dailyGoalMinutes,
    'dailyGoalReminderHour': dailyGoalReminderHour,
    'dailyGoalReminderMinute': dailyGoalReminderMinute,
    'selectedTodoId': selectedTodoId,
    'visitedProfileUserId': visitedProfileUserId,
    'visitedRoomUserId': visitedRoomUserId,
    'currentUserReady': currentUserReady,
    'lobbyStarted': lobbyStarted,
    'selectedCalendarDate': selectedCalendarDate.toIso8601String(),
    'ownedItems': ownedItems.toList(),
    'unlockedPetIds': unlockedPetIds.toList(),
    'selectedPetId': selectedPetId,
    'petName': petName,
    'petNameChosen': petNameChosen,
    'profileAvatarId': profileAvatarId,
    'customProfileImageBase64': customProfileImageBase64,
    'equippedPetItemId': equippedPetItemId,
    'equippedProfileItemId': equippedProfileItemId,
    'equippedRoomItemIds': Map<String, String>.from(equippedRoomItemIds),
    'activeSession': activeSession?.toJson(),
    'lastResult': lastResult?.toJson(),
  };

  void _normalizeRoomEquipment() {
    equippedRoomItemIds.removeWhere((slot, id) {
      final item = shopItemById(id);
      return item == null ||
          !item.isRoomFurniture ||
          item.slot != slot ||
          !ownedItems.contains(id);
    });
    for (final item in roomFurnitureItems) {
      if (ownedItems.contains(item.id)) {
        equippedRoomItemIds.putIfAbsent(item.slot, () => item.id);
      }
    }
  }

  FocusCategory _categoryById(String id) {
    return categories.firstWhere(
      (item) => item.id == id,
      orElse: () => categories.first,
    );
  }

  void _localizeDefaultCategories() {
    for (var index = 0; index < categories.length; index += 1) {
      final category = categories[index];
      if (!_isDefaultCategoryName(category.id, category.name)) {
        continue;
      }
      categories[index] = category.copyWith(
        name: _defaultCategoryName(category.id, languageCode),
      );
    }
  }
}

List<FocusCategory> _defaultCategories(String languageCode) => [
  for (final item in _defaultCategorySpecs)
    FocusCategory(
      id: item.id,
      name: item.name(languageCode),
      color: item.color,
    ),
];

String _defaultCategoryName(String id, String languageCode) {
  for (final item in _defaultCategorySpecs) {
    if (item.id == id) {
      return item.name(languageCode);
    }
  }
  return id;
}

bool _isDefaultCategoryName(String id, String name) {
  for (final item in _defaultCategorySpecs) {
    if (item.id == id) {
      return item.enName == name || item.trName == name;
    }
  }
  return false;
}

const _defaultCategorySpecs = [
  _DefaultCategorySpec(
    id: 'study',
    trName: 'Ders',
    enName: 'Study',
    color: CatudyColors.violet,
  ),
  _DefaultCategorySpec(
    id: 'work',
    trName: 'İş',
    enName: 'Work',
    color: CatudyColors.teal,
  ),
  _DefaultCategorySpec(
    id: 'read',
    trName: 'Okuma',
    enName: 'Reading',
    color: CatudyColors.lavender,
  ),
  _DefaultCategorySpec(
    id: 'math',
    trName: 'Matematik',
    enName: 'Math',
    color: CatudyColors.tealDark,
  ),
];

class _DefaultCategorySpec {
  const _DefaultCategorySpec({
    required this.id,
    required this.trName,
    required this.enName,
    required this.color,
  });

  final String id;
  final String trName;
  final String enName;
  final Color color;

  String name(String languageCode) => languageCode == 'en' ? enName : trName;
}

List<FocusRecord> _defaultHistory() => [];

Map<String, dynamic> mergeCatudyBackupStates(
  Map<String, dynamic> local,
  Map<String, dynamic> remote,
) {
  final localUpdated = _readDate(
    local,
    'stateUpdatedAt',
    DateTime.fromMillisecondsSinceEpoch(0),
  );
  final remoteUpdated = _readDate(
    remote,
    'stateUpdatedAt',
    DateTime.fromMillisecondsSinceEpoch(0),
  );
  final merged = Map<String, dynamic>.from(
    remoteUpdated.isAfter(localUpdated) ? remote : local,
  );
  merged['categories'] = _mergeJsonRowsById(
    _readMapList(local['categories']),
    _readMapList(remote['categories']),
  );
  merged['history'] = _mergeJsonRowsById(
    _readMapList(local['history']),
    _readMapList(remote['history']),
  );
  merged['todos'] = _mergeJsonRowsById(
    _readMapList(local['todos']),
    _readMapList(remote['todos']),
  );
  merged['friendRequests'] = _mergeJsonRowsById(
    _readMapList(local['friendRequests']),
    _readMapList(remote['friendRequests']),
  );
  merged['friendUserIds'] = _mergeStringLists(
    local['friendUserIds'],
    remote['friendUserIds'],
  );
  merged['blockedUserIds'] = _mergeStringLists(
    local['blockedUserIds'],
    remote['blockedUserIds'],
  );
  merged['reportedUserIds'] = _mergeStringLists(
    local['reportedUserIds'],
    remote['reportedUserIds'],
  );
  merged['ownedItems'] = _mergeStringLists(
    local['ownedItems'],
    remote['ownedItems'],
  );
  merged['unlockedPetIds'] = _mergeStringLists(
    local['unlockedPetIds'],
    remote['unlockedPetIds'],
  );
  merged['stateUpdatedAt'] =
      (remoteUpdated.isAfter(localUpdated) ? remoteUpdated : localUpdated)
          .toIso8601String();
  return merged;
}

List<Map<String, dynamic>> _mergeJsonRowsById(
  List<Map<String, dynamic>> local,
  List<Map<String, dynamic>> remote,
) {
  final byId = <String, Map<String, dynamic>>{};
  for (final row in [...remote, ...local]) {
    final id = _jsonRowId(row);
    if (id.isEmpty) {
      continue;
    }
    final normalized = Map<String, dynamic>.from(row)
      ..putIfAbsent('id', () => id);
    final current = byId[id];
    if (current == null || _jsonRowIsNewer(normalized, current)) {
      byId[id] = normalized;
    }
  }
  return byId.values.toList();
}

String _jsonRowId(Map<String, dynamic> row) {
  final id = _readString(row, 'id', '');
  if (id.isNotEmpty) {
    return id;
  }
  final keys = row.keys.toList()..sort();
  return _legacyEntityId('row', [for (final key in keys) '$key=${row[key]}']);
}

bool _jsonRowIsNewer(Map<String, dynamic> next, Map<String, dynamic> current) {
  final fallback = DateTime.fromMillisecondsSinceEpoch(0);
  final nextDate = _readDate(
    next,
    'updatedAt',
    _readDate(next, 'createdAt', fallback),
  );
  final currentDate = _readDate(
    current,
    'updatedAt',
    _readDate(current, 'createdAt', fallback),
  );
  return nextDate.isAfter(currentDate);
}

List<String> _mergeStringLists(Object? local, Object? remote) {
  return {..._readStringList(remote), ..._readStringList(local)}.toList();
}

String _newEntityId(String prefix) {
  return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
}

String _legacyEntityId(String prefix, Iterable<Object?> parts) {
  return '${prefix}_${_stableHash(parts.join('|'))}';
}

String _stableHash(String value) {
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

String _formatDisplayUserId(String userId) {
  final clean = userId.trim();
  if (clean.isEmpty) {
    return '';
  }
  if (clean == 'local') {
    return 'LOCAL';
  }
  if (clean.startsWith('demo-')) {
    return clean.toUpperCase();
  }
  final compact = clean.replaceAll('-', '').toUpperCase();
  if (compact.length >= 10) {
    return 'CAT-${compact.substring(0, 4)}-${compact.substring(compact.length - 4)}';
  }
  return clean.toUpperCase();
}

bool _looksLikeUuid(String value) {
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}

String _defaultLanguageCode() {
  final systemCode = ui.PlatformDispatcher.instance.locale.languageCode;
  return _normalizeLanguageCode(systemCode, fallback: 'en');
}

String _normalizeLanguageCode(String? value, {String fallback = 'en'}) {
  final clean = value?.trim().toLowerCase();
  if (clean != null && CatudyDemoStore.supportedLanguageCodes.contains(clean)) {
    return clean;
  }
  return CatudyDemoStore.supportedLanguageCodes.contains(fallback)
      ? fallback
      : 'en';
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

String _readString(Map<String, dynamic> json, String key, String fallback) {
  final value = json[key];
  return value is String && value.isNotEmpty ? value : fallback;
}

String? _readNullableString(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is String && value.isNotEmpty ? value : null;
}

bool _readBool(Map<String, dynamic> json, String key, bool fallback) {
  final value = json[key];
  return value is bool ? value : fallback;
}

DateTime _readDate(Map<String, dynamic> json, String key, DateTime fallback) {
  final value = json[key];
  return value is String ? DateTime.tryParse(value) ?? fallback : fallback;
}

DateTime? _readNullableDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is String ? DateTime.tryParse(value) : null;
}

List<Map<String, dynamic>> _readMapList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return [
    for (final item in value)
      if (item is Map)
        {
          for (final entry in item.entries)
            if (entry.key is String) entry.key as String: entry.value,
        },
  ];
}

List<String> _readStringList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value.whereType<String>().toList();
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

Map<String, dynamic>? _readNullableMap(Object? value) {
  return value is Map<String, dynamic> ? value : null;
}
