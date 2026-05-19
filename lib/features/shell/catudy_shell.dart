import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../../app/catudy_assets.dart';
import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/store_builder.dart';

class CatudyShell extends StatefulWidget {
  const CatudyShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  State<CatudyShell> createState() => _CatudyShellState();
}

class _CatudyShellState extends State<CatudyShell> {
  bool _exitDialogOpen = false;
  bool _celebrationDrainScheduled = false;
  Timer? _celebrationTimer;
  CatudyCelebration? _celebration;

  static const _paths = ['/', '/stats', '/calendar', '/pet-room', '/profile'];
  static final Map<int, String> _lastPathByIndex = {
    for (var i = 0; i < _paths.length; i++) i: _paths[i],
  };
  static const _items = [
    _NavItem(
      labelKey: 'nav.home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _NavItem(
      labelKey: 'nav.stats',
      icon: Icons.query_stats_outlined,
      activeIcon: Icons.query_stats_rounded,
    ),
    _NavItem(
      labelKey: 'nav.calendar',
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
    ),
    _NavItem(
      labelKey: 'nav.pet',
      icon: Icons.pets_outlined,
      activeIcon: Icons.pets_rounded,
    ),
    _NavItem(
      labelKey: 'nav.profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    catudyDemoStore.addListener(_handleStoreChange);
    _scheduleCelebrationDrain();
  }

  @override
  void dispose() {
    catudyDemoStore.removeListener(_handleStoreChange);
    _celebrationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = _pathOnly(widget.location);
    final selectedIndex = _selectedIndex(currentPath);
    _rememberLocation(selectedIndex, widget.location);
    final dark = CatudyColors.isDark(context);

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        if (context.canPop()) {
          context.pop();
          return;
        }
        final target = _backTarget(currentPath);
        if (target == null) {
          unawaited(_confirmAndExit(context));
          return;
        }
        context.go(target);
      },
      child: Scaffold(
        body: Stack(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    CatudyColors.paperFor(context),
                    CatudyColors.surfaceFor(context),
                    CatudyColors.surfaceStrongFor(context),
                  ],
                ),
              ),
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: widget.child,
                  ),
                ),
              ),
            ),
            if (_celebration != null)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 10,
                left: 14,
                right: 14,
                child: IgnorePointer(
                  child: Center(
                    child: _CelebrationBubble(celebration: _celebration!),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: CatudyColors.teal.withValues(alpha: dark ? 0.22 : 0.16),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: (dark ? Colors.black : CatudyColors.violet).withValues(
                  alpha: dark ? 0.28 : 0.10,
                ),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Container(
            color: CatudyColors.surfaceFor(context).withValues(alpha: 0.96),
            child: SizedBox(
              height: 78,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: SizedBox(
                    height: 72,
                    child: Row(
                      children: [
                        for (var index = 0; index < _items.length; index++)
                          Expanded(
                            child: _CatudyNavButton(
                              item: _items[index],
                              selected: selectedIndex == index,
                              isPet: index == 3,
                              onTap: () {
                                final focusRoute = index == 0
                                    ? catudyDemoStore
                                          .consumeFocusNavigationRoute()
                                    : null;
                                final target =
                                    focusRoute ??
                                    _lastPathByIndex[index] ??
                                    _paths[index];
                                if (index == 3 &&
                                    _pathOnly(target) == '/pet-room') {
                                  catudyDemoStore.clearVisitedRoom();
                                }
                                context.go(target);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleStoreChange() {
    _scheduleCelebrationDrain();
  }

  void _scheduleCelebrationDrain() {
    if (_celebrationDrainScheduled) {
      return;
    }
    _celebrationDrainScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _celebrationDrainScheduled = false;
      if (!mounted) {
        return;
      }
      _showNextCelebration();
    });
  }

  void _showNextCelebration() {
    if (_celebration != null) {
      return;
    }
    final next = catudyDemoStore.takePendingCelebration();
    if (next == null) {
      return;
    }
    _celebrationTimer?.cancel();
    setState(() => _celebration = next);
    _celebrationTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      setState(() => _celebration = null);
      _scheduleCelebrationDrain();
    });
  }

  String _pathOnly(String location) {
    final uri = Uri.tryParse(location);
    return uri?.path.isNotEmpty == true ? uri!.path : location;
  }

  void _rememberLocation(int index, String location) {
    final path = _pathOnly(location);
    if (path == '/auth' || path.startsWith('/focus/')) {
      return;
    }
    _lastPathByIndex[index] = location;
  }

  Future<void> _confirmAndExit(BuildContext context) async {
    if (_exitDialogOpen) {
      return;
    }
    _exitDialogOpen = true;
    final store = catudyDemoStore;
    final shouldExit =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(store.t('app.exitTitle')),
            content: Text(store.t('app.exitBody')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(store.t('common.cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(store.t('common.exit')),
              ),
            ],
          ),
        ) ??
        false;
    _exitDialogOpen = false;
    if (!mounted || !shouldExit) {
      return;
    }
    SystemNavigator.pop();
  }

  String? _backTarget(String path) {
    if (path == '/') {
      return null;
    }
    if (path.startsWith('/shop') || path.startsWith('/inventory')) {
      return '/pet-room';
    }
    if (path.startsWith('/season') || path.startsWith('/crates')) {
      return '/plus';
    }
    if (path.startsWith('/plus')) {
      return '/profile';
    }
    if (path.startsWith('/settings') || path.startsWith('/public-profile')) {
      return '/profile';
    }
    if (path.startsWith('/manual-entry')) {
      return '/calendar';
    }
    if (path.startsWith('/focus/start')) {
      return '/';
    }
    if (path.startsWith('/focus/duration')) {
      return '/focus/category';
    }
    if (path.startsWith('/focus/timer')) {
      return '/focus/start';
    }
    if (path.startsWith('/focus/result')) {
      return '/';
    }
    if (path.startsWith('/lobby/create') || path.startsWith('/lobby/join')) {
      return '/community?tab=lobbies';
    }
    if (path.startsWith('/lobby/room')) {
      return '/community?tab=lobbies';
    }
    return '/';
  }

  int _selectedIndex(String path) {
    if (path.startsWith('/stats')) {
      return 1;
    }
    if (path.startsWith('/calendar') || path.startsWith('/manual-entry')) {
      return 2;
    }
    if (path.startsWith('/pet-room') ||
        path.startsWith('/shop') ||
        path.startsWith('/inventory') ||
        path.startsWith('/crates')) {
      return 3;
    }
    if (path.startsWith('/profile') ||
        path.startsWith('/settings') ||
        path.startsWith('/public-profile')) {
      return 4;
    }
    return 0;
  }
}

class _CelebrationBubble extends StatelessWidget {
  const _CelebrationBubble({required this.celebration});

  final CatudyCelebration celebration;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: CatudyColors.surfaceFor(context).withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: CatudyColors.teal.withValues(alpha: 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: CatudyColors.teal.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(celebration.icon, color: CatudyColors.teal),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      celebration.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: CatudyColors.blueFor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      celebration.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: CatudyColors.mutedFor(context),
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatudyNavButton extends StatelessWidget {
  const _CatudyNavButton({
    required this.item,
    required this.selected,
    required this.isPet,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final bool isPet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? CatudyColors.teal : CatudyColors.mutedFor(context);

    return StoreBuilder(
      builder: (context, store) => Semantics(
        button: true,
        selected: selected,
        label: store.t(item.labelKey),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            decoration: BoxDecoration(
              color: selected
                  ? CatudyColors.teal.withValues(alpha: 0.18)
                  : Colors.transparent,
              border: selected
                  ? Border.all(color: CatudyColors.teal.withValues(alpha: 0.30))
                  : null,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: isPet
                  ? _PetNavIcon(selected: selected)
                  : Icon(
                      selected ? item.activeIcon : item.icon,
                      color: color,
                      size: selected ? 34 : 31,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PetNavIcon extends StatelessWidget {
  const _PetNavIcon({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        final accent = store.selectedPet.accent;
        return Container(
          width: selected ? 44 : 40,
          height: selected ? 44 : 40,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: selected ? 0.22 : 0.10),
            shape: BoxShape.circle,
            border: Border.all(
              color: accent.withValues(alpha: selected ? 0.42 : 0.18),
            ),
          ),
          child: Image.asset(CatudyAssets.mascot, fit: BoxFit.contain),
        );
      },
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.labelKey,
    required this.icon,
    required this.activeIcon,
  });

  final String labelKey;
  final IconData icon;
  final IconData activeIcon;
}
