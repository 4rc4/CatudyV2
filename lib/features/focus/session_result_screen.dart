import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/floating_mascot.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

class SessionResultScreen extends StatefulWidget {
  const SessionResultScreen({super.key});

  @override
  State<SessionResultScreen> createState() => _SessionResultScreenState();
}

class _SessionResultScreenState extends State<SessionResultScreen>
    with TickerProviderStateMixin {
  bool _unlockDialogShown = false;
  String? _celebratedResultId;
  late final AnimationController _entryController;
  late final AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        if (!_unlockDialogShown) {
          final unlocked = store.consumeUnlockedPets();
          if (unlocked.isNotEmpty) {
            _unlockDialogShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(store.t('focus.petUnlocked')),
                  content: Text(
                    store.t('focus.petUnlockedBody', {
                      'pet': unlocked.first.name,
                    }),
                  ),
                  actions: [
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(store.t('common.done')),
                    ),
                  ],
                ),
              );
            });
          }
        }
        final result = store.lastResult;
        _triggerCompletionFeedback(result);
        final goal = store.todayGoalProgress;
        return ScreenScaffold(
          title: store.t('focus.resultTitle'),
          children: [
            _ResultCelebrationFrame(
              enabled: result != null,
              entryController: _entryController,
              particleController: _particleController,
              child: CatudyPanel(
                color: CatudyColors.lavenderSoft,
                accentColor: CatudyColors.violet,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const FloatingMascot(width: 68, height: 68),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            result == null
                                ? store.t('focus.resultEmpty')
                                : store.t('focus.resultComplete'),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: CatudyColors.blueFor(context),
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      result == null
                          ? store.t('focus.resultEmptyBody')
                          : store.t('focus.resultSaved', {
                              'category': store.categoryName(result.categoryId),
                              'minutes': result.minutes,
                            }),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: CatudyColors.mutedFor(context),
                        height: 1.45,
                      ),
                    ),
                    if (result != null) ...[
                      const SizedBox(height: 18),
                      Text(
                        store.t('focus.resultSummary'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: CatudyColors.mutedFor(context),
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 10),
                      _ResultMetricGrid(
                        items: [
                          _ResultMetricItem(
                            icon: Icons.add_circle_rounded,
                            label: store.t('focus.resultGoldEarned'),
                            value: '+${result.gold} ${store.t('common.gold')}',
                            color: CatudyColors.violet,
                          ),
                          _ResultMetricItem(
                            icon: Icons.pets_rounded,
                            label: store.t('focus.resultPetEffect'),
                            value: store.t('focus.resultPetEffectValue'),
                            color: CatudyColors.teal,
                          ),
                          _ResultMetricItem(
                            icon: Icons.local_fire_department_rounded,
                            label: store.t('focus.resultStreak'),
                            value: store.t('focus.resultStreakValue', {
                              'days': store.streakDays,
                            }),
                            color: CatudyColors.coral,
                          ),
                          _ResultMetricItem(
                            icon: Icons.track_changes_rounded,
                            label: store.t('focus.resultGoal'),
                            value:
                                '${goal.completedMinutes}/${goal.goalMinutes}${store.t('common.minutesShort')}',
                            color: CatudyColors.tealDark,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            _ResultPrimaryActions(store: store),
          ],
        );
      },
    );
  }

  void _triggerCompletionFeedback(FocusRecord? result) {
    if (result == null || _celebratedResultId == result.id) {
      return;
    }
    _celebratedResultId = result.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _entryController.forward(from: 0);
      _particleController.forward(from: 0);
      unawaited(HapticFeedback.mediumImpact().catchError((Object _) {}));
      unawaited(
        SystemSound.play(SystemSoundType.alert).catchError((Object _) {}),
      );
    });
  }
}

class _ResultCelebrationFrame extends StatelessWidget {
  const _ResultCelebrationFrame({
    required this.enabled,
    required this.entryController,
    required this.particleController,
    required this.child,
  });

  final bool enabled;
  final AnimationController entryController;
  final AnimationController particleController;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }
    return AnimatedBuilder(
      animation: Listenable.merge([entryController, particleController]),
      builder: (context, child) {
        final entry = Curves.easeOutBack.transform(entryController.value);
        final opacity = Curves.easeOutCubic.transform(
          entryController.value.clamp(0, 1),
        );
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: ui.lerpDouble(0.94, 1, entry)!,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                child!,
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ResultParticlePainter(
                        progress: particleController.value,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class _ResultParticlePainter extends CustomPainter {
  const _ResultParticlePainter({required this.progress});

  final double progress;

  static const _colors = [
    CatudyColors.violet,
    CatudyColors.teal,
    CatudyColors.coral,
    CatudyColors.yellow,
    CatudyColors.lavender,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) {
      return;
    }
    final rect = Offset.zero & size;
    final center = rect.center;
    for (var index = 0; index < 54; index += 1) {
      final delay = (index % 9) * 0.018;
      final local = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) {
        continue;
      }
      final eased = Curves.easeOutCubic.transform(local);
      final side = index % 4;
      final edgeT = ((index * 37) % 100) / 100.0;
      final start = switch (side) {
        0 => Offset(size.width * edgeT, 0),
        1 => Offset(size.width, size.height * edgeT),
        2 => Offset(size.width * edgeT, size.height),
        _ => Offset(0, size.height * edgeT),
      };
      final outward = (start - center);
      final direction = outward.distance == 0
          ? const Offset(0, -1)
          : outward / outward.distance;
      final flutter = Offset(
        math.sin((local * math.pi * 2) + index) * 18,
        math.cos((local * math.pi * 1.4) + index) * 10,
      );
      final distance = ui.lerpDouble(8, 74 + (index % 7) * 8, eased)!;
      final position = start + direction * distance + flutter;
      final alpha = (1 - local).clamp(0.0, 1.0);
      final color = _colors[index % _colors.length].withValues(
        alpha: alpha * 0.92,
      );
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = color;

      if (index % 3 == 0) {
        final angle = local * math.pi * 2 + index;
        final length = ui.lerpDouble(12, 5, local)!;
        canvas.drawLine(
          position - Offset(math.cos(angle), math.sin(angle)) * length,
          position + Offset(math.cos(angle), math.sin(angle)) * length,
          paint,
        );
      } else {
        canvas.drawCircle(position, ui.lerpDouble(4.5, 1.6, local)!, paint);
      }
    }

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ui.lerpDouble(5, 1, progress)!
      ..color = CatudyColors.yellow.withValues(
        alpha: (1 - progress).clamp(0.0, 1.0) * 0.42,
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.inflate(8 + progress * 16),
        const Radius.circular(24),
      ),
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ResultParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ResultPrimaryActions extends StatelessWidget {
  const _ResultPrimaryActions({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 58,
          child: FilledButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home_rounded),
            label: Text(store.t('focus.backHome')),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 56,
          child: FilledButton.tonalIcon(
            onPressed: () => context.go('/focus/start'),
            icon: const Icon(Icons.replay_rounded),
            label: Text(store.t('focus.focusAgain')),
          ),
        ),
      ],
    );
  }
}

class _ResultMetricItem {
  const _ResultMetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class _ResultMetricGrid extends StatelessWidget {
  const _ResultMetricGrid({required this.items});

  final List<_ResultMetricItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final columns = constraints.maxWidth >= 260 ? 2 : 1;
        final tileWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: tileWidth,
                child: _ResultMetricTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _ResultMetricTile extends StatelessWidget {
  const _ResultMetricTile({required this.item});

  final _ResultMetricItem item;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 96),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: CatudyColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: item.color.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(item.icon, color: item.color, size: 22),
            const SizedBox(height: 8),
            Text(
              item.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: CatudyColors.blueFor(context),
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: CatudyColors.mutedFor(context),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
