import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/notifications/catudy_notification_service.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

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
          fallbackBackPath: '/lobby',
          children: [
            _LobbyStatusPanel(store: store),
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
              for (final member in store.lobbyMembers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MemberTile(member: member, store: store),
                ),
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

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.store});

  final LobbyMember member;
  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: member.ready
                ? CatudyColors.teal
                : CatudyColors.coral,
            child: Icon(
              member.ready ? Icons.check_rounded : Icons.schedule_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${member.name}${member.owner ? ' - ${store.t('lobby.owner')}' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            member.connected
                ? store.t('lobby.online')
                : store.t('lobby.offline'),
          ),
        ],
      ),
    );
  }
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
