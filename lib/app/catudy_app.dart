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

class _CatudyAppState extends State<CatudyApp> with WidgetsBindingObserver {
  final _rootNavigatorKey = GlobalKey<NavigatorState>();

  late final _router = CatudyRouter.createRouter(
    initialLocation: widget.initialLocation,
    navigatorKey: _rootNavigatorKey,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    catudyDemoStore.load().then((_) {
      if (!mounted) {
        return;
      }
      if (catudyDemoStore.needsTermsAcceptance) {
        _showTermsIfNeeded();
        return;
      }
      _continueStartup();
    });
  }

  void _continueStartup() {
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
  }

  void _showTermsIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !catudyDemoStore.needsTermsAcceptance) {
        return;
      }
      final navigatorContext = _rootNavigatorKey.currentContext;
      if (navigatorContext == null) {
        return;
      }
      final accepted =
          await showDialog<bool>(
            context: navigatorContext,
            barrierDismissible: false,
            builder: (_) => const _TermsAgreementDialog(),
          ) ??
          false;
      if (!mounted || !accepted) {
        _showTermsIfNeeded();
        return;
      }
      catudyDemoStore.acceptTerms();
      _continueStartup();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      catudyDemoStore.refreshActiveFocusState();
    }
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
      showFirstRunOnboarding(navigatorContext, router: _router);
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
        supportedLocales: CatudyDemoStore.supportedLanguageCodes
            .map((code) => Locale(code))
            .toList(growable: false),
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

class _TermsAgreementDialog extends StatefulWidget {
  const _TermsAgreementDialog();

  @override
  State<_TermsAgreementDialog> createState() => _TermsAgreementDialogState();
}

class _TermsAgreementDialogState extends State<_TermsAgreementDialog> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final store = catudyDemoStore;
    return AlertDialog(
      title: Text(store.t('terms.title')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(store.t('terms.intro')),
            const SizedBox(height: 12),
            _TermsBullet(text: store.t('terms.bulletAge')),
            _TermsBullet(text: store.t('terms.bulletData')),
            _TermsBullet(text: store.t('terms.bulletContent')),
            _TermsBullet(text: store.t('terms.bulletFairUse')),
            _TermsBullet(text: store.t('terms.bulletDeletion')),
            const SizedBox(height: 10),
            CheckboxListTile(
              value: _checked,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) => setState(() => _checked = value ?? false),
              title: Text(
                store.t('terms.acceptCheck'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: _checked ? () => Navigator.of(context).pop(true) : null,
          child: Text(store.t('terms.accept')),
        ),
      ],
    );
  }
}

class _TermsBullet extends StatelessWidget {
  const _TermsBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
