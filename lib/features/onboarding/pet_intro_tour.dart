import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/floating_mascot.dart';

Future<void> showFirstRunOnboarding(
  BuildContext context, {
  required GoRouter router,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  return showDialog<void>(
    context: navigator.context,
    barrierDismissible: false,
    builder: (context) => _FirstRunOnboarding(router: router),
  );
}

class _FirstRunOnboarding extends StatefulWidget {
  const _FirstRunOnboarding({required this.router});

  final GoRouter router;

  @override
  State<_FirstRunOnboarding> createState() => _FirstRunOnboardingState();
}

class _FirstRunOnboardingState extends State<_FirstRunOnboarding> {
  late final TextEditingController _nameController;
  late final TextEditingController _goalController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: catudyDemoStore.displayName);
    _goalController = TextEditingController(
      text: '${catudyDemoStore.dailyGoalMinutes}',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = catudyDemoStore;
    final isLast = _index == 4;
    return AlertDialog(
      icon: const FloatingMascot(width: 74, height: 74),
      title: Text(store.t(_titleKey)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _stepContent(context, store),
        ),
      ),
      actions: [
        TextButton(onPressed: _finish, child: Text(store.t('tour.skip'))),
        FilledButton.icon(
          onPressed: isLast ? _startFirstFocus : _next,
          icon: Icon(
            isLast ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded,
          ),
          label: Text(store.t(isLast ? 'onboarding.startFocus' : 'tour.next')),
        ),
      ],
    );
  }

  String get _titleKey => switch (_index) {
    0 => 'onboarding.nameTitle',
    1 => 'onboarding.petTitle',
    2 => 'onboarding.goalTitle',
    3 => 'onboarding.friendTitle',
    _ => 'onboarding.startTitle',
  };

  Widget _stepContent(BuildContext context, CatudyDemoStore store) {
    if (_index == 0) {
      return Column(
        key: const ValueKey(0),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(store.t('onboarding.nameBody')),
          const SizedBox(height: 14),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: store.t('profile.name'),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      );
    }
    if (_index == 1) {
      return Column(
        key: const ValueKey(1),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(store.t('onboarding.petBody')),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final pet in store.unlockablePets)
                ChoiceChip(
                  label: Text(pet.name),
                  selected: store.selectedPetId == pet.id,
                  onSelected: store.unlockedPetIds.contains(pet.id)
                      ? (_) => setState(() => store.selectPet(pet.id))
                      : null,
                ),
            ],
          ),
        ],
      );
    }
    if (_index == 2) {
      return Column(
        key: const ValueKey(2),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(store.t('onboarding.goalBody')),
          const SizedBox(height: 14),
          TextField(
            controller: _goalController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: store.t('home.goalMinutes'),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      );
    }
    if (_index == 3) {
      return Column(
        key: const ValueKey(3),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(store.t('onboarding.friendBody')),
          const SizedBox(height: 12),
          SelectableText(
            store.publicUserCode,
            style: TextStyle(
              color: CatudyColors.blueFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: store.publicUserCode),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(store.t('profile.idCopied'))),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded),
            label: Text(store.t('profile.copyId')),
          ),
        ],
      );
    }
    return Text(store.t('onboarding.startBody'), key: const ValueKey(4));
  }

  void _next() {
    _saveCurrentStep();
    setState(() => _index += 1);
  }

  void _saveCurrentStep() {
    final store = catudyDemoStore;
    if (_index == 0) {
      store.updateProfile(
        name: _nameController.text,
        avatarId: store.profileAvatarId,
        customAvatarBase64: store.customProfileImageBase64,
      );
    }
    if (_index == 2) {
      store.updateDailyGoal(
        int.tryParse(_goalController.text) ?? store.dailyGoalMinutes,
      );
    }
  }

  void _finish() {
    _saveCurrentStep();
    catudyDemoStore.markIntroTourSeen();
    Navigator.of(context).pop();
  }

  void _startFirstFocus() {
    _finish();
    widget.router.go('/focus/start');
  }
}

Future<void> showPetIntroTour(BuildContext context, {GoRouter? router}) async {
  final appRouter = router ?? GoRouter.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  appRouter.go('/');
  if (!navigator.mounted) {
    return;
  }
  return showGeneralDialog<void>(
    context: navigator.context,
    barrierDismissible: false,
    barrierLabel: catudyDemoStore.t('tour.barrier'),
    barrierColor: Colors.black.withValues(alpha: 0.10),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, _, _) => _PetIntroTourOverlay(router: appRouter),
    transitionBuilder: (context, animation, _, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class _PetIntroTourOverlay extends StatefulWidget {
  const _PetIntroTourOverlay({required this.router});

  final GoRouter router;

  @override
  State<_PetIntroTourOverlay> createState() => _PetIntroTourOverlayState();
}

class _PetIntroTourOverlayState extends State<_PetIntroTourOverlay> {
  int _index = 0;

  static const _steps = [
    _TourStep(
      route: '/',
      title: 'Burası ana ekran',
      message:
          'Bugünün odak süresini, serini, hatırlatmalarını ve petinin kısa durumunu buradan takip edersin.',
      alignment: Alignment.topCenter,
      arrowAlignment: Alignment.topCenter,
      icon: Icons.home_rounded,
    ),
    _TourStep(
      route: '/',
      title: 'Odak burada başlar',
      message:
          'Ortadaki saat düğmesine basınca kategori ve süre seçimine geçersin. Gerçek seanslar puan, altın ve pet gelişimi kazandırır.',
      alignment: Alignment.center,
      arrowAlignment: Alignment.center,
      icon: Icons.schedule_rounded,
    ),
    _TourStep(
      route: '/calendar',
      title: 'Takvim',
      message:
          'Şimdi takvim ekranındayız. Geçmiş günlere manuel kayıt ekleyebilir, bugün ve gelecek günler için kendi metninle hatırlatma oluşturabilirsin.',
      alignment: Alignment.center,
      arrowAlignment: Alignment.center,
      icon: Icons.calendar_month_rounded,
    ),
    _TourStep(
      route: '/stats',
      title: 'İstatistikler',
      message:
          'Hafta, ay ve tüm zaman aralıklarında odak ritmini görürsün. Barların üstüne dokununca küçük açıklamalar açılır.',
      alignment: Alignment.center,
      arrowAlignment: Alignment.center,
      icon: Icons.query_stats_rounded,
    ),
    _TourStep(
      route: '/pet-room',
      title: 'Pet odası',
      message:
          'Mochi burada yaşar. Mutluluk, açlık ve enerji barlarına dokunarak ne anlama geldiklerini görebilirsin.',
      alignment: Alignment.topCenter,
      arrowAlignment: Alignment.topCenter,
      icon: Icons.pets_rounded,
    ),
    _TourStep(
      route: '/profile',
      title: 'Profil',
      message:
          'Toplam odak, seans sayısı, favori kategori, takılı eşyalar ve pet özetin burada görünür. Public profile bağlantısı da buradan ilerler.',
      alignment: Alignment.center,
      arrowAlignment: Alignment.center,
      icon: Icons.person_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _goToStepRoute());
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_index];
    final isLast = _index == _steps.length - 1;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Container(color: Colors.black.withValues(alpha: 0.04)),
              ),
            ),
            Align(
              alignment: step.alignment,
              child: Padding(
                padding: _paddingFor(step.alignment),
                child: _TourBubble(
                  step: step,
                  index: _index,
                  total: _steps.length,
                  isLast: isLast,
                  onSkip: _finish,
                  onNext: isLast ? _finish : _next,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  EdgeInsets _paddingFor(Alignment alignment) {
    if (alignment == Alignment.topCenter) {
      return const EdgeInsets.fromLTRB(18, 72, 18, 18);
    }
    if (alignment == Alignment.bottomCenter) {
      return const EdgeInsets.fromLTRB(18, 18, 18, 104);
    }
    return const EdgeInsets.symmetric(horizontal: 18);
  }

  void _next() {
    setState(() => _index += 1);
    WidgetsBinding.instance.addPostFrameCallback((_) => _goToStepRoute());
  }

  void _goToStepRoute() {
    if (!mounted) {
      return;
    }
    final route = _steps[_index].route;
    widget.router.go(route);
  }

  void _finish() {
    catudyDemoStore.markIntroTourSeen();
    Navigator.of(context).pop();
  }
}

class _TourBubble extends StatelessWidget {
  const _TourBubble({
    required this.step,
    required this.index,
    required this.total,
    required this.isLast,
    required this.onSkip,
    required this.onNext,
  });

  final _TourStep step;
  final int index;
  final int total;
  final bool isLast;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final dark = CatudyColors.isDark(context);
    final title = _titleFor(index);
    final message = _messageFor(index);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 370),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: CatudyColors.surfaceFor(
                context,
              ).withValues(alpha: dark ? 0.88 : 0.84),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: CatudyColors.teal.withValues(alpha: 0.34),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: (dark ? Colors.black : CatudyColors.violet).withValues(
                    alpha: dark ? 0.30 : 0.14,
                  ),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const FloatingMascot(width: 42, height: 42),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: CatudyColors.blueFor(context),
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    Icon(step.icon, color: CatudyColors.tealDark),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: CatudyColors.mutedFor(context),
                    height: 1.34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      '${index + 1}/$total',
                      style: TextStyle(
                        color: CatudyColors.mutedFor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onSkip,
                      child: Text(catudyDemoStore.t('tour.skip')),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: onNext,
                      icon: Icon(
                        isLast
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(
                        isLast
                            ? catudyDemoStore.t('tour.finish')
                            : catudyDemoStore.t('tour.next'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: -9,
            left: step.arrowAlignment == Alignment.topCenter ? 42 : null,
            right: step.arrowAlignment == Alignment.centerRight ? 42 : null,
            child: Transform.rotate(
              angle: 0.78,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: CatudyColors.surfaceFor(
                    context,
                  ).withValues(alpha: dark ? 0.88 : 0.84),
                  border: Border(
                    left: BorderSide(
                      color: CatudyColors.teal.withValues(alpha: 0.30),
                    ),
                    top: BorderSide(
                      color: CatudyColors.teal.withValues(alpha: 0.30),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _titleFor(int index) {
    const keys = [
      'tour.homeTitle',
      'tour.focusTitle',
      'tour.calendarTitle',
      'tour.statsTitle',
      'tour.petTitle',
      'tour.profileTitle',
    ];
    return catudyDemoStore.t(keys[index.clamp(0, keys.length - 1)]);
  }

  String _messageFor(int index) {
    const keys = [
      'tour.homeBody',
      'tour.focusBody',
      'tour.calendarBody',
      'tour.statsBody',
      'tour.petBody',
      'tour.profileBody',
    ];
    return catudyDemoStore.t(keys[index.clamp(0, keys.length - 1)]);
  }
}

class _TourStep {
  const _TourStep({
    required this.route,
    required this.title,
    required this.message,
    required this.alignment,
    required this.arrowAlignment,
    required this.icon,
  });

  final String route;
  final String title;
  final String message;
  final Alignment alignment;
  final Alignment arrowAlignment;
  final IconData icon;
}
