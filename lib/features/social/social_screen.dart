import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  late final TextEditingController _friendController;

  @override
  void initState() {
    super.initState();
    _friendController = TextEditingController();
  }

  @override
  void dispose() {
    _friendController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        final challenge = store.weeklySocialChallenge;
        final friends = store.friendProfiles;
        return ScreenScaffold(
          title: store.t('social.title'),
          children: [
            CatudyPanel(
              color: CatudyColors.cream,
              accentColor: CatudyColors.teal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.groups_rounded,
                        color: CatudyColors.teal,
                        size: 30,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          challenge.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: CatudyColors.blueFor(context),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    challenge.description,
                    style: TextStyle(
                      color: CatudyColors.mutedFor(context),
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: challenge.ratio,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: CatudyColors.surfaceFor(context),
                    color: challenge.completed
                        ? CatudyColors.teal
                        : CatudyColors.violet,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    store.t('social.challengeProgress', {
                      'done': challenge.currentMinutes,
                      'goal': challenge.targetMinutes,
                      'left': challenge.remainingMinutes,
                      'people': challenge.participants,
                    }),
                    style: TextStyle(
                      color: CatudyColors.mutedFor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            CatudyPanel(
              accentColor: CatudyColors.violet,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.t('social.addByNameTitle'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: CatudyColors.mutedFor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _friendController,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: store.t('social.friendSearchLabel'),
                            hintText: store.t('social.friendSearchHint'),
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.badge_rounded),
                          ),
                          onSubmitted: (_) =>
                              _sendFriendRequest(context, store),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: () => _sendFriendRequest(context, store),
                          icon: const Icon(Icons.send_rounded),
                          label: Text(store.t('social.requestButton')),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _FriendRequestsPanel(store: store),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.go('/lobby/create'),
                    icon: const Icon(Icons.add_home_rounded),
                    label: Text(store.t('home.createLobby')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => context.go('/lobby/join'),
                    icon: const Icon(Icons.login_rounded),
                    label: Text(store.t('home.joinLobby')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            CatudyPanel(
              accentColor: CatudyColors.teal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.t('social.friends'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: CatudyColors.mutedFor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (friends.isEmpty)
                    Text(
                      store.t('social.noFriends'),
                      style: TextStyle(color: CatudyColors.mutedFor(context)),
                    )
                  else
                    for (var index = 0; index < friends.length; index++)
                      _SocialProfileRow(profile: friends[index], store: store),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _sendFriendRequest(BuildContext context, CatudyDemoStore store) {
    final result = store.sendFriendRequestByQuery(_friendController.text);
    final messageKey = switch (result) {
      FriendRequestActionResult.sent => 'social.friendRequestSent',
      FriendRequestActionResult.alreadyFriend => 'social.friendAlreadyAdded',
      FriendRequestActionResult.alreadyPending => 'social.friendRequestPending',
      FriendRequestActionResult.self => 'social.friendSelf',
      FriendRequestActionResult.notFound => 'social.friendNotFound',
      FriendRequestActionResult.blocked => 'social.friendBlocked',
      FriendRequestActionResult.empty => 'social.friendEmpty',
    };
    if (result == FriendRequestActionResult.sent) {
      _friendController.clear();
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(store.t(messageKey))));
  }
}

class _FriendRequestsPanel extends StatelessWidget {
  const _FriendRequestsPanel({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final incoming = store.incomingFriendRequests;
    final outgoing = store.outgoingFriendRequests;
    return CatudyPanel(
      accentColor: CatudyColors.coral,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            store.t('social.friendRequests'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          if (incoming.isEmpty && outgoing.isEmpty)
            Text(
              store.t('social.noFriendRequests'),
              style: TextStyle(color: CatudyColors.mutedFor(context)),
            ),
          for (final request in incoming)
            _FriendRequestRow(store: store, request: request, incoming: true),
          for (final request in outgoing)
            _FriendRequestRow(store: store, request: request, incoming: false),
        ],
      ),
    );
  }
}

class _FriendRequestRow extends StatelessWidget {
  const _FriendRequestRow({
    required this.store,
    required this.request,
    required this.incoming,
  });

  final CatudyDemoStore store;
  final FriendRequest request;
  final bool incoming;

  @override
  Widget build(BuildContext context) {
    final profile = store.profileByUserId(
      incoming ? request.fromUserId : request.toUserId,
    );
    final name =
        profile?.name ?? (incoming ? request.fromUserId : request.toUserId);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CatudyColors.coral.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(
            incoming
                ? Icons.mark_email_unread_rounded
                : Icons.schedule_send_rounded,
            color: CatudyColors.coral,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              incoming
                  ? store.t('social.incomingRequestFrom', {'name': name})
                  : store.t('social.outgoingRequestTo', {'name': name}),
              style: TextStyle(
                color: CatudyColors.blueFor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (incoming) ...[
            IconButton(
              tooltip: store.t('common.no'),
              onPressed: () => store.rejectFriendRequest(request.id),
              icon: const Icon(Icons.close_rounded),
            ),
            IconButton.filled(
              tooltip: store.t('common.yes'),
              onPressed: () => store.acceptFriendRequest(request.id),
              icon: const Icon(Icons.check_rounded),
            ),
          ] else ...[
            Text(
              store.t('social.pending'),
              style: TextStyle(
                color: CatudyColors.mutedFor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
            IconButton(
              tooltip: store.t('social.cancelRequest'),
              onPressed: () {
                store.cancelFriendRequest(request.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(store.t('social.requestCancelled'))),
                );
              },
              icon: const Icon(Icons.cancel_schedule_send_rounded),
            ),
          ],
        ],
      ),
    );
  }
}

enum _SocialAction { remove, block, report }

class _SocialProfileRow extends StatelessWidget {
  const _SocialProfileRow({required this.profile, required this.store});

  final LeaderboardProfile profile;
  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: profile.currentUser
            ? CatudyColors.lavenderSoft
            : CatudyColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CatudyColors.violet.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.person_rounded, color: CatudyColors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  profile.currentUser
                      ? '${profile.name} (${store.t('leaderboard.you')})'
                      : profile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CatudyColors.blueFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${profile.totalMinutes}${store.t('common.minutesShort')}',
                style: TextStyle(
                  color: CatudyColors.mutedFor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (!profile.currentUser)
                PopupMenuButton<_SocialAction>(
                  tooltip: store.t('social.moreActions'),
                  onSelected: (action) {
                    final messageKey = switch (action) {
                      _SocialAction.remove => 'social.friendRemoved',
                      _SocialAction.block => 'social.userBlocked',
                      _SocialAction.report => 'social.userReported',
                    };
                    switch (action) {
                      case _SocialAction.remove:
                        store.removeFriend(profile.userId);
                      case _SocialAction.block:
                        store.blockUser(profile.userId);
                      case _SocialAction.report:
                        store.reportUser(profile.userId);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(store.t(messageKey))),
                    );
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _SocialAction.remove,
                      child: Text(store.t('social.removeFriendAction')),
                    ),
                    PopupMenuItem(
                      value: _SocialAction.block,
                      child: Text(store.t('social.blockUser')),
                    ),
                    PopupMenuItem(
                      value: _SocialAction.report,
                      child: Text(store.t('social.reportUser')),
                    ),
                  ],
                ),
            ],
          ),
          if (!profile.currentUser) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _inviteToLobby(context),
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: Text(store.t('social.inviteToLobby')),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: store.t('social.visitPetRoom'),
                    onPressed: () {
                      store.visitPetRoom(profile.userId);
                      context.go('/pet-room');
                    },
                    icon: const Icon(Icons.meeting_room_rounded),
                  ),
                  IconButton(
                    tooltip: store.t('social.visitProfile'),
                    onPressed: () {
                      store.visitProfile(profile.userId);
                      context.go('/public-profile');
                    },
                    icon: const Icon(Icons.visibility_rounded),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _inviteToLobby(BuildContext context) async {
    final code = store.onlineLobbyCode?.trim();
    if (code == null || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(store.t('social.createLobbyFirst'))),
      );
      context.go('/lobby/create');
      return;
    }

    final text = store.t('lobby.inviteText', {'code': code});
    try {
      await SharePlus.instance.share(
        ShareParams(text: text, title: store.t('social.inviteToLobby')),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(store.t('social.lobbyInviteReady'))),
        );
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(store.t('lobby.codeCopied'))));
      }
    }
  }
}
