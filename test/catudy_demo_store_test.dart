import 'dart:async';
import 'dart:math';

import 'package:catudy_app/app/demo/catudy_demo_store.dart';
import 'package:catudy_app/app/online/catudy_auth_service.dart';
import 'package:catudy_app/app/online/catudy_leaderboard_service.dart';
import 'package:catudy_app/app/online/catudy_premium_service.dart';
import 'package:catudy_app/app/premium/catudy_premium_models.dart';
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
    expect(store.focusPoints, 60);
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

  test(
    'active focus navigation returns to timer without clearing session',
    () async {
      final storage = _MemoryStorage(null);
      final store = CatudyDemoStore(storage: storage);

      await store.load();

      store.activeSession = ActiveFocusSession(
        categoryId: 'study',
        durationMinutes: 25,
        startedAt: DateTime.now(),
        lobbyMode: false,
      );

      try {
        expect(store.consumeFocusNavigationRoute(), '/focus/timer');
        expect(store.activeSession, isNotNull);
      } finally {
        store.cancelFocus();
      }
    },
  );

  test(
    'completed focus queues daily goal and achievement celebrations',
    () async {
      final store = CatudyDemoStore(
        storage: _MemoryStorage({'languageCode': 'tr'}),
      );

      await store.load();

      store.updateDailyGoal(15);
      store.activeSession = ActiveFocusSession(
        categoryId: 'study',
        durationMinutes: 15,
        startedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        lobbyMode: false,
      );

      store.completeFocus();

      final first = store.takePendingCelebration();
      final second = store.takePendingCelebration();

      expect(first?.title, 'Günlük hedef tamamlandı');
      expect(second?.title, 'Başarım açıldı');
      expect(store.takePendingCelebration(), isNull);
    },
  );

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

    expect(store.addFriendByQuery('Ada'), FriendAddResult.notFound);
    expect(store.addFriendByQuery('demo-ada'), FriendAddResult.added);
    expect(store.friendUserIds.contains('demo-ada'), isTrue);
    expect(store.addFriendByQuery('demo-ada'), FriendAddResult.alreadyFriend);
    expect(store.addFriendByQuery('local'), FriendAddResult.self);
    expect(store.addFriendByQuery('unknown-user'), FriendAddResult.notFound);

    store.friendUserIds.clear();

    expect(
      store.sendFriendRequestByQuery('demo-ada'),
      FriendRequestActionResult.sent,
    );
    expect(store.outgoingFriendRequests.single.toUserId, 'demo-ada');
    expect(
      store.sendFriendRequestByQuery('demo-ada'),
      FriendRequestActionResult.alreadyPending,
    );

    store.cancelFriendRequest(store.outgoingFriendRequests.single.id);
    expect(store.outgoingFriendRequests, isEmpty);

    expect(
      store.sendFriendRequestByQuery('demo-ada'),
      FriendRequestActionResult.sent,
    );
    store.rejectFriendRequest(store.outgoingFriendRequests.single.id);
    store.sendDemoIncomingFriendRequest('demo-ada');
    expect(store.incomingFriendRequests.single.fromUserId, 'demo-ada');

    store.acceptFriendRequest(store.incomingFriendRequests.single.id);
    expect(store.friendUserIds.contains('demo-ada'), isTrue);

    store.visitPetRoom('demo-ada');
    expect(store.visitedRoomProfile?.userId, 'demo-ada');

    store.removeFriend('demo-ada');
    expect(store.friendUserIds.contains('demo-ada'), isFalse);

    store.friendUserIds.add('demo-ada');
    store.blockUser('demo-ada');
    expect(store.blockedUserIds.contains('demo-ada'), isTrue);
    expect(store.friendUserIds.contains('demo-ada'), isFalse);
    expect(
      store.sendFriendRequestByQuery('demo-ada'),
      FriendRequestActionResult.blocked,
    );

    store.reportUser('demo-deniz');
    expect(store.reportedUserIds.contains('demo-deniz'), isTrue);
  });

  test(
    'profile stats privacy is persisted and reflected in local profile',
    () async {
      final storage = _MemoryStorage(null);
      final store = CatudyDemoStore(storage: storage);

      await store.load();

      expect(store.publicStatsVisible, isTrue);
      expect(store.leaderboardProfiles.single.statsPublic, isTrue);

      store.updateSettings(
        name: store.displayName,
        apiUrl: store.apiBaseUrl,
        dnd: store.dndReminder,
        petNotifications: store.notifications,
        profileStatsVisible: false,
        language: store.languageCode,
        themeMode: store.themeModeCode,
      );

      expect(store.publicStatsVisible, isFalse);
      expect(store.leaderboardProfiles.single.statsPublic, isFalse);
      expect(storage.state?['publicStatsVisible'], isFalse);
    },
  );

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
    final store = CatudyDemoStore(
      storage: _MemoryStorage({'languageCode': 'tr'}),
    );

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
    final store = CatudyDemoStore(
      storage: _MemoryStorage({'languageCode': 'tr'}),
    );

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

  test('legacy records receive stable sync ids during restore', () async {
    final storage = _MemoryStorage({
      'categories': [
        {
          'id': 'study',
          'name': 'Study',
          'color': CatudyColors.violet.toARGB32(),
        },
      ],
      'history': [
        {
          'categoryId': 'study',
          'minutes': 25,
          'createdAt': DateTime(2026, 5, 1, 10).toIso8601String(),
          'manual': false,
          'note': 'Focus session',
          'gold': 25,
        },
      ],
      'todos': [
        {
          'id': 'todo-1',
          'title': 'Read',
          'date': DateTime(2026, 5, 2).toIso8601String(),
          'hour': 9,
          'minute': 0,
          'done': false,
        },
      ],
      'selectedCategoryId': 'study',
      'ownedItems': ['violet_collar'],
    });
    final store = CatudyDemoStore(storage: storage);

    await store.load();

    expect(store.history.single.id, startsWith('focus_'));
    expect(storage.state?['history'].single['id'], startsWith('focus_'));
    expect(storage.state?['history'].single['updatedAt'], isNotNull);
    expect(store.todos.single.updatedAt, DateTime(2026, 5, 2));
    expect(storage.state?['todos'].single['updatedAt'], isNotNull);
  });

  test('backup merge combines records and keeps latest scalar state', () {
    final oldTime = DateTime(2026, 5, 1, 10);
    final newTime = DateTime(2026, 5, 2, 10);
    final merged = mergeCatudyBackupStates(
      {
        'stateUpdatedAt': oldTime.toIso8601String(),
        'displayName': 'Local Cat',
        'history': [
          {
            'id': 'focus-a',
            'categoryId': 'study',
            'minutes': 20,
            'createdAt': oldTime.toIso8601String(),
            'updatedAt': oldTime.toIso8601String(),
            'manual': false,
            'note': 'Local',
            'gold': 20,
          },
        ],
        'todos': [],
        'categories': [],
        'friendRequests': [],
        'ownedItems': ['violet_collar'],
      },
      {
        'stateUpdatedAt': newTime.toIso8601String(),
        'displayName': 'Remote Cat',
        'history': [
          {
            'id': 'focus-a',
            'categoryId': 'study',
            'minutes': 30,
            'createdAt': oldTime.toIso8601String(),
            'updatedAt': newTime.toIso8601String(),
            'manual': false,
            'note': 'Remote',
            'gold': 30,
          },
          {
            'id': 'focus-b',
            'categoryId': 'math',
            'minutes': 15,
            'createdAt': newTime.toIso8601String(),
            'updatedAt': newTime.toIso8601String(),
            'manual': false,
            'note': 'Remote second',
            'gold': 15,
          },
        ],
        'todos': [],
        'categories': [],
        'friendRequests': [],
        'ownedItems': ['sunny_hat'],
      },
    );

    expect(merged['displayName'], 'Remote Cat');
    expect(merged['history'], hasLength(2));
    expect(
      (merged['history'] as List).firstWhere(
        (item) => item['id'] == 'focus-a',
      )['minutes'],
      30,
    );
    expect(merged['ownedItems'], containsAll(['violet_collar', 'sunny_hat']));
  });

  test(
    'premium entitlement unlocks coach and adds premium reward bonus',
    () async {
      final store = CatudyDemoStore(storage: _MemoryStorage(null));

      await store.load();
      store.activatePremiumDemo();

      expect(store.hasPremiumAccess, isTrue);
      expect(store.coachRecommendation.headline, isNotEmpty);

      store.activeSession = ActiveFocusSession(
        categoryId: 'study',
        durationMinutes: 20,
        startedAt: DateTime.now().subtract(const Duration(minutes: 20)),
        lobbyMode: false,
      );

      final record = store.completeFocus();

      expect(record.gold, 23);
      expect(store.gold, 23);
      expect(store.focusPoints, 20);
    },
  );

  test('coach personalizes after enough real focus history', () async {
    final now = DateTime.now();
    final store = CatudyDemoStore(
      storage: _MemoryStorage({
        'history': [
          {
            'categoryId': 'study',
            'minutes': 25,
            'createdAt': now
                .subtract(const Duration(days: 1))
                .toIso8601String(),
            'manual': false,
            'note': 'Focus session',
            'gold': 25,
          },
          {
            'categoryId': 'study',
            'minutes': 30,
            'createdAt': now
                .subtract(const Duration(days: 2))
                .toIso8601String(),
            'manual': false,
            'note': 'Focus session',
            'gold': 30,
          },
          {
            'categoryId': 'study',
            'minutes': 20,
            'createdAt': now
                .subtract(const Duration(days: 3))
                .toIso8601String(),
            'manual': false,
            'note': 'Focus session',
            'gold': 20,
          },
        ],
        'selectedCategoryId': 'study',
        'ownedItems': ['violet_collar'],
      }),
    );

    await store.load();

    final recommendation = store.coachRecommendation;

    expect(recommendation.basedOnHistory, isTrue);
    expect(recommendation.sessionsConsidered, 3);
  });

  test(
    'crates convert duplicate cosmetics into shards and advance pity',
    () async {
      final store = CatudyDemoStore(storage: _MemoryStorage(null));

      await store.load();
      store.crateInventory['cat_crate'] = 2;

      final first = store.openCrate('cat_crate', random: _FixedRandom());
      final second = store.openCrate('cat_crate', random: _FixedRandom());

      expect(first?.id, 'rainbow_scarf');
      expect(second?.id, 'rainbow_scarf');
      expect(store.ownedCosmeticIds.contains('rainbow_scarf'), isTrue);
      expect(store.shardWallet.shards, Rarity.common.shardValue);
      expect(store.pityStates['cat_crate']?.opensSinceRare, 2);
      expect(store.pityStates['cat_crate']?.opensSinceEpic, 2);
    },
  );

  test('season rewards respect free and premium tracks', () async {
    final store = CatudyDemoStore(storage: _MemoryStorage(null));

    await store.load();
    store.seasonProgress = store.seasonProgress.copyWith(focusMinutes: 720);

    expect(store.claimSeasonReward('free_cat_crate_120'), isTrue);
    expect(store.crateInventory['cat_crate'], 1);
    expect(store.claimSeasonReward('plus_style_crate_60'), isFalse);

    store.activatePremiumDemo();

    expect(store.claimSeasonReward('plus_style_crate_60'), isTrue);
    expect(store.crateInventory['style_crate'], 1);
  });

  test(
    'buddy pass is monthly for sender and once per receiver lifetime',
    () async {
      final sender = CatudyDemoStore(storage: _MemoryStorage(null));
      final receiver = CatudyDemoStore(storage: _MemoryStorage(null));

      await sender.load();
      await receiver.load();
      sender.activatePremiumDemo();

      final pass = await sender.createBuddyPass();

      expect(pass, isNotNull);
      expect(await sender.createBuddyPass(), isNull);
      expect(await receiver.redeemBuddyPass(pass!.code), isTrue);
      expect(receiver.hasPremiumAccess, isTrue);

      receiver.clearPremiumEntitlement();

      expect(await receiver.redeemBuddyPass('PLUS-SECOND12'), isFalse);
    },
  );

  test(
    'leaderboard profile uses real focus minutes as public metric',
    () async {
      final store = CatudyDemoStore(storage: _MemoryStorage(null));

      await store.load();
      store.focusPoints = 900;
      store.activeSession = ActiveFocusSession(
        categoryId: 'study',
        durationMinutes: 15,
        startedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        lobbyMode: false,
      );
      store.completeFocus();

      expect(store.leaderboardProfiles.single.points, greaterThan(15));
      expect(store.leaderboardProfiles.single.totalMinutes, 15);
    },
  );

  test('online premium state overrides local backup state', () async {
    final store = CatudyDemoStore(storage: _MemoryStorage(null));
    final now = DateTime.now();
    final service = _FakePremiumService(
      CatudyPremiumSnapshot(
        entitlement: PremiumEntitlement(
          source: PremiumSource.subscription,
          activatedAt: now,
          expiresAt: now.add(const Duration(days: 30)),
        ),
        issuedBuddyPasses: const [],
        redemption: const BuddyPassRedemption(code: '', redeemedAt: null),
        grantedCosmeticIds: const {},
      ),
    );

    await store.load();
    store.attachPremiumService(service);
    store.authUserId = 'premium-user';
    store.activatePremiumDemo(duration: const Duration(days: 1));
    store.attachPremiumService(service);
    await Future<void>.delayed(Duration.zero);

    expect(store.hasPremiumAccess, isTrue);
    expect(store.premiumEntitlement.source, PremiumSource.subscription);
    expect(
      store.premiumEntitlement.expiresAt,
      now.add(const Duration(days: 30)),
    );
  });

  test('online reward grants merge into owned cosmetics', () async {
    final store = CatudyDemoStore(storage: _MemoryStorage(null));
    final service = _FakePremiumService(
      const CatudyPremiumSnapshot(
        entitlement: PremiumEntitlement.inactive(),
        issuedBuddyPasses: [],
        redemption: BuddyPassRedemption(code: '', redeemedAt: null),
        grantedCosmeticIds: {'buddy_moon_pin'},
      ),
    );

    await store.load();
    store.attachPremiumService(service);
    store.authUserId = 'reward-user';
    store.attachPremiumService(service);
    await Future<void>.delayed(Duration.zero);

    expect(store.ownedCosmeticIds, contains('buddy_moon_pin'));
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
  Future<List<CatudyOnlineLeaderboardProfile>> fetchTopProfiles() async {
    return const [];
  }

  @override
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

class _FakePremiumService extends CatudyPremiumService {
  _FakePremiumService(this.snapshot) : super(_testSupabaseClient());

  CatudyPremiumSnapshot snapshot;

  @override
  Future<CatudyPremiumSnapshot?> fetchCurrentState() async => snapshot;

  @override
  Future<BuddyPass?> createBuddyPass() async {
    final pass = BuddyPass(
      code: 'PLUS-FAKE1234',
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      redeemedByUserId: null,
      redeemedAt: null,
    );
    snapshot = CatudyPremiumSnapshot(
      entitlement: snapshot.entitlement,
      issuedBuddyPasses: [...snapshot.issuedBuddyPasses, pass],
      redemption: snapshot.redemption,
      grantedCosmeticIds: snapshot.grantedCosmeticIds,
    );
    return pass;
  }

  @override
  Future<bool> redeemBuddyPass(String code) async => code == 'PLUS-FAKE1234';
}

class _FixedRandom implements Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0.95;

  @override
  int nextInt(int max) => 0;
}

SupabaseClient _testSupabaseClient() {
  return SupabaseClient('http://127.0.0.1:54321', 'test-anon-key');
}
