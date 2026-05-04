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
    await _requestPermissions();
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
    await _plugin.zonedSchedule(
      id: _notificationId(todo),
      title: languageCode == 'en' ? 'Catudy reminder' : 'Catudy hatırlatma',
      body: todo.title,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'catudy_reminders',
          'Catudy Reminders',
          channelDescription: 'Planned study reminders from Catudy',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
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

  Future<void> cancelReminder(CalendarTodo todo) async {
    await initialize();
    await _plugin.cancel(id: _notificationId(todo));
  }

  Future<void> _requestPermissions() async {
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
}
