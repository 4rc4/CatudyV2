import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../demo/catudy_demo_store.dart';

class CatudyNotificationService {
  CatudyNotificationService._();

  static final instance = CatudyNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _permissionsRequested = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    tz.initializeTimeZones();
    try {
      final localInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<void> scheduleReminder(
    CalendarTodo todo, {
    required String languageCode,
  }) async {
    await initialize();
    if (todo.done) {
      await cancelReminder(todo);
      return;
    }
    final when = todo.scheduledAt;
    if (!when.isAfter(DateTime.now())) {
      return;
    }
    await requestPermissions();
    await _plugin.zonedSchedule(
      id: _notificationId(todo),
      title: _isEnglish(languageCode) ? 'Catudy reminder' : 'Catudy hatırlatma',
      body: todo.title,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: NotificationDetails(
        android: _androidDetails(
          channelId: 'catudy_reminders',
          languageCode: languageCode,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> schedulePendingReminders(
    Iterable<CalendarTodo> todos, {
    required String languageCode,
  }) async {
    await initialize();
    for (final todo in todos) {
      await scheduleReminder(todo, languageCode: languageCode);
    }
  }

  Future<void> scheduleDailyGoalReminder({
    required int hour,
    required int minute,
    required String languageCode,
    required bool enabled,
  }) async {
    await initialize();
    const id = 900001;
    await _plugin.cancel(id: id);
    if (!enabled) {
      return;
    }
    await requestPermissions();
    var next = DateTime.now();
    next = DateTime(next.year, next.month, next.day, hour, minute);
    if (!next.isAfter(DateTime.now())) {
      next = next.add(const Duration(days: 1));
    }
    final english = _isEnglish(languageCode);
    await _plugin.zonedSchedule(
      id: id,
      title: english ? 'Daily focus target' : 'Günlük odak hedefi',
      body: english
          ? 'Check your remaining focus minutes for today.'
          : 'Bugün kalan odak dakikalarını kontrol et.',
      scheduledDate: tz.TZDateTime.from(next, tz.local),
      notificationDetails: NotificationDetails(
        android: _androidDetails(
          channelId: 'catudy_goals',
          languageCode: languageCode,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleFocusCompleteNotification({
    required ActiveFocusSession session,
    required String languageCode,
  }) async {
    await initialize();
    const id = 900002;
    await _plugin.cancel(id: id);
    if (session.isPaused) {
      return;
    }
    final endAt = session.plannedEndAt;
    if (!endAt.isAfter(DateTime.now())) {
      return;
    }
    await requestPermissions();
    final english = _isEnglish(languageCode);
    await _plugin.zonedSchedule(
      id: id,
      title: session.lobbyMode
          ? (english ? 'Lobby focus complete' : 'Lobi odağı tamamlandı')
          : (english ? 'Focus complete' : 'Odak tamamlandı'),
      body: english
          ? 'Your session is done. Open Catudy to see the result.'
          : "Seansın bitti. Sonucu görmek için Catudy'yi aç.",
      scheduledDate: tz.TZDateTime.from(endAt, tz.local),
      notificationDetails: NotificationDetails(
        android: _androidDetails(
          channelId: 'catudy_focus',
          languageCode: languageCode,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelFocusCompleteNotification() async {
    await initialize();
    await _plugin.cancel(id: 900002);
  }

  Future<void> schedulePetCareReminders({
    required String languageCode,
    required bool enabled,
  }) async {
    await initialize();
    final reminders = _petCareReminders(languageCode);
    for (final reminder in reminders) {
      await _plugin.cancel(id: reminder.id);
    }
    if (!enabled) {
      return;
    }
    await requestPermissions();
    for (final reminder in reminders) {
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: _nextDailyTime(reminder.hour, reminder.minute),
        notificationDetails: NotificationDetails(
          android: _androidDetails(
            channelId: 'catudy_pet',
            languageCode: languageCode,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> showFriendRequestNotification({
    required String name,
    required String languageCode,
  }) async {
    await initialize();
    await requestPermissions();
    final english = _isEnglish(languageCode);
    await _plugin.show(
      id: 910001,
      title: english ? 'New friend request' : 'Yeni arkadaşlık isteği',
      body: english
          ? '$name sent you a friend request.'
          : '$name sana arkadaşlık isteği gönderdi.',
      notificationDetails: NotificationDetails(
        android: _androidDetails(
          channelId: 'catudy_social',
          languageCode: languageCode,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> showLobbyInviteNotification({
    required String code,
    required String languageCode,
  }) async {
    await initialize();
    await requestPermissions();
    final english = _isEnglish(languageCode);
    await _plugin.show(
      id: 910002,
      title: english ? 'Lobby invite ready' : 'Lobi daveti hazır',
      body: english
          ? 'Share lobby code $code with a friend.'
          : '$code lobi kodunu bir arkadaşınla paylaş.',
      notificationDetails: NotificationDetails(
        android: _androidDetails(
          channelId: 'catudy_social',
          languageCode: languageCode,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> showPetCareNotification({
    required String alertType,
    required String languageCode,
  }) async {
    await initialize();
    await requestPermissions();
    final english = _isEnglish(languageCode);
    final title = english ? 'Cat update' : 'Kedi bildirimi';
    final body = switch (alertType) {
      'happiness' =>
        english
            ? 'Your cat feels low. A real focus streak will help.'
            : 'Kedin biraz durgun. Gercek odak serisi iyi gelir.',
      'hunger' =>
        english
            ? 'Your cat needs attention. Focus today to refill the routine.'
            : 'Kedin ilgi istiyor. Bugun odaklanip ritmi doldur.',
      'energy_full' =>
        english
            ? 'Your cat is rested and ready for a new focus session.'
            : 'Kedin dinlendi ve yeni odak seansina hazir.',
      _ => english ? 'Open Catudy to check your pet.' : 'Petini kontrol et.',
    };
    await _plugin.show(
      id: switch (alertType) {
        'happiness' => 920001,
        'hunger' => 920002,
        'energy_full' => 920003,
        _ => 920000,
      },
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: _androidDetails(
          channelId: 'catudy_pet',
          languageCode: languageCode,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelReminder(CalendarTodo todo) async {
    await initialize();
    await _plugin.cancel(id: _notificationId(todo));
  }

  Future<void> requestPermissions() async {
    await initialize();
    if (_permissionsRequested) {
      return;
    }
    _permissionsRequested = true;
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  int _notificationId(CalendarTodo todo) {
    final parsed = int.tryParse(todo.id);
    return (parsed ?? todo.id.hashCode) & 0x7fffffff;
  }

  tz.TZDateTime _nextDailyTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  AndroidNotificationDetails _androidDetails({
    required String channelId,
    required String languageCode,
    required Importance importance,
    required Priority priority,
  }) {
    final english = _isEnglish(languageCode);
    return AndroidNotificationDetails(
      '${channelId}_${english ? 'en' : 'tr'}',
      _channelName(channelId, english),
      channelDescription: _channelDescription(channelId, english),
      importance: importance,
      priority: priority,
    );
  }

  bool _isEnglish(String languageCode) => languageCode == 'en';

  String _channelName(String channelId, bool english) {
    if (english) {
      return switch (channelId) {
        'catudy_goals' => 'Catudy Goals',
        'catudy_social' => 'Catudy Social',
        'catudy_focus' => 'Catudy Focus',
        'catudy_pet' => 'Catudy Pet',
        _ => 'Catudy Reminders',
      };
    }
    return switch (channelId) {
      'catudy_goals' => 'Catudy Hedefleri',
      'catudy_social' => 'Catudy Sosyal',
      'catudy_focus' => 'Catudy Odak',
      'catudy_pet' => 'Catudy Pet',
      _ => 'Catudy Hatırlatmaları',
    };
  }

  String _channelDescription(String channelId, bool english) {
    if (english) {
      return switch (channelId) {
        'catudy_goals' => 'Daily focus target reminders from Catudy',
        'catudy_social' => 'Social updates from Catudy',
        'catudy_focus' => 'Focus session updates from Catudy',
        'catudy_pet' => 'Pet care updates from Catudy',
        _ => 'Study reminders from Catudy',
      };
    }
    return switch (channelId) {
      'catudy_goals' => 'Catudy günlük odak hedefi hatırlatmaları',
      'catudy_social' => 'Catudy sosyal güncellemeleri',
      'catudy_focus' => 'Catudy odak seansı güncellemeleri',
      'catudy_pet' => 'Catudy pet bakım bildirimleri',
      _ => 'Catudy çalışma hatırlatmaları',
    };
  }
}

class _PetCareReminder {
  const _PetCareReminder({
    required this.id,
    required this.hour,
    required this.minute,
    required this.title,
    required this.body,
  });

  final int id;
  final int hour;
  final int minute;
  final String title;
  final String body;
}

List<_PetCareReminder> _petCareReminders(String languageCode) {
  final english = languageCode == 'en';
  return [
    _PetCareReminder(
      id: 920101,
      hour: 13,
      minute: 0,
      title: english ? 'Cat update' : 'Kedi bildirimi',
      body: english
          ? 'Your cat is waiting for a quick check-in.'
          : 'Kedin kısa bir kontrol bekliyor.',
    ),
    _PetCareReminder(
      id: 920102,
      hour: 20,
      minute: 30,
      title: english ? 'Focus care time' : 'Odak bakım zamanı',
      body: english
          ? 'A real focus session keeps your cat balanced.'
          : 'Gerçek bir odak seansı kedinin ritmini dengeler.',
    ),
  ];
}
