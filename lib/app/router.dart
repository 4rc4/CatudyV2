import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/calendar/calendar_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/calendar/manual_entry_screen.dart';
import '../features/focus/category_screen.dart';
import '../features/focus/duration_screen.dart';
import '../features/focus/session_result_screen.dart';
import '../features/focus/timer_screen.dart';
import '../features/home/home_screen.dart';
import '../features/leaderboard/leaderboard_screen.dart';
import '../features/lobby/lobby_screen.dart';
import '../features/pet/pet_room_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/public_profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/catudy_shell.dart';
import '../features/shop/inventory_screen.dart';
import '../features/shop/shop_screen.dart';
import '../features/stats/stats_screen.dart';

class CatudyRouter {
  const CatudyRouter._();

  static GoRouter createRouter({
    String initialLocation = '/',
    GlobalKey<NavigatorState>? navigatorKey,
  }) => GoRouter(
    initialLocation: initialLocation,
    navigatorKey: navigatorKey,
    routes: [
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) =>
            _animatedPage(state, const AuthScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return CatudyShell(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                _animatedPage(state, const HomeScreen()),
          ),
          GoRoute(
            path: '/stats',
            pageBuilder: (context, state) =>
                _animatedPage(state, const StatsScreen()),
          ),
          GoRoute(
            path: '/calendar',
            pageBuilder: (context, state) =>
                _animatedPage(state, const CalendarScreen()),
          ),
          GoRoute(
            path: '/leaderboard',
            pageBuilder: (context, state) =>
                _animatedPage(state, const LeaderboardScreen()),
          ),
          GoRoute(
            path: '/pet-room',
            pageBuilder: (context, state) =>
                _animatedPage(state, const PetRoomScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                _animatedPage(state, const ProfileScreen()),
          ),
          GoRoute(
            path: '/focus/category',
            pageBuilder: (context, state) =>
                _animatedPage(state, const CategoryScreen()),
          ),
          GoRoute(
            path: '/focus/duration',
            pageBuilder: (context, state) =>
                _animatedPage(state, const DurationScreen()),
          ),
          GoRoute(
            path: '/focus/timer',
            pageBuilder: (context, state) =>
                _animatedPage(state, const TimerScreen()),
          ),
          GoRoute(
            path: '/focus/result',
            pageBuilder: (context, state) =>
                _animatedPage(state, const SessionResultScreen()),
          ),
          GoRoute(
            path: '/lobby',
            pageBuilder: (context, state) =>
                _animatedPage(state, const LobbyScreen()),
          ),
          GoRoute(
            path: '/lobby/create',
            pageBuilder: (context, state) =>
                _animatedPage(state, const LobbyCreateScreen()),
          ),
          GoRoute(
            path: '/lobby/join',
            pageBuilder: (context, state) =>
                _animatedPage(state, const LobbyJoinScreen()),
          ),
          GoRoute(
            path: '/lobby/room',
            pageBuilder: (context, state) =>
                _animatedPage(state, const LobbyRoomScreen()),
          ),
          GoRoute(
            path: '/manual-entry',
            pageBuilder: (context, state) =>
                _animatedPage(state, const ManualEntryScreen()),
          ),
          GoRoute(
            path: '/shop',
            pageBuilder: (context, state) =>
                _animatedPage(state, const ShopScreen()),
          ),
          GoRoute(
            path: '/inventory',
            pageBuilder: (context, state) =>
                _animatedPage(state, const InventoryScreen()),
          ),
          GoRoute(
            path: '/public-profile',
            pageBuilder: (context, state) =>
                _animatedPage(state, const PublicProfileScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                _animatedPage(state, const SettingsScreen()),
          ),
        ],
      ),
    ],
  );

  static final router = createRouter();
}

CustomTransitionPage<void> _animatedPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}
