import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'demo/catudy_demo_store.dart';
import 'router.dart';
import 'theme/catudy_theme.dart';
import '../features/onboarding/pet_intro_tour.dart';

class CatudyApp extends StatefulWidget {
  const CatudyApp({this.initialLocation = '/', super.key});

  final String initialLocation;

  @override
  State<CatudyApp> createState() => _CatudyAppState();
}

class _CatudyAppState extends State<CatudyApp> {
  final _rootNavigatorKey = GlobalKey<NavigatorState>();

  late final _router = CatudyRouter.createRouter(
    initialLocation: widget.initialLocation,
    navigatorKey: _rootNavigatorKey,
  );

  @override
  void initState() {
    super.initState();
    catudyDemoStore.load().then((_) {
      if (!mounted) {
        return;
      }
      if (widget.initialLocation == '/' && catudyDemoStore.needsAuth) {
        _router.go('/auth');
        return;
      }
      final route = widget.initialLocation == '/'
          ? catudyDemoStore.consumeInitialRestoreRoute()
          : null;
      if (route != null) {
        _router.go(route);
        return;
      }
      _showIntroIfNeeded();
    });
  }

  void _showIntroIfNeeded() {
    if (widget.initialLocation != '/' || catudyDemoStore.introTourSeen) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || catudyDemoStore.introTourSeen) {
        return;
      }
      final navigatorContext = _rootNavigatorKey.currentContext;
      if (navigatorContext == null) {
        return;
      }
      showPetIntroTour(navigatorContext, router: _router);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: catudyDemoStore,
      builder: (context, _) => MaterialApp.router(
        title: 'Catudy',
        debugShowCheckedModeBanner: false,
        theme: CatudyTheme.light(),
        darkTheme: CatudyTheme.dark(),
        themeMode: switch (catudyDemoStore.themeModeCode) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        },
        locale: Locale(catudyDemoStore.languageCode),
        supportedLocales: const [Locale('tr'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: _router,
      ),
    );
  }
}
