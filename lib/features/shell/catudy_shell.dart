import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../../app/catudy_assets.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/store_builder.dart';

class CatudyShell extends StatelessWidget {
  const CatudyShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  static const _paths = ['/', '/stats', '/calendar', '/pet-room', '/profile'];
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
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(location);
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
        final target = _backTarget(location);
        if (target == null) {
          SystemNavigator.pop();
          return;
        }
        context.go(target);
      },
      child: Scaffold(
        body: DecoratedBox(
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
                child: child,
              ),
            ),
          ),
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
                              onTap: () => context.go(_paths[index]),
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

  String? _backTarget(String path) {
    if (path == '/') {
      return null;
    }
    if (path.startsWith('/shop') || path.startsWith('/inventory')) {
      return '/pet-room';
    }
    if (path.startsWith('/settings') || path.startsWith('/public-profile')) {
      return '/profile';
    }
    if (path.startsWith('/manual-entry')) {
      return '/calendar';
    }
    if (path.startsWith('/focus/duration')) {
      return '/focus/category';
    }
    if (path.startsWith('/focus/timer')) {
      return '/focus/duration';
    }
    if (path.startsWith('/focus/result')) {
      return '/';
    }
    if (path.startsWith('/lobby/create') || path.startsWith('/lobby/join')) {
      return '/lobby';
    }
    if (path.startsWith('/lobby/room')) {
      return '/lobby';
    }
    return '/';
  }

  int _selectedIndex(String path) {
    if (path.startsWith('/stats')) {
      return 1;
    }
    if (path.startsWith('/calendar')) {
      return 2;
    }
    if (path.startsWith('/pet-room') ||
        path.startsWith('/shop') ||
        path.startsWith('/inventory')) {
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
