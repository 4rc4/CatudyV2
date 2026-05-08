import 'package:catudy_app/app/demo/catudy_demo_store.dart';
import 'package:catudy_app/app/storage/catudy_local_storage.dart';
import 'package:catudy_app/app/theme/catudy_colors.dart';
import 'package:flutter_test/flutter_test.dart';

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
