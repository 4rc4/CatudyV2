import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/catudy_test_ad_banner.dart';
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
          showInfoAction: false,
          showSettingsAction: false,
          children: [
            CatudyPanel(
              color: CatudyColors.lavenderSoft,
              accentColor: CatudyColors.violet,
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
                  const SizedBox(height: 6),
                  Text(
                    session?.todoId == null
                        ? store.t('focus.noTaskSelected')
                        : store.selectedFocusTodo?.title ??
                              store.t('focus.noTaskSelected'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: CatudyColors.mutedFor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
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
                  if (session != null) ...[
                    const SizedBox(height: 18),
                    Text(
                      session.isPaused
                          ? store.t(
                              session.isBreak
                                  ? 'focus.breakActive'
                                  : 'focus.paused',
                            )
                          : store.t('focus.ritualBody'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CatudyColors.mutedFor(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (session != null) ...[
              _FocusControls(store: store),
              const SizedBox(height: 14),
            ],
            if (session?.lobbyMode == true) ...[
              _BreakVotePanel(store: store),
              const SizedBox(height: 14),
            ],
            if (session != null) ...[
              CatudyTestAdBanner(show: !store.hasPremiumAccess),
              const SizedBox(height: 14),
            ],
            if (session == null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.go('/focus/start'),
                  icon: const Icon(Icons.timer_rounded),
                  label: Text(store.t('focus.start')),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: _EndFocusButton(
                  enabled: store.canEndActiveFocus && !store.lobbyBusy,
                  onPressed: () {
                    unawaited(
                      store.endActiveFocus().then((ended) {
                        if (ended && context.mounted) {
                          context.go('/focus/result');
                        }
                      }),
                    );
                  },
                  label: store.t('focus.endFocus'),
                ),
              ),
            if (store.endFocusBlockReason != null) ...[
              const SizedBox(height: 8),
              Text(
                store.endFocusBlockReason!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CatudyColors.mutedFor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
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

class _FocusControls extends StatelessWidget {
  const _FocusControls({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final session = store.activeSession;
    if (session == null) {
      return const SizedBox.shrink();
    }
    final pauseBlocked = !store.canPauseActiveFocus || store.lobbyBusy;
    final breakDisabled =
        store.lobbyBusy ||
        (session.lobbyMode
            ? store.activeFocusPaused || store.currentUserBreakVote == true
            : store.activeFocusPaused);
    return CatudyPanel(
      accentColor: store.activeFocusBreakActive
          ? CatudyColors.teal
          : CatudyColors.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: pauseBlocked
                      ? null
                      : () => unawaited(store.toggleFocusPause()),
                  icon: Icon(
                    store.activeFocusPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                  ),
                  label: Text(
                    store.activeFocusPaused
                        ? store.t('focus.resumeFocus')
                        : store.t('focus.pauseFocus'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: breakDisabled
                      ? null
                      : () => unawaited(store.startBreak()),
                  icon: Icon(
                    store.activeFocusBreakActive
                        ? Icons.free_breakfast_rounded
                        : Icons.local_cafe_rounded,
                  ),
                  label: Text(
                    session.lobbyMode
                        ? (store.currentUserBreakVote == true
                              ? store.t('focus.breakRequested')
                              : store.t('focus.requestBreak'))
                        : store.t('focus.startBreak'),
                  ),
                ),
              ),
            ],
          ),
          if (store.pauseFocusBlockReason != null) ...[
            const SizedBox(height: 8),
            Text(
              store.pauseFocusBlockReason!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CatudyColors.mutedFor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EndFocusButton extends StatefulWidget {
  const _EndFocusButton({
    required this.onPressed,
    required this.label,
    required this.enabled,
  });

  final VoidCallback onPressed;
  final String label;
  final bool enabled;

  @override
  State<_EndFocusButton> createState() => _EndFocusButtonState();
}

class _EndFocusButtonState extends State<_EndFocusButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: widget.enabled
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapCancel: widget.enabled
            ? () => setState(() => _pressed = false)
            : null,
        onTapUp: widget.enabled
            ? (_) => setState(() => _pressed = false)
            : null,
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          scale: widget.enabled && _pressed ? 0.985 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: widget.enabled
                  ? const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [CatudyColors.coral, CatudyColors.violet],
                    )
                  : null,
              color: widget.enabled
                  ? null
                  : CatudyColors.muted.withValues(alpha: 0.2),
              boxShadow: [
                BoxShadow(
                  color: CatudyColors.coral.withValues(
                    alpha: widget.enabled ? (_pressed ? 0.14 : 0.26) : 0,
                  ),
                  blurRadius: _pressed ? 8 : 20,
                  offset: Offset(0, _pressed ? 4 : 10),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.38),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: CatudyColors.coral,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BreakVotePanel extends StatelessWidget {
  const _BreakVotePanel({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final vote = store.currentUserBreakVote;
    final votingClosed = store.activeFocusPaused || store.lobbyBusy;
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
            store.activeFocusBreakActive
                ? store.t('lobby.breakActive')
                : store.t('lobby.breakVoteStatus', {
                    'yes': store.breakVoteApproveCount,
                    'no': store.breakVoteRejectCount,
                    'cast': store.breakVoteCastCount,
                    'total': store.breakVoteTotalCount,
                    'needed': store.breakVoteThreshold,
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
                  onPressed: votingClosed
                      ? null
                      : () => store.submitBreakVote(false),
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
                  onPressed: votingClosed
                      ? null
                      : () => store.submitBreakVote(true),
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
