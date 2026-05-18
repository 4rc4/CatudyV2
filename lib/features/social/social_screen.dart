import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/catudy_section_header.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) => ScreenScaffold(
        title: store.t('social.title'),
        showBack: true,
        fallbackBackPath: '/',
        children: const [FriendsCommunitySection()],
      ),
    );
  }
}

class FriendsCommunitySection extends StatefulWidget {
  const FriendsCommunitySection({super.key});

  @override
  State<FriendsCommunitySection> createState() =>
      _FriendsCommunitySectionState();
}

class _FriendsCommunitySectionState extends State<FriendsCommunitySection> {
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
        return Column(
          children: [
            _SocialHero(
              store: store,
              challenge: challenge,
              friendCount: friends.length,
            ),
            const SizedBox(height: 14),
            _LobbyActions(store: store),
            const SizedBox(height: 14),
            CatudyPanel(
              accentColor: CatudyColors.violet,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CatudySectionHeader(
                    title: store.t('social.addByNameTitle'),
                    icon: Icons.person_add_alt_1_rounded,
                    accentColor: CatudyColors.violet,
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final field = TextField(
                        controller: _friendController,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: store.t('social.friendSearchLabel'),
                          hintText: store.t('social.friendSearchHint'),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.badge_rounded),
                        ),
                        onSubmitted: (_) => _sendFriendRequest(context, store),
                      );
                      final button = SizedBox(
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
                      );

                      if (constraints.maxWidth < 420) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [field, const SizedBox(height: 10), button],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: field),
                          const SizedBox(width: 10),
                          button,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _FriendRequestsPanel(store: store),
            const SizedBox(height: 14),
            CatudyPanel(
              accentColor: CatudyColors.teal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CatudySectionHeader(
                    title: store.t('social.friends'),
                    icon: Icons.people_alt_rounded,
                    accentColor: CatudyColors.teal,
                  ),
                  const SizedBox(height: 10),
                  if (friends.isEmpty)
                    Text(
                      store.t('social.noFriends'),
                      style: TextStyle(color: CatudyColors.mutedFor(context)),
                    )
                  else
                    _FriendGrid(
                      children: [
                        for (final profile in friends)
                          _SocialProfileCard(profile: profile, store: store),
                      ],
                    ),
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

class _SocialHero extends StatelessWidget {
  const _SocialHero({
    required this.store,
    required this.challenge,
    required this.friendCount,
  });

  final CatudyDemoStore store;
  final SocialChallenge challenge;
  final int friendCount;

  @override
  Widget build(BuildContext context) {
    final requestCount =
        store.incomingFriendRequests.length +
        store.outgoingFriendRequests.length;
    return CatudyPanel(
      color: CatudyColors.cream,
      accentColor: CatudyColors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CatudySectionHeader(
            title: challenge.title,
            subtitle: challenge.description,
            icon: Icons.groups_rounded,
            accentColor: CatudyColors.teal,
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SocialMetric(
                  icon: Icons.people_alt_rounded,
                  value: '$friendCount',
                  label: store.t('social.friendCount'),
                  color: CatudyColors.teal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SocialMetric(
                  icon: Icons.mark_email_unread_rounded,
                  value: '$requestCount',
                  label: store.t('social.friendRequests'),
                  color: CatudyColors.coral,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SocialMetric(
                  icon: Icons.groups_rounded,
                  value: '${challenge.participants}',
                  label: store.t('social.participants'),
                  color: CatudyColors.violet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialMetric extends StatelessWidget {
  const _SocialMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: CatudyColors.blueFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: CatudyColors.mutedFor(context),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LobbyActions extends StatelessWidget {
  const _LobbyActions({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final createButton = FilledButton.icon(
          onPressed: () => context.go('/lobby/create'),
          icon: const Icon(Icons.add_home_rounded),
          label: Text(store.t('home.createLobby')),
        );
        final joinButton = FilledButton.tonalIcon(
          onPressed: () => context.go('/lobby/join'),
          icon: const Icon(Icons.login_rounded),
          label: Text(store.t('home.joinLobby')),
        );

        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [createButton, const SizedBox(height: 10), joinButton],
          );
        }

        return Row(
          children: [
            Expanded(child: createButton),
            const SizedBox(width: 10),
            Expanded(child: joinButton),
          ],
        );
      },
    );
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
          CatudySectionHeader(
            title: store.t('social.friendRequests'),
            icon: Icons.mark_email_unread_rounded,
            accentColor: CatudyColors.coral,
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
        profile?.name ??
        store.displayUserId(incoming ? request.fromUserId : request.toUserId);
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

class _FriendGrid extends StatelessWidget {
  const _FriendGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final columns = constraints.maxWidth >= 620 ? 2 : 1;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _SocialProfileCard extends StatelessWidget {
  const _SocialProfileCard({required this.profile, required this.store});

  final LeaderboardProfile profile;
  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: profile.currentUser
            ? CatudyColors.lavenderSoft
            : CatudyColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CatudyColors.violet.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: CatudyColors.teal.withValues(alpha: 0.16),
                child: const Icon(
                  Icons.person_rounded,
                  color: CatudyColors.teal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
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
                    Text(
                      '${profile.totalMinutes}${store.t('common.minutesShort')}',
                      style: TextStyle(
                        color: CatudyColors.mutedFor(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _inviteToLobby(context),
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: Text(store.t('social.inviteToLobby')),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: store.t('social.visitPetRoom'),
                  onPressed: () {
                    store.visitPetRoom(profile.userId);
                    context.go('/pet-room');
                  },
                  icon: const Icon(Icons.meeting_room_rounded),
                ),
                const SizedBox(width: 4),
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
