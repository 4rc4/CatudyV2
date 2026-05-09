import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../features/onboarding/pet_intro_tour.dart';

class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({
    required this.title,
    required this.children,
    this.actions = const [],
    this.showBack = false,
    this.fallbackBackPath = '/',
    this.showSettingsAction = true,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final List<Widget> actions;
  final bool showBack;
  final String fallbackBackPath;
  final bool showSettingsAction;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showBack) ...[
                IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(fallbackBackPath);
                    }
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: CatudyColors.blueFor(context),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: CatudyColors.blueFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ...actions,
              const SizedBox(width: 4),
              IconButton.filledTonal(
                onPressed: () => showPetIntroTour(context),
                tooltip: catudyDemoStore.t('pet.showTour'),
                icon: const Icon(Icons.info_rounded),
              ),
              const SizedBox(width: 4),
              if (showSettingsAction)
                IconButton.filledTonal(
                  onPressed: () => context.go('/settings'),
                  tooltip: catudyDemoStore.t('pet.settings'),
                  icon: const Icon(Icons.settings_rounded),
                ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}
