import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  Timer? _ticker;
  DateTime _now = DateTime.now();
  bool _completedFromTicker = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        final session = store.activeSession;
        final remaining = store.remainingSeconds(_now);
        final total =
            (session?.durationMinutes ?? store.selectedDurationMinutes) * 60;
        final progress = total == 0 ? 0.0 : 1 - (remaining / total);

        if (session != null && remaining == 0 && !_completedFromTicker) {
          _completedFromTicker = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            store.completeFocus();
            context.go('/focus/result');
          });
        }
        if (session == null &&
            store.hasPendingFocusResult &&
            !_completedFromTicker) {
          _completedFromTicker = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            final focusRoute = store.consumeFocusNavigationRoute();
            if (focusRoute != null) {
              context.go(focusRoute);
            }
          });
        }

        return ScreenScaffold(
          title: session?.lobbyMode == true
              ? store.t('focus.lobbyTimerTitle')
              : store.t('focus.timerTitle'),
          showBack: false,
          children: [
            CatudyPanel(
              child: Column(
                children: [
                  Text(
                    store.categoryName(
                      session?.categoryId ?? store.selectedCategoryId,
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: store.categoryColor(
                        session?.categoryId ?? store.selectedCategoryId,
                      ),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 190,
                        height: 190,
                        child: CircularProgressIndicator(
                          value: progress.clamp(0, 1),
                          strokeWidth: 14,
                          backgroundColor: CatudyColors.lavenderSoft,
                          color: CatudyColors.violet,
                        ),
                      ),
                      Text(
                        _format(remaining),
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              color: CatudyColors.blue,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                  if (session == null) ...[
                    const SizedBox(height: 22),
                    Text(
                      store.t('focus.noActiveSession'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: CatudyColors.muted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (session?.lobbyMode == true) ...[
              _BreakVotePanel(store: store),
              const SizedBox(height: 14),
            ],
            if (session == null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.go('/focus/category'),
                  icon: const Icon(Icons.timer_rounded),
                  label: Text(store.t('focus.start')),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    store.completeFocus();
                    context.go('/focus/result');
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: Text(store.t('focus.endFocus')),
                ),
              ),
          ],
        );
      },
    );
  }

  String _format(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
  }
}

class _BreakVotePanel extends StatelessWidget {
  const _BreakVotePanel({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final vote = store.currentUserBreakVote;
    return CatudyPanel(
      accentColor: CatudyColors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            store.t('lobby.breakVote'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            store.t('lobby.breakVoteStatus', {
              'yes': store.breakVoteApproveCount,
              'no': store.breakVoteRejectCount,
              'total': store.breakVoteTotalCount,
            }),
            style: TextStyle(
              color: CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => store.submitBreakVote(false),
                  icon: Icon(
                    vote == false
                        ? Icons.check_circle_rounded
                        : Icons.close_rounded,
                  ),
                  label: Text(store.t('common.no')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => store.submitBreakVote(true),
                  icon: Icon(
                    vote == true
                        ? Icons.check_circle_rounded
                        : Icons.free_breakfast_rounded,
                  ),
                  label: Text(store.t('common.yes')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
