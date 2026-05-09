import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/catudy_app.dart';
import 'app/demo/catudy_demo_store.dart';
import 'app/notifications/catudy_notification_service.dart';
import 'app/online/catudy_auth_service.dart';
import 'app/online/catudy_leaderboard_service.dart';
import 'app/online/catudy_lobby_service.dart';
import 'app/online/catudy_social_service.dart';

const _supabaseUrl = String.fromEnvironment('CATUDY_SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('CATUDY_SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await catudyDemoStore.load();
  await CatudyNotificationService.instance.initialize();
  catudyDemoStore.configureSocialNotifications(
    onFriendRequest: (name, languageCode) {
      CatudyNotificationService.instance.showFriendRequestNotification(
        name: name,
        languageCode: languageCode,
      );
    },
  );
  await _initializeOnlineLobby();
  await CatudyNotificationService.instance.schedulePendingReminders(
    catudyDemoStore.todos,
    languageCode: catudyDemoStore.languageCode,
  );
  await CatudyNotificationService.instance.scheduleDailyGoalReminder(
    hour: catudyDemoStore.dailyGoalReminderHour,
    minute: catudyDemoStore.dailyGoalReminderMinute,
    languageCode: catudyDemoStore.languageCode,
    enabled:
        catudyDemoStore.notifications &&
        catudyDemoStore.dailyGoalReminderEnabled,
  );
  runApp(const ProviderScope(child: CatudyApp()));
}

Future<void> _initializeOnlineLobby() async {
  if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
    return;
  }
  try {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
    catudyDemoStore.attachAuthService(
      CatudyAuthService(Supabase.instance.client),
    );
    catudyDemoStore.attachLobbyService(
      CatudySupabaseLobbyService(Supabase.instance.client),
    );
    catudyDemoStore.attachLeaderboardService(
      CatudyLeaderboardService(Supabase.instance.client),
    );
    catudyDemoStore.attachSocialService(
      CatudySocialService(Supabase.instance.client),
    );
  } catch (error) {
    debugPrint('Catudy Supabase initialization failed: $error');
  }
}
