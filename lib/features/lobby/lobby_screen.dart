import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/catudy_assets.dart';
import '../../app/demo/catudy_demo_store.dart';
import '../../app/notifications/catudy_notification_service.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/catudy_section_header.dart';
import '../../shared/widgets/catudy_test_ad_banner.dart';
import '../../shared/widgets/catudy_visual_system.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

class LobbiesCommunitySection extends StatefulWidget {
  const LobbiesCommunitySection({super.key});

  @override
  State<LobbiesCommunitySection> createState() =>
      _LobbiesCommunitySectionState();
}

class _LobbiesCommunitySectionState extends State<LobbiesCommunitySection> {
  final _codeController = TextEditingController();
  late final TextEditingController _minutesController;

  @override
  void initState() {
    super.initState();
    _minutesController = TextEditingController(
      text: catudyDemoStore.selectedDurationMinutes.toString(),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        return Column(
          children: [
            CatudyStagePanel(
              title: store.t('community.lobbiesTitle'),
              subtitle: store.t('community.lobbiesBody'),
              art: const CatudyMascotBadge(
                size: 92,
                accent: CatudyColors.violet,
              ),
              actions: [
                FilledButton.icon(
                  onPressed: store.lobbyBusy
                      ? null
                      : () => unawaited(store.createOnlineLobby()),
                  icon: store.lobbyBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_home_work_rounded),
                  label: Text(store.t('lobby.create')),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/focus/start'),
                  icon: const Icon(Icons.timer_rounded),
                  label: Text(store.t('focus.start')),
                ),
              ],
            ),
            CatudyTestAdBanner(show: !store.hasPremiumAccess),
            const SizedBox(height: 14),
            _LobbyComposer(
              store: store,
              codeController: _codeController,
              minutesController: _minutesController,
            ),
            const SizedBox(height: 14),
            if (store.hasOnlineLobby)
              _CurrentLobbyCard(store: store)
            else
              _NoLobbyCard(store: store),
          ],
        );
      },
    );
  }
}

class _LobbyComposer extends StatelessWidget {
  const _LobbyComposer({
    required this.store,
    required this.codeController,
    required this.minutesController,
  });

  final CatudyDemoStore store;
  final TextEditingController codeController;
  final TextEditingController minutesController;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      accentColor: CatudyColors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CatudySectionHeader(
            title: store.t('community.lobbyComposerTitle'),
            subtitle: store.t('community.lobbyComposerBody'),
            icon: Icons.tune_rounded,
            accentColor: CatudyColors.teal,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final minutes in store.durations)
                ChoiceChip(
                  label: Text('$minutes ${store.t('common.minutesShort')}'),
                  selected: store.selectedDurationMinutes == minutes,
                  onSelected: (_) {
                    store.selectDuration(minutes);
                    minutesController.text = '$minutes';
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: store.t('lobby.joinCode'),
                    prefixIcon: const Icon(Icons.key_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: store.lobbyBusy
                    ? null
                    : () =>
                          unawaited(store.joinOnlineLobby(codeController.text)),
                child: Text(store.t('lobby.join')),
              ),
            ],
          ),
          if (store.lobbyError != null) _LobbyError(store.lobbyError!),
        ],
      ),
    );
  }
}

class _CurrentLobbyCard extends StatelessWidget {
  const _CurrentLobbyCard({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      accentColor: CatudyColors.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CatudySectionHeader(
            title: store.t('community.currentLobbyTitle'),
            subtitle: store.lobbyJoinCode == null
                ? store.t('lobby.selectedDuration', {
                    'minutes': store.selectedDurationMinutes,
                  })
                : store.t('lobby.code', {'code': store.lobbyJoinCode}),
            icon: Icons.meeting_room_rounded,
            accentColor: CatudyColors.violet,
          ),
          const SizedBox(height: 12),
          _LobbyPlazaScene(store: store, compact: true),
          const SizedBox(height: 12),
          if (store.lobbyStartBlockReason != null) ...[
            Text(
              store.lobbyStartBlockReason!,
              style: TextStyle(
                color: CatudyColors.mutedFor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: store.toggleReady,
                  icon: Icon(
                    store.currentUserReady
                        ? Icons.close_rounded
                        : Icons.check_rounded,
                  ),
                  label: Text(
                    store.currentUserReady
                        ? store.t('lobby.notReady')
                        : store.t('lobby.ready'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: store.lobbyBusy || !store.canStartLobby
                      ? null
                      : store.startLobbySession,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(store.t('lobby.start')),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: store.leaveOnlineLobby,
              icon: const Icon(Icons.logout_rounded),
              label: Text(store.t('lobby.leave')),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoLobbyCard extends StatelessWidget {
  const _NoLobbyCard({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      color: CatudyColors.cream,
      accentColor: CatudyColors.coral,
      child: Row(
        children: [
          const Icon(Icons.lock_clock_rounded, color: CatudyColors.coral),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              store.t('community.noLobbyBody'),
              style: TextStyle(
                color: CatudyColors.mutedFor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) => ScreenScaffold(
        title: store.t('lobby.title'),
        showBack: true,
        children: [
          CatudyPanel(
            accentColor: CatudyColors.teal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  store.t('lobby.chooseFlow'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: CatudyColors.mutedFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => context.go('/lobby/create'),
                  icon: const Icon(Icons.add_home_work_rounded),
                  label: Text(store.t('lobby.create')),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => context.go('/lobby/join'),
                  icon: const Icon(Icons.login_rounded),
                  label: Text(store.t('lobby.join')),
                ),
              ],
            ),
          ),
          CatudyTestAdBanner(show: !store.hasPremiumAccess),
        ],
      ),
    );
  }
}

class LobbyCreateScreen extends StatefulWidget {
  const LobbyCreateScreen({super.key});

  @override
  State<LobbyCreateScreen> createState() => _LobbyCreateScreenState();
}

class _LobbyCreateScreenState extends State<LobbyCreateScreen> {
  late final TextEditingController _minutesController;

  @override
  void initState() {
    super.initState();
    _minutesController = TextEditingController(
      text: catudyDemoStore.selectedDurationMinutes.toString(),
    );
  }

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        if (store.hasOnlineLobby) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/lobby/room');
            }
          });
        }
        return ScreenScaffold(
          title: store.t('lobby.createTitle'),
          showBack: true,
          fallbackBackPath: '/lobby',
          children: [
            CatudyPanel(
              accentColor: CatudyColors.teal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    store.t('lobby.durationSetup'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: CatudyColors.mutedFor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final minutes in store.durations)
                        ChoiceChip(
                          label: Text('$minutes ${store.t('common.minutes')}'),
                          selected: store.selectedDurationMinutes == minutes,
                          onSelected: (_) {
                            store.selectDuration(minutes);
                            _minutesController.text = '$minutes';
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _minutesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: store.t('lobby.customMinutes'),
                      prefixIcon: const Icon(Icons.timer_rounded),
                    ),
                    onChanged: (value) {
                      final minutes = int.tryParse(value);
                      if (minutes != null && minutes > 0) {
                        store.selectDuration(minutes.clamp(1, 240).toInt());
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: store.lobbyBusy
                        ? null
                        : () => unawaited(store.createOnlineLobby()),
                    icon: store.lobbyBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_home_work_rounded),
                    label: Text(store.t('lobby.create')),
                  ),
                  if (store.lobbyError != null) _LobbyError(store.lobbyError!),
                ],
              ),
            ),
            CatudyTestAdBanner(show: !store.hasPremiumAccess),
          ],
        );
      },
    );
  }
}

class LobbyJoinScreen extends StatefulWidget {
  const LobbyJoinScreen({super.key});

  @override
  State<LobbyJoinScreen> createState() => _LobbyJoinScreenState();
}

class _LobbyJoinScreenState extends State<LobbyJoinScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        if (store.hasOnlineLobby) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/lobby/room');
            }
          });
        }
        return ScreenScaffold(
          title: store.t('lobby.joinTitle'),
          showBack: true,
          fallbackBackPath: '/lobby',
          children: [
            CatudyPanel(
              accentColor: CatudyColors.violet,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: store.t('lobby.joinCode'),
                      prefixIcon: const Icon(Icons.key_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: store.lobbyBusy
                        ? null
                        : () => unawaited(
                            store.joinOnlineLobby(_codeController.text),
                          ),
                    icon: const Icon(Icons.login_rounded),
                    label: Text(store.t('lobby.join')),
                  ),
                  if (store.lobbyError != null) _LobbyError(store.lobbyError!),
                ],
              ),
            ),
            CatudyTestAdBanner(show: !store.hasPremiumAccess),
          ],
        );
      },
    );
  }
}

class LobbyRoomScreen extends StatelessWidget {
  const LobbyRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        if (store.activeSession?.lobbyMode == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/focus/timer');
            }
          });
        }
        return ScreenScaffold(
          title: store.t('lobby.roomTitle'),
          showBack: true,
          fallbackBackPath: '/',
          children: [
            _LobbyStatusPanel(store: store),
            CatudyTestAdBanner(show: !store.hasPremiumAccess),
            const SizedBox(height: 14),
            if (!store.hasOnlineLobby)
              CatudyPanel(
                child: Text(
                  store.t('lobby.noActiveLobby'),
                  style: TextStyle(color: CatudyColors.mutedFor(context)),
                ),
              )
            else ...[
              _DurationPanel(store: store),
              const SizedBox(height: 14),
              _LobbyPlazaScene(store: store),
              const SizedBox(height: 14),
              if (store.lobbyStartBlockReason != null) ...[
                Text(
                  store.lobbyStartBlockReason!,
                  style: TextStyle(
                    color: CatudyColors.mutedFor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: store.toggleReady,
                      icon: Icon(
                        store.currentUserReady
                            ? Icons.close_rounded
                            : Icons.check_rounded,
                      ),
                      label: Text(
                        store.currentUserReady
                            ? store.t('lobby.notReady')
                            : store.t('lobby.ready'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: store.lobbyBusy || !store.canStartLobby
                          ? null
                          : store.startLobbySession,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(store.t('lobby.start')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: store.leaveOnlineLobby,
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(store.t('lobby.leave')),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LobbyStatusPanel extends StatelessWidget {
  const _LobbyStatusPanel({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final code = store.lobbyJoinCode;
    return CatudyPanel(
      color: CatudyColors.lavenderSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            store.onlineLobbyAvailable
                ? store.t('lobby.onlineBackend')
                : store.t('lobby.offlineBackend'),
            style: TextStyle(
              color: CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          if (code != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    store.t('lobby.code', {'code': code}),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: CatudyColors.isDark(context)
                          ? CatudyColors.yellow
                          : CatudyColors.tealDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: store.t('lobby.copyCode'),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(store.t('lobby.codeCopied'))),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded),
                ),
                IconButton(
                  tooltip: store.t('lobby.shareInvite'),
                  onPressed: () async {
                    await CatudyNotificationService.instance
                        .showLobbyInviteNotification(
                          code: code,
                          languageCode: store.languageCode,
                        );
                    await SharePlus.instance.share(
                      ShareParams(
                        text: store.t('lobby.inviteText', {'code': code}),
                      ),
                    );
                  },
                  icon: const Icon(Icons.ios_share_rounded),
                ),
              ],
            ),
          ],
          if (store.lobbyError != null) _LobbyError(store.lobbyError!),
        ],
      ),
    );
  }
}

class _DurationPanel extends StatelessWidget {
  const _DurationPanel({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      child: Row(
        children: [
          const Icon(Icons.timer_rounded, color: CatudyColors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              store.t('lobby.selectedDuration', {
                'minutes': store.selectedDurationMinutes,
              }),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _LobbyPlazaScene extends StatelessWidget {
  const _LobbyPlazaScene({required this.store, this.compact = false});

  final CatudyDemoStore store;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final members = store.lobbyMembers
        .where((member) => member.connected)
        .toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final height = compact
            ? (width * 0.92).clamp(300.0, 430.0).toDouble()
            : (width * 1.24).clamp(430.0, 620.0).toDouble();
        final placements = [
          for (var index = 0; index < members.length; index += 1)
            _LobbyPetPlacement.forIndex(index, width, height, compact: compact),
        ]..sort((a, b) => b.row.compareTo(a.row));

        return ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  CatudyAssets.lobbyPlaza,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) =>
                      const _LobbyPlazaFallback(),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.00),
                        Colors.white.withValues(alpha: 0.04),
                        Colors.black.withValues(alpha: 0.10),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
                for (final placement in placements)
                  Positioned(
                    left: placement.x - placement.size / 2,
                    top: placement.y - placement.size / 2,
                    width: placement.size,
                    height: placement.size * 1.08,
                    child: _LobbyPet(
                      member: members[placement.index],
                      store: store,
                      size: placement.size,
                    ),
                  ),
                Positioned(
                  left: 12,
                  right: 12,
                  top: 12,
                  child: Row(
                    children: [
                      _LobbySceneBadge(
                        icon: Icons.groups_rounded,
                        label:
                            '${members.length} ${store.t('social.participants')}',
                      ),
                      const Spacer(),
                      _LobbySceneBadge(
                        icon: Icons.timer_rounded,
                        label:
                            '${store.selectedDurationMinutes} ${store.t('common.minutesShort')}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LobbyPetPlacement {
  const _LobbyPetPlacement({
    required this.index,
    required this.row,
    required this.x,
    required this.y,
    required this.size,
  });

  factory _LobbyPetPlacement.forIndex(
    int index,
    double width,
    double height, {
    required bool compact,
  }) {
    var remaining = index;
    var row = 0;
    var rowCapacity = 2;
    while (remaining >= rowCapacity) {
      remaining -= rowCapacity;
      row += 1;
      rowCapacity = row + 2;
    }
    final countInRow = rowCapacity;
    final rowProgress = countInRow == 1
        ? 0.5
        : (remaining + 1) / (countInRow + 1);
    final rowWidth = width * (0.44 + row * 0.10).clamp(0.44, 0.74);
    final x = width / 2 - rowWidth / 2 + rowWidth * rowProgress;
    final frontY = compact ? height * 0.75 : height * 0.77;
    final y = frontY - row * (compact ? height * 0.115 : height * 0.105);
    final size = (width * (compact ? 0.25 : 0.29) * math.pow(0.80, row))
        .clamp(compact ? 58.0 : 76.0, compact ? 96.0 : 128.0)
        .toDouble();
    return _LobbyPetPlacement(
      index: index,
      row: row,
      x: x.clamp(size * 0.62, width - size * 0.62).toDouble(),
      y: y.clamp(height * 0.38, height - size * 0.50).toDouble(),
      size: size,
    );
  }

  final int index;
  final int row;
  final double x;
  final double y;
  final double size;
}

class _LobbyPet extends StatelessWidget {
  const _LobbyPet({
    required this.member,
    required this.store,
    required this.size,
  });

  final LobbyMember member;
  final CatudyDemoStore store;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pet = store.unlockablePets.firstWhere(
      (item) => item.id == member.petId,
      orElse: () => store.unlockablePets.first,
    );
    final accessory = member.equippedPetItemId == null
        ? null
        : store.shopItemById(member.equippedPetItemId!);
    return Semantics(
      label: member.petName,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: size * 0.04,
            child: Container(
              width: size * 0.72,
              height: size * 0.16,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.12,
            child: Container(
              width: size * 0.95,
              height: size * 0.95,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: pet.accent.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.12,
            child: Image.asset(
              CatudyAssets.mascot,
              width: size * 0.90,
              height: size * 0.90,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          if (accessory?.id == 'violet_collar')
            Positioned(
              bottom: size * 0.25,
              child: CustomPaint(
                size: Size(size * 0.44, size * 0.16),
                painter: _LobbyCollarPainter(color: accessory!.accent),
              ),
            ),
          if (accessory?.id == 'sunny_hat')
            Positioned(
              top: size * 0.10,
              child: CustomPaint(
                size: Size(size * 0.46, size * 0.28),
                painter: _LobbyHatPainter(color: accessory!.accent),
              ),
            ),
          if (member.owner)
            Positioned(
              top: size * 0.05,
              right: size * 0.07,
              child: _TinyPetBadge(
                color: CatudyColors.yellow,
                icon: Icons.star_rounded,
                size: size * 0.22,
              ),
            ),
          Positioned(
            bottom: size * 0.02,
            right: size * 0.08,
            child: _TinyPetBadge(
              color: member.ready ? CatudyColors.teal : CatudyColors.coral,
              icon: member.ready ? Icons.check_rounded : Icons.schedule_rounded,
              size: size * 0.20,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyPetBadge extends StatelessWidget {
  const _TinyPetBadge({
    required this.color,
    required this.icon,
    required this.size,
  });

  final Color color;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.clamp(16.0, 28.0),
      height: size.clamp(16.0, 28.0),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size.clamp(10.0, 16.0)),
    );
  }
}

class _LobbySceneBadge extends StatelessWidget {
  const _LobbySceneBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.68)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: CatudyColors.violet, size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: CatudyColors.tealDark,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _LobbyPlazaFallback extends StatelessWidget {
  const _LobbyPlazaFallback();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _LobbyPlazaFallbackPainter());
  }
}

class _LobbyPlazaFallbackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF69C9FF), Color(0xFFEFF9FF), Color(0xFFF8D9B8)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final pathPaint = Paint()..color = const Color(0xFFF4CDAE);
    final path = Path()
      ..moveTo(size.width * 0.20, size.height)
      ..lineTo(size.width * 0.40, size.height * 0.48)
      ..lineTo(size.width * 0.60, size.height * 0.48)
      ..lineTo(size.width * 0.82, size.height)
      ..close();
    canvas.drawPath(path, pathPaint);

    final gardenPaint = Paint()..color = const Color(0xFF8DCB7F);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.10, size.height * 0.58),
        width: size.width * 0.46,
        height: size.height * 0.22,
      ),
      gardenPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.90, size.height * 0.58),
        width: size.width * 0.46,
        height: size.height * 0.22,
      ),
      gardenPaint,
    );

    final gazeboPaint = Paint()..color = const Color(0xFFD8A7E8);
    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.35),
      size.width * 0.10,
      gazeboPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.47),
        width: size.width * 0.22,
        height: size.height * 0.11,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.72),
    );
  }

  @override
  bool shouldRepaint(covariant _LobbyPlazaFallbackPainter oldDelegate) => false;
}

class _LobbyCollarPainter extends CustomPainter {
  const _LobbyCollarPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final collar = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.26
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height * 1.8),
      math.pi * 0.08,
      math.pi * 0.84,
      false,
      collar,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.92),
      size.height * 0.18,
      Paint()..color = CatudyColors.yellow,
    );
  }

  @override
  bool shouldRepaint(covariant _LobbyCollarPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _LobbyHatPainter extends CustomPainter {
  const _LobbyHatPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final brim = Paint()..color = color;
    final crown = Paint()..color = Color.lerp(color, Colors.white, 0.20)!;
    canvas.drawOval(
      Rect.fromLTWH(0, size.height * 0.46, size.width, size.height * 0.32),
      brim,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.22,
          size.height * 0.16,
          size.width * 0.56,
          size.height * 0.46,
        ),
        Radius.circular(size.height * 0.28),
      ),
      crown,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.24,
        size.height * 0.48,
        size.width * 0.52,
        size.height * 0.11,
      ),
      Paint()..color = CatudyColors.coral.withValues(alpha: 0.74),
    );
  }

  @override
  bool shouldRepaint(covariant _LobbyHatPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _LobbyError extends StatelessWidget {
  const _LobbyError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        message,
        style: const TextStyle(
          color: CatudyColors.coral,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
