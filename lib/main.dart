import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/ads/catudy_ads.dart';
import 'app/catudy_app.dart';
import 'app/demo/catudy_demo_store.dart';
import 'app/notifications/catudy_notification_service.dart';
import 'app/online/catudy_auth_service.dart';
import 'app/online/catudy_backup_service.dart';
import 'app/online/catudy_leaderboard_service.dart';
import 'app/online/catudy_lobby_service.dart';
import 'app/online/catudy_premium_service.dart';
import 'app/online/catudy_social_service.dart';
import 'app/update/catudy_update_service.dart';
import 'app/update/catudy_update_dialog.dart';

const _supabaseUrl = bool.hasEnvironment('CATUDY_SUPABASE_URL')
    ? String.fromEnvironment('CATUDY_SUPABASE_URL')
    : String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = bool.hasEnvironment('CATUDY_SUPABASE_ANON_KEY')
    ? String.fromEnvironment('CATUDY_SUPABASE_ANON_KEY')
    : String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(initializeCatudyAds());
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
  catudyDemoStore.configurePetCareNotifications(
    onPetCareAlert: (alertType, languageCode) {
      CatudyNotificationService.instance.showPetCareNotification(
        alertType: alertType,
        languageCode: languageCode,
      );
    },
  );
  catudyDemoStore.configureNotificationSync(_scheduleLocalizedNotifications);
  await _initializeOnlineLobby();
  await _scheduleLocalizedNotifications();
  runApp(
    ProviderScope(
      child: CatudyApp(
        initialLocation: _initialLocation(),
        onAppReady: _checkForUpdate,
      ),
    ),
  );
}

/// Called after the first frame is rendered so the navigator is available.
Future<void> _checkForUpdate(BuildContext context) async {
  try {
    final info = await CatudyUpdateService.instance.checkForUpdate();
    if (info == null) return;
    if (!context.mounted) return;
    await showCatudyUpdateDialog(context, info);
  } catch (e) {
    debugPrint('Update check error: $e');
  }
}

String _initialLocation() {
  if (!kIsWeb) {
    return '/';
  }

  final uri = Uri.base;
  final path = uri.path.isEmpty ? '/' : uri.path;
  final query = uri.hasQuery ? '?${uri.query}' : '';
  return '$path$query';
}

Future<void> _scheduleLocalizedNotifications() async {
  final store = catudyDemoStore;
  await CatudyNotificationService.instance.schedulePendingReminders(
    store.todos,
    languageCode: store.languageCode,
  );
  await CatudyNotificationService.instance.scheduleDailyGoalReminder(
    hour: store.dailyGoalReminderHour,
    minute: store.dailyGoalReminderMinute,
    languageCode: store.languageCode,
    enabled: store.notifications && store.dailyGoalReminderEnabled,
  );
  final activeSession = store.activeSession;
  if (store.notifications && activeSession != null) {
    await CatudyNotificationService.instance.scheduleFocusCompleteNotification(
      session: activeSession,
      languageCode: store.languageCode,
    );
    return;
  }
  await CatudyNotificationService.instance.cancelFocusCompleteNotification();
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
    catudyDemoStore.attachBackupService(
      CatudyBackupService(Supabase.instance.client),
    );
    catudyDemoStore.attachLobbyService(
      CatudySupabaseLobbyService(Supabase.instance.client),
    );
    catudyDemoStore.attachLeaderboardService(
      CatudyLeaderboardService(Supabase.instance.client),
    );
    catudyDemoStore.attachPremiumService(
      CatudyPremiumService(Supabase.instance.client),
    );
    catudyDemoStore.attachSocialService(
      CatudySocialService(Supabase.instance.client),
    );
  } catch (error) {
    debugPrint('Catudy Supabase initialization failed: $error');
  }
}
