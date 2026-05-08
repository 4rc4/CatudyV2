import 'dart:async';

import 'package:catudy_app/app/demo/catudy_demo_store.dart';
import 'package:catudy_app/app/online/catudy_auth_service.dart';
import 'package:catudy_app/app/online/catudy_leaderboard_service.dart';
import 'package:catudy_app/app/storage/catudy_local_storage.dart';
import 'package:catudy_app/app/theme/catudy_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'loads persisted guest profile, categories, wallet, and inventory',
    () async {
      final storage = _MemoryStorage({
        'categories': [
          {
            'id': 'physics',
            'name': 'Physics',
            'color': CatudyColors.teal.toARGB32(),
          },
        ],
        'history': [
          {
            'categoryId': 'physics',
            'minutes': 50,
            'createdAt': DateTime(2026, 4, 27, 12).toIso8601String(),
            'manual': true,
            'note': 'Lab catch-up',
            'gold': 0,
          },
        ],
        'selectedCategoryId': 'physics',
        'selectedDurationMinutes': 40,
        'gold': 70,
        'focusPoints': 900,
        'streakDays': 3,
        'petMood': 90,
        'petHunger': 10,
        'displayName': 'Arca',
        'apiBaseUrl': 'http://localhost:5000',
        'offlineMode': true,
        'dndReminder': false,
        'notifications': false,
        'ownedItems': ['violet_collar', 'sunny_hat'],
        'equippedPetItemId': 'sunny_hat',
      });
      final store = CatudyDemoStore(storage: storage);

      await store.load();

      expect(store.displayName, 'Arca');
      expect(store.selectedCategory.name, 'Physics');
      expect(store.selectedDurationMinutes, 40);
      expect(store.gold, 70);
      expect(store.history.single.manual, isTrue);
      expect(store.ownedItems.contains('sunny_hat'), isTrue);
      expect(store.equippedPetItemId, 'sunny_hat');
      expect(storage.state?['displayName'], 'Arca');
    },
  );

  test('completes expired active timer during restore', () async {
    final startedAt = DateTime.now().subtract(const Duration(minutes: 30));
    final storage = _MemoryStorage({
      'categories': [
        {
          'id': 'study',
          'name': 'Study',
          'color': CatudyColors.violet.toARGB32(),
        },
      ],
      'history': [],
      'selectedCategoryId': 'study',
      'selectedDurationMinutes': 25,
      'gold': 0,
      'focusPoints': 0,
      'ownedItems': ['violet_collar'],
      'activeSession': {
        'categoryId': 'study',
        'durationMinutes': 25,
        'startedAt': startedAt.toIso8601String(),
        'lobbyMode': false,
      },
    });
    final store = CatudyDemoStore(storage: storage);

    await store.load();

    expect(store.activeSession, isNull);
    expect(store.lastResult?.minutes, 25);
    expect(store.gold, 25);
    expect(store.consumeInitialRestoreRoute(), '/focus/result');
    expect(storage.state?['activeSession'], isNull);
  });

  test('early completed focus only rewards elapsed minutes', () async {
    final storage = _MemoryStorage(null);
    final store = CatudyDemoStore(storage: storage);

    await store.load();

    store.activeSession = ActiveFocusSession(
      categoryId: 'study',
      durationMinutes: 25,
      startedAt: DateTime.now().subtract(
        const Duration(minutes: 9, seconds: 30),
      ),
      lobbyMode: false,
    );

    final record = store.completeFocus();

    expect(record.minutes, 9);
    expect(record.gold, 9);
    expect(store.gold, 9);
    expect(store.focusPoints, 9);
    expect(store.history.first.minutes, 9);
  });

  test('room furniture equips by slot and boosts focus rewards', () async {
    final storage = _MemoryStorage(null);
    final store = CatudyDemoStore(storage: storage);

    await store.load();

    expect(
      store.roomFurnitureItems.every((item) => item.assetPath != null),
      isTrue,
    );

    store.gold = 1000;

    expect(store.buyItem('moonlit_study_nook'), isTrue);
    expect(store.buyItem('warm_den_bed'), isTrue);
    expect(store.equippedRoomItemIds['room_study'], 'moonlit_study_nook');
    expect(store.equippedRoomItemIds['room_bed'], 'warm_den_bed');
    expect(store.focusRewardBoostBasisPoints, 500);
    expect(storage.state?['equippedRoomItemIds'], {
      'room_study': 'moonlit_study_nook',
      'room_bed': 'warm_den_bed',
    });

    store.activeSession = ActiveFocusSession(
      categoryId: 'study',
      durationMinutes: 60,
      startedAt: DateTime.now().subtract(const Duration(minutes: 60)),
      lobbyMode: false,
    );

    final record = store.completeFocus();

    expect(record.minutes, 60);
    expect(record.gold, 63);
    expect(store.focusPoints, 63);
  });

  test('demo wallet tops up currency without clearing purchases', () async {
    final storage = _MemoryStorage(null);
    final store = CatudyDemoStore(storage: storage);

    await store.load();

    store.gold = 120;
    store.focusPoints = 80;
    store.ownedItems.add('sunny_hat');

    store.loadDemoWallet();

    expect(store.gold, 5000);
    expect(store.focusPoints, 2500);
    expect(store.ownedItems.contains('sunny_hat'), isTrue);
    expect(storage.state?['gold'], 5000);
    expect(storage.state?['focusPoints'], 2500);
  });

  test('pet name is chosen and persisted', () async {
    final storage = _MemoryStorage(null);
    final store = CatudyDemoStore(storage: storage);

    await store.load();

    expect(store.petNameChosen, isFalse);

    store.updatePetName('Minik');

    expect(store.petDisplayName, 'Minik');
    expect(store.petNameChosen, isTrue);
    expect(storage.state?['petName'], 'Minik');
    expect(storage.state?['petNameChosen'], isTrue);
  });

  test('selected focus task is completed with the session', () async {
    final storage = _MemoryStorage(null);
    final store = CatudyDemoStore(storage: storage);

    await store.load();

    final todo = store.addTodoReminder(
      date: DateTime.now(),
      time: const TimeOfDay(hour: 9, minute: 0),
      title: 'Read chapter',
    )!;
    store.selectTodoForFocus(todo.id);
    store.activeSession = ActiveFocusSession(
      categoryId: 'study',
      durationMinutes: 25,
      startedAt: DateTime.now().subtract(const Duration(minutes: 25)),
      lobbyMode: false,
      todoId: todo.id,
    );

    final record = store.completeFocus();

    expect(record.todoId, todo.id);
    expect(store.todos.single.done, isTrue);
    expect(store.selectedFocusTodo, isNull);
    expect(storage.state?['todos'].single['done'], isTrue);
  });

  test('friends can be added and visited from social profiles', () async {
    final storage = _MemoryStorage(null);
    final store = CatudyDemoStore(storage: storage);

    await store.load();

    final friend = store.socialProfiles.firstWhere(
      (profile) => !profile.currentUser,
    );

    store.toggleFriend(friend.userId);
    store.visitProfile(friend.userId);

    expect(store.friendUserIds.contains(friend.userId), isTrue);
    expect(store.friendProfiles.single.userId, friend.userId);
    expect(store.visitedProfile?.name, friend.name);
    expect(storage.state?['friendUserIds'], contains(friend.userId));

    store.toggleFriend(friend.userId);

    expect(store.friendUserIds.contains(friend.userId), isFalse);
  });

  test(
    'local leaderboard contains only the current profile before online sync',
    () async {
      final storage = _MemoryStorage(null);
      final store = CatudyDemoStore(storage: storage);

      await store.load();

      store.updateProfile(name: 'Arca', avatarId: 'catudy');

      expect(store.leaderboardProfiles, hasLength(1));
      expect(store.leaderboardProfiles.single.name, 'Arca');
      expect(store.leaderboardProfiles.single.currentUser, isTrue);
    },
  );

  test('leaderboard sync does not create a profile before auth', () async {
    final store = CatudyDemoStore(storage: _MemoryStorage(null));
    final leaderboard = _FakeLeaderboardService();

    await store.load();

    store.attachLeaderboardService(leaderboard);
    store.updateProfile(name: 'Arca', avatarId: 'catudy');
    await Future<void>.delayed(Duration.zero);

    expect(leaderboard.upsertCalls, 0);
    expect(store.isAuthenticated, isFalse);
  });

  test(
    'restored anonymous session is discarded without guest marker',
    () async {
      final store = CatudyDemoStore(storage: _MemoryStorage(null));
      final auth = _FakeAuthService(
        const CatudyAuthSession(
          userId: 'anonymous-user',
          email: null,
          displayName: 'Guest Cat',
          provider: 'anonymous',
          anonymous: true,
        ),
      );

      await store.load();

      store.attachAuthService(auth);
      await Future<void>.delayed(Duration.zero);

      expect(auth.signOutCalls, 1);
      expect(store.isAuthenticated, isFalse);
    },
  );

  test('restored anonymous session is kept with guest marker', () async {
    final store = CatudyDemoStore(
      storage: _MemoryStorage({'explicitGuestUserId': 'anonymous-user'}),
    );
    final auth = _FakeAuthService(
      const CatudyAuthSession(
        userId: 'anonymous-user',
        email: null,
        displayName: 'Guest Cat',
        provider: 'anonymous',
        anonymous: true,
      ),
    );

    await store.load();

    store.attachAuthService(auth);
    await Future<void>.delayed(Duration.zero);

    expect(auth.signOutCalls, 0);
    expect(store.isAuthenticated, isTrue);
    expect(store.authProvider, 'guest');
  });

  test('shop item names follow selected language', () async {
    final store = CatudyDemoStore(storage: _MemoryStorage(null));

    await store.load();

    final item = store.shopItemById('soft_study_nook')!;
    expect(store.itemName(item), 'Yumuşak Çalışma Alanı');

    store.updateSettings(
      name: store.displayName,
      apiUrl: store.apiBaseUrl,
      dnd: store.dndReminder,
      petNotifications: store.notifications,
      language: 'en',
      themeMode: store.themeModeCode,
    );

    expect(store.itemName(item), 'Soft Study Nook');
    expect(
      store.itemDescription(item),
      'A cushioned low study corner made for Mochi.',
    );
  });

  test('default category names follow selected language', () async {
    final store = CatudyDemoStore(storage: _MemoryStorage(null));

    await store.load();

    expect(store.categories.map((item) => item.name), [
      'Ders',
      'İş',
      'Okuma',
      'Matematik',
    ]);

    store.addCategory('Physics', CatudyColors.coral);
    store.updateSettings(
      name: store.displayName,
      apiUrl: store.apiBaseUrl,
      dnd: store.dndReminder,
      petNotifications: store.notifications,
      language: 'en',
      themeMode: store.themeModeCode,
    );

    expect(store.categories.map((item) => item.name), [
      'Study',
      'Work',
      'Reading',
      'Math',
      'Physics',
    ]);
  });

  test('persisted default category names localize on restore', () async {
    final storage = _MemoryStorage({
      'categories': [
        {
          'id': 'study',
          'name': 'Study',
          'color': CatudyColors.violet.toARGB32(),
        },
        {'id': 'work', 'name': 'Work', 'color': CatudyColors.teal.toARGB32()},
      ],
      'languageCode': 'tr',
      'history': [],
      'selectedCategoryId': 'study',
      'ownedItems': ['violet_collar'],
    });
    final store = CatudyDemoStore(storage: storage);

    await store.load();

    expect(store.categories.map((item) => item.name), ['Ders', 'İş']);
  });
}

class _MemoryStorage extends CatudyLocalStorage {
  _MemoryStorage(this.state);

  Map<String, dynamic>? state;

  @override
  Future<Map<String, dynamic>?> readState() async => state;

  @override
  Future<void> writeState(Map<String, dynamic> state) async {
    this.state = Map<String, dynamic>.from(state);
  }
}

class _FakeLeaderboardService extends CatudyLeaderboardService {
  _FakeLeaderboardService() : super(_testSupabaseClient());

  int upsertCalls = 0;

  @override
  String? get currentUserId => null;

  @override
  Stream<List<CatudyOnlineLeaderboardProfile>> watchTopProfiles() {
    return const Stream.empty();
  }

  @override
  Future<String?> upsertCurrentProfile({
    required String displayName,
    required String petId,
    required int points,
    required int totalMinutes,
    required int streakDays,
  }) async {
    upsertCalls++;
    return 'test-user';
  }
}

class _FakeAuthService extends CatudyAuthService {
  _FakeAuthService(this._session) : super(_testSupabaseClient());

  final _controller = StreamController<CatudyAuthSession?>.broadcast();
  CatudyAuthSession? _session;
  int signOutCalls = 0;

  @override
  CatudyAuthSession? get currentSession => _session;

  @override
  Stream<CatudyAuthSession?> get authStateChanges => _controller.stream;

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _session = null;
    _controller.add(null);
  }
}

SupabaseClient _testSupabaseClient() {
  return SupabaseClient('http://127.0.0.1:54321', 'test-anon-key');
}
