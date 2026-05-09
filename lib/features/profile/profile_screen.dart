import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/catudy_assets.dart';
import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_info_bubble.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/floating_mascot.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        final owned = store.shopItems
            .where((item) => store.ownedItems.contains(item.id))
            .take(3)
            .toList();
        final favorite = store.favoriteCategory;

        return ScreenScaffold(
          title: store.t('profile.title'),
          children: [
            CatudyPanel(
              color: CatudyColors.cream,
              accentColor: CatudyColors.teal,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          _ProfileAvatar(store: store, size: 108),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: CircleAvatar(
                              radius: 19,
                              backgroundColor: CatudyColors.surface,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => _editProfile(context, store),
                                icon: const Icon(
                                  Icons.edit_rounded,
                                  size: 18,
                                  color: CatudyColors.teal,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    store.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: CatudyColors.blue,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                ),
                                const Icon(
                                  Icons.star_rounded,
                                  color: CatudyColors.teal,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              store.t('profile.subtitle'),
                              style: TextStyle(
                                color: CatudyColors.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: CatudyColors.surface.withValues(
                                  alpha: 0.72,
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                store.t('profile.petMessage', {
                                  'pet': store.selectedPet.name,
                                }),
                                style: const TextStyle(
                                  color: CatudyColors.muted,
                                  height: 1.35,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _ProfileMetric(
                          icon: Icons.hourglass_bottom_rounded,
                          label: store.t('profile.totalFocus'),
                          value: _formatMinutes(store.totalFocusMinutes, store),
                          info:
                              'Hesaptaki tüm odak kayıtlarının toplam süresidir.',
                        ),
                      ),
                      Expanded(
                        child: _ProfileMetric(
                          icon: Icons.local_fire_department_rounded,
                          iconColor: CatudyColors.yellow,
                          label: store.t('stats.streak'),
                          value:
                              '${store.streakDays}${store.t('common.daysShort')}',
                          info: 'Art arda sürdürülen odak günlerini gösterir.',
                        ),
                      ),
                      Expanded(
                        child: _ProfileMetric(
                          icon: Icons.track_changes_rounded,
                          label: store.t('profile.sessions'),
                          value: '${store.sessionsCount}',
                          info:
                              'Manuel olmayan tamamlanmış odak seansı sayısıdır.',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            CatudyPanel(
              accentColor: CatudyColors.violet,
              child: Row(
                children: [
                  const Icon(Icons.badge_rounded, color: CatudyColors.violet),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.t('profile.myId'),
                          style: TextStyle(
                            color: CatudyColors.mutedFor(context),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        SelectableText(
                          store.publicUserId,
                          style: TextStyle(
                            color: CatudyColors.blueFor(context),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _copyUserId(context, store),
                    icon: const Icon(Icons.copy_rounded),
                    label: Text(store.t('profile.copyId')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _ProfileInsightsCard(store: store),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _EquippedItemsCard(items: owned),
                      const SizedBox(height: 12),
                      _WeeklySummaryCard(records: store.history),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      const _PetPreviewCard(),
                      const SizedBox(height: 12),
                      CatudyPanel(
                        accentColor: CatudyColors.teal,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CardTitle(
                              icon: Icons.star_rounded,
                              title: store.t('profile.favoriteCategory'),
                              color: CatudyColors.teal,
                            ),
                            const SizedBox(height: 12),
                            _FavoriteCategoryTile(category: favorite),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editProfile(context, store),
                    icon: const Icon(Icons.edit_rounded),
                    label: Text(store.t('profile.edit')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _shareProfile(context, store),
                    icon: const Icon(Icons.share_rounded),
                    label: Text(store.t('profile.share')),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _editProfile(BuildContext context, CatudyDemoStore store) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _ProfileEditDialog(store: store),
    );
  }

  Future<void> _copyUserId(BuildContext context, CatudyDemoStore store) async {
    await Clipboard.setData(ClipboardData(text: store.publicUserId));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(store.t('profile.idCopied'))));
    }
  }

  Future<void> _shareProfile(
    BuildContext context,
    CatudyDemoStore store,
  ) async {
    store.clearVisitedProfile();
    final link = _profileShareLink(store);
    final text = store.t('profile.shareText', {
      'name': store.displayName,
      'link': link,
    });
    try {
      final renderObject = context.findRenderObject();
      final box = renderObject is RenderBox ? renderObject : null;
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          title: store.t('profile.share'),
          subject: store.t('profile.shareSubject', {'name': store.displayName}),
          sharePositionOrigin: box != null && box.hasSize
              ? box.localToGlobal(Offset.zero) & box.size
              : null,
        ),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(store.t('profile.shareCopied'))));
      }
    }
  }

  String _profileShareLink(CatudyDemoStore store) {
    final userId = Uri.encodeComponent(store.authUserId ?? 'local');
    final configuredBase = _shareOriginFromText(store.profileShareBaseUrl);
    if (configuredBase != null) {
      return '$configuredBase/#/public-profile?user=$userId';
    }
    final base = Uri.base;
    if ((base.scheme == 'http' || base.scheme == 'https') &&
        base.host.isNotEmpty) {
      final port = base.hasPort ? ':${base.port}' : '';
      return '${base.scheme}://${base.host}$port/#/public-profile?user=$userId';
    }
    return 'catudy:///public-profile?user=$userId';
  }

  String? _shareOriginFromText(String value) {
    final clean = value.trim();
    if (clean.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(clean.contains('://') ? clean : 'https://$clean');
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return null;
    }
    final path = uri.path == '/'
        ? ''
        : uri.path.endsWith('/') && uri.path.length > 1
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;
    return Uri(
      scheme: uri.scheme,
      userInfo: uri.userInfo,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: path,
    ).toString();
  }

  String _formatMinutes(int minutes, CatudyDemoStore store) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (hours == 0) {
      return '$rest${store.t('common.minutesShort')}';
    }
    return '$hours${store.t('common.hoursShort')} $rest${store.t('common.minutesShort')}';
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.size,
    this.store,
    this.avatarId,
    this.customAvatarBase64,
  });

  final CatudyDemoStore? store;
  final String? avatarId;
  final String? customAvatarBase64;
  final double size;

  @override
  Widget build(BuildContext context) {
    final effectiveId = avatarId ?? store?.profileAvatarId ?? 'catudy';
    final effectiveCustom =
        customAvatarBase64 ?? store?.customProfileImageBase64;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(effectiveId == 'custom' ? 0 : size * 0.13),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CatudyColors.surface,
        borderRadius: BorderRadius.circular(size * 0.31),
        border: Border.all(color: CatudyColors.teal.withValues(alpha: 0.18)),
      ),
      child: _avatarChild(effectiveId, effectiveCustom),
    );
  }

  Widget _avatarChild(String id, String? customBase64) {
    if (id == 'custom') {
      final bytes = _decodeAvatar(customBase64);
      if (bytes != null) {
        return Image.memory(bytes, fit: BoxFit.cover);
      }
    }
    if (id == 'mochi') {
      return Image.asset(CatudyAssets.mascot, fit: BoxFit.contain);
    }
    if (id == 'study') {
      return const Icon(Icons.menu_book_rounded, color: CatudyColors.violet);
    }
    if (id == 'star') {
      return const Icon(Icons.star_rounded, color: CatudyColors.yellow);
    }
    return Image.asset(CatudyAssets.logo, fit: BoxFit.contain);
  }
}

class _ProfileEditDialog extends StatefulWidget {
  const _ProfileEditDialog({required this.store});

  final CatudyDemoStore store;

  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<_ProfileEditDialog> {
  late final TextEditingController _nameController;
  late String _avatarId;
  String? _customAvatarBase64;
  bool _pickingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.store.displayName);
    _avatarId = widget.store.profileAvatarId;
    _customAvatarBase64 = widget.store.customProfileImageBase64;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return AlertDialog(
      title: Text(store.t('profile.editTitle')),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(labelText: store.t('profile.name')),
              ),
              const SizedBox(height: 18),
              Text(
                store.t('profile.chooseAvatar'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final id in const ['catudy', 'mochi', 'study', 'star'])
                    _ProfileAvatarOption(
                      avatarId: id,
                      selected: _avatarId == id,
                      onTap: () => setState(() => _avatarId = id),
                    ),
                  if (_customAvatarBase64 != null)
                    _ProfileAvatarOption(
                      avatarId: 'custom',
                      customAvatarBase64: _customAvatarBase64,
                      selected: _avatarId == 'custom',
                      onTap: () => setState(() => _avatarId = 'custom'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickingImage ? null : _pickCustomImage,
                icon: _pickingImage
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_photo_alternate_rounded),
                label: Text(store.t('profile.uploadAvatar')),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(store.t('common.cancel')),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(store.t('profile.saveProfile')),
        ),
      ],
    );
  }

  Future<void> _pickCustomImage() async {
    setState(() => _pickingImage = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        imageQuality: 80,
      );
      if (image == null) {
        return;
      }
      final bytes = await image.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() {
        _customAvatarBase64 = base64Encode(bytes);
        _avatarId = 'custom';
      });
    } finally {
      if (mounted) {
        setState(() => _pickingImage = false);
      }
    }
  }

  void _save() {
    widget.store.updateProfile(
      name: _nameController.text,
      avatarId: _avatarId,
      customAvatarBase64: _customAvatarBase64,
    );
    Navigator.of(context).pop();
  }
}

class _ProfileAvatarOption extends StatelessWidget {
  const _ProfileAvatarOption({
    required this.avatarId,
    required this.selected,
    required this.onTap,
    this.customAvatarBase64,
  });

  final String avatarId;
  final String? customAvatarBase64;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? CatudyColors.teal : Colors.transparent,
                width: 2,
              ),
            ),
            child: _ProfileAvatar(
              avatarId: avatarId,
              customAvatarBase64: customAvatarBase64,
              size: 58,
            ),
          ),
          if (selected)
            const Positioned(
              right: 0,
              bottom: 0,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: CatudyColors.teal,
                child: Icon(Icons.check_rounded, size: 14, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

Uint8List? _decodeAvatar(String? base64Value) {
  if (base64Value == null || base64Value.isEmpty) {
    return null;
  }
  try {
    return base64Decode(base64Value);
  } catch (_) {
    return null;
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.info,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String info;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return CatudyInfoTap(
      title: label,
      message: info,
      child: Column(
        children: [
          Icon(icon, color: iconColor ?? CatudyColors.teal, size: 28),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: CatudyColors.blueFor(context),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EquippedItemsCard extends StatelessWidget {
  const _EquippedItemsCard({required this.items});

  final List<ShopItem> items;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.shopping_bag_rounded,
            title: catudyDemoStore.t('profile.equippedItems'),
            color: CatudyColors.teal,
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              catudyDemoStore.t('profile.noItems'),
              style: TextStyle(color: CatudyColors.muted),
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: item.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.icon, color: item.accent),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        catudyDemoStore.itemName(item),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () => context.go('/inventory'),
            icon: const Icon(Icons.chevron_right_rounded),
            label: Text(catudyDemoStore.t('profile.viewAll')),
          ),
        ],
      ),
    );
  }
}

class _ProfileInsightsCard extends StatelessWidget {
  const _ProfileInsightsCard({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final unlocked = store.unlockedAchievements.take(4).toList();
    final goal = store.todayGoalProgress;
    return CatudyPanel(
      accentColor: CatudyColors.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.auto_graph_rounded,
            title: store.t('profile.richStats'),
            color: CatudyColors.violet,
          ),
          const SizedBox(height: 12),
          _MiniWeekChart(minutes: store.lastSevenDayMinutes),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InsightChip(
                icon: Icons.local_fire_department_rounded,
                label: store.t('profile.bestStreak', {
                  'days': store.bestStreakDays,
                }),
              ),
              _InsightChip(
                icon: Icons.track_changes_rounded,
                label: store.t('profile.todayGoalShort', {
                  'done': goal.completedMinutes,
                  'goal': goal.goalMinutes,
                }),
              ),
              _InsightChip(
                icon: Icons.star_rounded,
                label: store.t('profile.favorite', {
                  'category': store.favoriteCategory.name,
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            store.t('profile.badges'),
            style: TextStyle(
              color: CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          if (unlocked.isEmpty)
            Text(
              store.t('profile.noBadges'),
              style: TextStyle(color: CatudyColors.mutedFor(context)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final achievement in unlocked)
                  Chip(
                    avatar: Icon(
                      achievement.icon,
                      size: 17,
                      color: CatudyColors.teal,
                    ),
                    label: Text(achievement.title),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 17, color: CatudyColors.violet),
      label: Text(label),
    );
  }
}

class _MiniWeekChart extends StatelessWidget {
  const _MiniWeekChart({required this.minutes});

  final List<int> minutes;

  @override
  Widget build(BuildContext context) {
    final maxMinutes = minutes.fold(
      1,
      (max, value) => value > max ? value : max,
    );
    const labels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return SizedBox(
      height: 96,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < minutes.length; index++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: (minutes[index] / maxMinutes).clamp(
                            0.08,
                            1.0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: CatudyColors.teal.withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[index.clamp(0, labels.length - 1)],
                      style: TextStyle(
                        color: CatudyColors.mutedFor(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PetPreviewCard extends StatelessWidget {
  const _PetPreviewCard();

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) => CatudyPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardTitle(
              icon: Icons.pets_rounded,
              title: catudyDemoStore.t('profile.myPet'),
              color: CatudyColors.teal,
            ),
            const SizedBox(height: 8),
            const Center(child: FloatingMascot(width: 96, height: 96)),
            Center(
              child: Text(
                store.selectedPet.name,
                style: TextStyle(
                  color: CatudyColors.blueFor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Center(
              child: Text(
                catudyDemoStore.t('profile.focusBuddy'),
                style: TextStyle(color: CatudyColors.muted),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                store.clearVisitedRoom();
                context.go('/pet-room');
              },
              icon: const Icon(Icons.chevron_right_rounded),
              label: Text(catudyDemoStore.t('profile.petRoom')),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteCategoryTile extends StatelessWidget {
  const _FavoriteCategoryTile({required this.category});

  final FocusCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: category.color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(Icons.menu_book_rounded, color: category.color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CatudyColors.blue,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  const _WeeklySummaryCard({required this.records});

  final List<FocusRecord> records;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final values = <int>[];
    for (var index = 6; index >= 0; index--) {
      final day = now.subtract(Duration(days: index));
      values.add(
        records
            .where(
              (item) =>
                  item.createdAt.year == day.year &&
                  item.createdAt.month == day.month &&
                  item.createdAt.day == day.day,
            )
            .fold(0, (sum, item) => sum + item.minutes),
      );
    }
    final total = values.fold(0, (sum, value) => sum + value);
    final sessions = records
        .where((item) => now.difference(item.createdAt).inDays < 7)
        .length;
    final max = values.fold(1, (max, value) => value > max ? value : max);

    return CatudyPanel(
      accentColor: CatudyColors.lavender,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.bar_chart_rounded,
            title: catudyDemoStore.t('profile.weeklySummary'),
            color: CatudyColors.violet,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: catudyDemoStore.t('home.focus'),
            value: _formatMinutes(total),
          ),
          _SummaryRow(
            label: catudyDemoStore.t('profile.sessions'),
            value: '$sessions',
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final value in values)
                  Expanded(
                    child: CatudyInfoTap(
                      title: catudyDemoStore.t('profile.dailyFocus'),
                      message: value == 0
                          ? 'Bu gün için kayıtlı odak yok.'
                          : 'Bu gün toplam $value dakika odak kaydı var.',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                          height: 14 + (34 * (value / max)),
                          decoration: BoxDecoration(
                            color: CatudyColors.teal.withValues(alpha: 0.36),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (hours == 0) {
      return '$rest${catudyDemoStore.t('common.minutesShort')}';
    }
    return '$hours${catudyDemoStore.t('common.hoursShort')} $rest${catudyDemoStore.t('common.minutesShort')}';
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: CatudyColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: CatudyColors.blue,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: CatudyColors.muted,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
