import 'dart:async';

import 'package:flutter/material.dart';

import '../localization/catudy_copy.dart';
import '../online/catudy_auth_service.dart';
import '../online/catudy_leaderboard_service.dart';
import '../online/catudy_lobby_service.dart';
import '../storage/catudy_local_storage.dart';
import '../theme/catudy_colors.dart';

final catudyDemoStore = CatudyDemoStore();

class FocusCategory {
  const FocusCategory({
    required this.id,
    required this.name,
    required this.color,
  });

  factory FocusCategory.fromJson(Map<String, dynamic> json) {
    return FocusCategory(
      id: _readString(json, 'id', 'study'),
      name: _readString(json, 'name', 'Study'),
      color: Color(_readInt(json, 'color', CatudyColors.violet.toARGB32())),
    );
  }

  final String id;
  final String name;
  final Color color;

  FocusCategory copyWith({String? name}) {
    return FocusCategory(id: id, name: name ?? this.name, color: color);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color.toARGB32(),
  };
}

class FocusRecord {
  const FocusRecord({
    required this.categoryId,
    required this.minutes,
    required this.createdAt,
    required this.manual,
    required this.note,
    required this.gold,
  });

  factory FocusRecord.fromJson(Map<String, dynamic> json) {
    return FocusRecord(
      categoryId: _readString(json, 'categoryId', 'study'),
      minutes: _readInt(json, 'minutes', 25),
      createdAt: _readDate(json, 'createdAt', DateTime.now()),
      manual: _readBool(json, 'manual', false),
      note: _readString(json, 'note', 'Focus session'),
      gold: _readInt(json, 'gold', 0),
    );
  }

  final String categoryId;
  final int minutes;
  final DateTime createdAt;
  final bool manual;
  final String note;
  final int gold;

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'minutes': minutes,
    'createdAt': createdAt.toIso8601String(),
    'manual': manual,
    'note': note,
    'gold': gold,
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
  });

  factory CalendarTodo.fromJson(Map<String, dynamic> json) {
    return CalendarTodo(
      id: _readString(
        json,
        'id',
        DateTime.now().microsecondsSinceEpoch.toString(),
      ),
      title: _readString(json, 'title', 'Planlı hatırlatma'),
      date: _readDate(json, 'date', DateTime.now()),
      hour: _readInt(json, 'hour', 9).clamp(0, 23),
      minute: _readInt(json, 'minute', 0).clamp(0, 59),
      done: _readBool(json, 'done', false),
    );
  }

  final String id;
  final String title;
  final DateTime date;
  final int hour;
  final int minute;
  final bool done;

  DateTime get scheduledAt =>
      DateTime(date.year, date.month, date.day, hour, minute);

  CalendarTodo copyWith({bool? done}) {
    return CalendarTodo(
      id: id,
      title: title,
      date: date,
      hour: hour,
      minute: minute,
      done: done ?? this.done,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
    'hour': hour,
    'minute': minute,
    'done': done,
  };
}

class ActiveFocusSession {
  const ActiveFocusSession({
    required this.categoryId,
    required this.durationMinutes,
    required this.startedAt,
    required this.lobbyMode,
  });

  factory ActiveFocusSession.fromJson(Map<String, dynamic> json) {
    return ActiveFocusSession(
      categoryId: _readString(json, 'categoryId', 'study'),
      durationMinutes: _readInt(json, 'durationMinutes', 25),
      startedAt: _readDate(json, 'startedAt', DateTime.now()),
      lobbyMode: _readBool(json, 'lobbyMode', false),
    );
  }

  final String categoryId;
  final int durationMinutes;
  final DateTime startedAt;
  final bool lobbyMode;

  DateTime get plannedEndAt =>
      startedAt.add(Duration(minutes: durationMinutes));

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'durationMinutes': durationMinutes,
    'startedAt': startedAt.toIso8601String(),
    'lobbyMode': lobbyMode,
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
    required this.points,
    required this.totalMinutes,
    required this.streakDays,
    required this.currentUser,
  });

  final String userId;
  final String name;
  final String petId;
  final int points;
  final int totalMinutes;
  final int streakDays;
  final bool currentUser;
}

class CatudyDemoStore extends ChangeNotifier {
  CatudyDemoStore({CatudyLocalStorage storage = const CatudyLocalStorage()})
    : _storage = storage {
    _applyDefaults();
  }

  final CatudyLocalStorage _storage;
  CatudyAuthService? _authService;
  CatudySupabaseLobbyService? _lobbyService;
  CatudyLeaderboardService? _leaderboardService;
  StreamSubscription<CatudyAuthSession?>? _authSubscription;
  StreamSubscription<CatudyOnlineLobby>? _onlineLobbySubscription;
  StreamSubscription<List<CatudyOnlineLobbyMember>>? _onlineMembersSubscription;
  StreamSubscription<List<CatudyOnlineLeaderboardProfile>>?
  _leaderboardSubscription;
  Future<void>? _loadFuture;
  bool _loaded = false;
  bool _restoredCompletedSession = false;
  List<LobbyMember>? _onlineLobbyMembers;
  List<LeaderboardProfile>? _onlineLeaderboardProfiles;
  Timer? _leaderboardSyncTimer;

  final categories = <FocusCategory>[];
  final durations = <int>[15, 25, 40, 60];
  final history = <FocusRecord>[];
  final todos = <CalendarTodo>[];
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
  bool offlineMode = true;
  bool dndReminder = true;
  bool notifications = true;
  bool introTourSeen = false;
  String languageCode = 'tr';
  String themeModeCode = 'system';
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

  bool get needsAuth => onlineAuthAvailable && !isAuthenticated;

  bool get hasOnlineLobby => onlineLobbyId != null;

  String? get lobbyJoinCode => onlineLobbyCode;

  bool get canStartLobby {
    if (!hasOnlineLobby) {
      return false;
    }
    final connected = lobbyMembers.where((member) => member.connected).toList();
    return onlineLobbyOwner &&
        connected.isNotEmpty &&
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
                points: profile.points,
                totalMinutes: profile.totalMinutes,
                streakDays: profile.streakDays,
                currentUser: profile.userId == currentId,
              ),
          ];
    if (!profiles.any((profile) => profile.userId == currentId)) {
      profiles.add(_localLeaderboardProfile(currentId));
    }
    profiles.sort((a, b) => b.points.compareTo(a.points));
    return profiles;
  }

  String get _currentLeaderboardUserId =>
      authUserId ?? _leaderboardService?.currentUserId ?? 'local';

  LeaderboardProfile _localLeaderboardProfile(String userId) {
    return LeaderboardProfile(
      userId: userId,
      name: displayName,
      petId: selectedPetId,
      points: focusPoints,
      totalMinutes: totalFocusMinutes,
      streakDays: streakDays,
      currentUser: true,
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

  void attachAuthService(CatudyAuthService service) {
    _authService = service;
    _applyAuthSession(service.currentSession);
    unawaited(_authSubscription?.cancel());
    _authSubscription = service.authStateChanges.listen((session) {
      _applyAuthSession(session);
      _commit();
    }, onError: _setAuthError);
    notifyListeners();
    unawaited(_save());
  }

  void attachLobbyService(CatudySupabaseLobbyService service) {
    _lobbyService = service;
    offlineMode = false;
    notifyListeners();
    unawaited(_save());
  }

  void attachLeaderboardService(CatudyLeaderboardService service) {
    _leaderboardService = service;
    unawaited(_leaderboardSubscription?.cancel());
    _leaderboardSubscription = service.watchTopProfiles().listen(
      (profiles) {
        final currentId = _currentLeaderboardUserId;
        _onlineLeaderboardProfiles = profiles
            .map(
              (profile) => LeaderboardProfile(
                userId: profile.userId,
                name: profile.displayName,
                petId: profile.petId,
                points: profile.points,
                totalMinutes: profile.totalMinutes,
                streakDays: profile.streakDays,
                currentUser: profile.userId == currentId,
              ),
            )
            .toList();
        notifyListeners();
      },
      onError: (_) {
        _onlineLeaderboardProfiles = null;
        notifyListeners();
      },
    );
    _scheduleLeaderboardSync(immediate: true);
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
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: cleanTitle,
      date: DateTime(date.year, date.month, date.day),
      hour: time.hour,
      minute: time.minute,
      done: false,
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
    categories.add(FocusCategory(id: id, name: cleanName, color: color));
    selectedCategoryId = id;
    _commit();
  }

  void selectDuration(int minutes) {
    selectedDurationMinutes = minutes;
    _commit();
  }

  void prepareRecommendedFocus() {
    final recommendation = focusRecommendation;
    selectCategory(recommendation.categoryId);
    selectedDurationMinutes = recommendation.minutes;
    _commit();
  }

  void startFocus({bool lobbyMode = false}) {
    activeSession = ActiveFocusSession(
      categoryId: selectedCategoryId,
      durationMinutes: selectedDurationMinutes,
      startedAt: DateTime.now(),
      lobbyMode: lobbyMode,
    );
    lastResult = null;
    localBreakVote = null;
    _restoredCompletedSession = false;
    if (lobbyMode) {
      lobbyStarted = true;
    }
    _commit();
  }

  void cancelFocus() {
    activeSession = null;
    lobbyStarted = false;
    currentUserReady = false;
    localBreakVote = null;
    _restoredCompletedSession = false;
    _commit();
  }

  FocusRecord completeFocus() {
    final record = _completeCurrentSession(completedAt: DateTime.now());
    _restoredCompletedSession = false;
    _commit();
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
        categoryId: categoryId,
        minutes: minutes,
        createdAt: DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          now.hour,
          now.minute,
        ),
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
      _commit();
      return;
    }
    await _runAuthAction(() => service.signInAsGuest(displayName));
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final service = _authService;
    if (service == null) {
      authError = t('auth.offlineUnavailable');
      _commit();
      return;
    }
    await _runAuthAction(
      () => service.signInWithEmail(email: email, password: password),
    );
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final service = _authService;
    if (service == null) {
      authError = t('auth.offlineUnavailable');
      _commit();
      return;
    }
    await _runAuthAction(
      () => service.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    final service = _authService;
    if (service == null) {
      authError = t('auth.offlineUnavailable');
      _commit();
      return;
    }
    await _runAuthVoidAction(service.signInWithGoogle);
  }

  Future<void> signInWithApple() async {
    final service = _authService;
    if (service == null) {
      authError = t('auth.offlineUnavailable');
      _commit();
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
    _commit();
    try {
      await service.signOut();
      _applyAuthSession(null);
    } catch (error) {
      _setAuthError(error);
      return;
    }
    authBusy = false;
    _commit();
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
      if (!onlineLobbyOwner) {
        lobbyError = t('lobby.onlyOwnerCanStart');
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
    lobbyError = '$error';
    notifyListeners();
    unawaited(_save());
  }

  Future<void> _runAuthAction(
    Future<CatudyAuthSession> Function() action,
  ) async {
    authBusy = true;
    authError = null;
    _commit();
    try {
      final session = await action();
      _applyAuthSession(session);
    } catch (error) {
      _setAuthError(error);
      return;
    }
    authBusy = false;
    _commit();
  }

  Future<void> _runAuthVoidAction(Future<void> Function() action) async {
    authBusy = true;
    authError = null;
    _commit();
    try {
      await action();
    } catch (error) {
      _setAuthError(error);
      return;
    }
    authBusy = false;
    _commit();
  }

  void _applyAuthSession(CatudyAuthSession? session) {
    authUserId = session?.userId;
    authEmail = session?.email;
    authProvider = session?.anonymous == true ? 'guest' : session?.provider;
    authError = null;
    authBusy = false;
    if (session != null && session.displayName.trim().isNotEmpty) {
      displayName = session.displayName.trim();
    }
  }

  void _setAuthError(Object error) {
    authBusy = false;
    authError = '$error';
    notifyListeners();
    unawaited(_save());
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
    if (cleanName.isNotEmpty) {
      displayName = cleanName;
    }
    profileAvatarId = avatarId;
    customProfileImageBase64 = customAvatarBase64;
    _commit();
  }

  void updatePetName(String name) {
    final cleanName = name.trim();
    petName = cleanName.isEmpty ? selectedPet.name : cleanName;
    petNameChosen = true;
    _commit();
  }

  void updateSettings({
    required String name,
    required String apiUrl,
    required bool dnd,
    required bool petNotifications,
    String? language,
    String? themeMode,
  }) {
    displayName = name.trim().isEmpty ? displayName : name.trim();
    apiBaseUrl = apiUrl.trim().isEmpty ? apiBaseUrl : apiUrl.trim();
    dndReminder = dnd;
    notifications = petNotifications;
    final nextLanguageCode = language == 'en' ? 'en' : 'tr';
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
  }

  void loadDemoWallet() {
    gold = gold < 5000 ? 5000 : gold;
    focusPoints = focusPoints < 2500 ? 2500 : focusPoints;
    _unlockEligiblePets();
    _commit();
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

  ShopItem? roomItemForSlot(String slot) {
    final id = equippedRoomItemIds[slot];
    if (id == null || !ownedItems.contains(id)) {
      return null;
    }
    final item = shopItemById(id);
    return item != null && item.slot == slot && item.isRoomFurniture
        ? item
        : null;
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

  void _commit() {
    notifyListeners();
    unawaited(_save());
    _scheduleLeaderboardSync();
  }

  void _scheduleLeaderboardSync({bool immediate = false}) {
    final service = _leaderboardService;
    if (service == null) {
      return;
    }
    _leaderboardSyncTimer?.cancel();
    _leaderboardSyncTimer = Timer(
      immediate ? Duration.zero : const Duration(seconds: 2),
      () {
        unawaited(
          service
              .upsertCurrentProfile(
                displayName: displayName,
                petId: selectedPetId,
                points: focusPoints,
                totalMinutes: totalFocusMinutes,
                streakDays: streakDays,
              )
              .catchError((Object _) {
                _onlineLeaderboardProfiles = null;
                notifyListeners();
                return '';
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

  FocusRecord _completeCurrentSession({required DateTime completedAt}) {
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
      categoryId: session.categoryId,
      minutes: actualMinutes,
      createdAt: completedAt,
      manual: false,
      note: actualMinutes < session.durationMinutes
          ? (session.lobbyMode
                ? 'Early lobby focus session'
                : 'Early focus session')
          : (session.lobbyMode ? 'Lobby focus session' : 'Focus session'),
      gold: reward,
    );
    history.insert(0, record);
    gold += reward;
    focusPoints += reward;
    streakDays = streakDays < 1 ? 1 : streakDays;
    petMood = (petMood + 8).clamp(0, 100);
    petHunger = (petHunger + 4).clamp(0, 100);
    petEnergy = (petEnergy - 6).clamp(0, 100);
    _unlockEligiblePets();
    activeSession = null;
    lobbyStarted = false;
    currentUserReady = false;
    lastResult = record;
    return record;
  }

  int _rewardForMinutes(int minutes) {
    if (minutes <= 0) {
      return 0;
    }
    final bonus = ((minutes * focusRewardBoostBasisPoints) / 10000).round();
    return minutes + bonus;
  }

  void _completeExpiredRestoredSession(DateTime now) {
    final session = activeSession;
    if (session == null || session.plannedEndAt.isAfter(now)) {
      return;
    }
    _completeCurrentSession(completedAt: session.plannedEndAt);
    _restoredCompletedSession = true;
  }

  void _applyDefaults() {
    languageCode = 'tr';
    categories
      ..clear()
      ..addAll(_defaultCategories(languageCode));
    history
      ..clear()
      ..addAll(_defaultHistory());
    todos.clear();
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
    apiBaseUrl = 'http://127.0.0.1:5099';
    offlineMode = true;
    dndReminder = true;
    notifications = true;
    introTourSeen = false;
    themeModeCode = 'system';
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
    activeSession = null;
    lastResult = null;
    selectedCalendarDate = DateTime.now();
    selectedPetId = 'mochi';
    petName = 'Mochi';
    petNameChosen = false;
    profileAvatarId = 'catudy';
    customProfileImageBase64 = null;
    equippedPetItemId = 'violet_collar';
    equippedProfileItemId = null;
    _restoredCompletedSession = false;
  }

  void _restoreFromJson(Map<String, dynamic> json) {
    languageCode = _readString(json, 'languageCode', 'tr') == 'en'
        ? 'en'
        : 'tr';
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
    authBusy = false;
    authError = null;
    apiBaseUrl = _readString(json, 'apiBaseUrl', 'http://127.0.0.1:5099');
    offlineMode = _readBool(json, 'offlineMode', true);
    dndReminder = _readBool(json, 'dndReminder', true);
    notifications = _readBool(json, 'notifications', true);
    introTourSeen = _readBool(json, 'introTourSeen', false);
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
    'version': 1,
    'categories': categories.map((item) => item.toJson()).toList(),
    'history': history.map((item) => item.toJson()).toList(),
    'todos': todos.map((item) => item.toJson()).toList(),
    'selectedCategoryId': selectedCategoryId,
    'selectedDurationMinutes': selectedDurationMinutes,
    'gold': gold,
    'focusPoints': focusPoints,
    'streakDays': streakDays,
    'petMood': petMood,
    'petHunger': petHunger,
    'petEnergy': petEnergy,
    'displayName': displayName,
    'apiBaseUrl': apiBaseUrl,
    'offlineMode': offlineMode,
    'dndReminder': dndReminder,
    'notifications': notifications,
    'introTourSeen': introTourSeen,
    'languageCode': languageCode,
    'themeModeCode': themeModeCode,
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

List<Map<String, dynamic>> _readMapList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value.whereType<Map<String, dynamic>>().toList();
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
