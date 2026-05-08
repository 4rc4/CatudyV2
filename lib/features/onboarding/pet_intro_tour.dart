import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/floating_mascot.dart';

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
