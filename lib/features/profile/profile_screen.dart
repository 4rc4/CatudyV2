import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/catudy_assets.dart';
import '../../app/demo/catudy_demo_store.dart';
import '../../app/premium/catudy_premium_models.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/catudy_visual_system.dart';
import '../../shared/widgets/shop_item_art.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        final monthRecords = _monthRecords(store.history);
        final monthMinutes = monthRecords.fold(
          0,
          (sum, item) => sum + item.minutes,
        );
        final monthTarget = store.monthlyGoalMinutes;
        final unlockedAchievements = store.unlockedAchievements
            .take(5)
            .toList();
        final collectionItems = store.shopItems
            .where((item) => store.ownedItems.contains(item.id))
            .take(4)
            .toList();
        final collectionCosmetics = store.cosmeticItems
            .where((item) => store.ownedCosmeticIds.contains(item.id))
            .take(4)
            .toList();
        final level = (store.focusPoints ~/ 120) + 1;

        return ScreenScaffold(
          title: store.t('profile.title'),
          actions: [
            IconButton.filledTonal(
              onPressed: () => _shareProfile(context, store),
              icon: const Icon(Icons.ios_share_rounded),
            ),
            IconButton.filledTonal(
              onPressed: () => _editProfile(context, store),
              icon: const Icon(Icons.edit_rounded),
            ),
          ],
          children: [
            _ProfileHeroCard(
              store: store,
              level: level,
              onEdit: () => _editProfile(context, store),
              onCopyCode: () => _copyUserId(context, store),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 370;
                final monthCard = _MonthSummaryCard(
                  store: store,
                  minutes: monthMinutes,
                  target: monthTarget,
                );
                final friendsCard = _FriendsCard(store: store);
                if (compact) {
                  return Column(
                    children: [
                      monthCard,
                      const SizedBox(height: 12),
                      friendsCard,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: monthCard),
                    const SizedBox(width: 12),
                    Expanded(child: friendsCard),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            _AchievementShelf(achievements: unlockedAchievements, store: store),
            const SizedBox(height: 14),
            _CollectionShelf(
              store: store,
              items: collectionItems,
              cosmetics: collectionCosmetics,
            ),
          ],
        );
      },
    );
  }

  static List<FocusRecord> _monthRecords(List<FocusRecord> records) {
    final now = DateTime.now();
    return records
        .where(
          (item) =>
              !item.manual &&
              item.createdAt.year == now.year &&
              item.createdAt.month == now.month,
        )
        .toList();
  }

  static Future<void> _editProfile(
    BuildContext context,
    CatudyDemoStore store,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _ProfileEditDialog(store: store),
    );
  }

  static Future<void> _copyUserId(
    BuildContext context,
    CatudyDemoStore store,
  ) async {
    await Clipboard.setData(ClipboardData(text: store.publicUserCode));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(store.t('profile.idCopied'))));
    }
  }

  static Future<void> _shareProfile(
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

  static String _profileShareLink(CatudyDemoStore store) {
    final userId = Uri.encodeComponent(store.publicUserCode);
    return 'https://catudy.com/public-profile?user=$userId';
  }

  static String _formatMinutes(int minutes, CatudyDemoStore store) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (hours == 0) {
      return '$rest${store.t('common.minutesShort')}';
    }
    return '$hours${store.t('common.hoursShort')} $rest${store.t('common.minutesShort')}';
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.store,
    required this.level,
    required this.onEdit,
    required this.onCopyCode,
  });

  final CatudyDemoStore store;
  final int level;
  final VoidCallback onEdit;
  final VoidCallback onCopyCode;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      padding: const EdgeInsets.all(13),
      accentColor: CatudyColors.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: CatudyColors.blueFor(context),
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            store.publicUserCode,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: CatudyColors.mutedFor(context),
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        SizedBox.square(
                          dimension: 30,
                          child: IconButton.filledTonal(
                            onPressed: onCopyCode,
                            tooltip: store.t('profile.copyId'),
                            padding: EdgeInsets.zero,
                            iconSize: 15,
                            icon: const Icon(Icons.copy_rounded),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: onEdit,
                tooltip: store.t('profile.edit'),
                icon: const Icon(Icons.edit_rounded),
              ),
              const SizedBox(width: 8),
              _ProfileAvatar(store: store, size: 74),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ProfileStatTile(
                  icon: Icons.schedule_rounded,
                  label: store.t('profile.totalFocus'),
                  value: ProfileScreen._formatMinutes(
                    store.totalFocusMinutes,
                    store,
                  ),
                  color: CatudyColors.teal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ProfileStatTile(
                  icon: Icons.local_fire_department_rounded,
                  label: store.t('stats.streak'),
                  value: '${store.streakDays}${store.t('common.daysShort')}',
                  color: CatudyColors.coral,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ProfileStatTile(
                  icon: Icons.star_rounded,
                  label: store.t('profile.levelTitle'),
                  value: '$level',
                  color: CatudyColors.yellow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileStatTile extends StatelessWidget {
  const _ProfileStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CatudyColors.violet.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CatudyColors.mutedFor(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              value,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: CatudyColors.blueFor(context),
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementShelf extends StatelessWidget {
  const _AchievementShelf({required this.achievements, required this.store});

  final List<CatudyAchievement> achievements;
  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      accentColor: CatudyColors.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionRow(
            icon: Icons.emoji_events_rounded,
            title: store.t('achievements.title'),
            action: store.t('profile.viewAll'),
            onTap: () => context.push('/season?from=profile'),
          ),
          const SizedBox(height: 12),
          if (achievements.isEmpty)
            Text(
              store.t('profile.noBadges'),
              style: TextStyle(color: CatudyColors.mutedFor(context)),
            )
          else
            SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: achievements.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  return SizedBox(
                    width: 96,
                    child: CatudyAssetSlot(
                      icon: achievement.icon,
                      accentColor: CatudyColors.violet,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            achievement.icon,
                            color: CatudyColors.violet,
                            size: 28,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            achievement.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: CatudyColors.blueFor(context),
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CollectionShelf extends StatelessWidget {
  const _CollectionShelf({
    required this.store,
    required this.items,
    required this.cosmetics,
  });

  final CatudyDemoStore store;
  final List<ShopItem> items;
  final List<CosmeticItem> cosmetics;

  @override
  Widget build(BuildContext context) {
    final total = items.length + cosmetics.length;
    return CatudyPanel(
      accentColor: CatudyColors.coral,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionRow(
            icon: Icons.collections_bookmark_rounded,
            title: store.t('profile.collection'),
            action: store.t('profile.viewAll'),
            onTap: () => context.push('/inventory'),
          ),
          const SizedBox(height: 12),
          if (total == 0)
            Text(
              store.t('profile.noItems'),
              style: TextStyle(color: CatudyColors.mutedFor(context)),
            )
          else
            SizedBox(
              height: 104,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final item in items) ...[
                    _CollectionItem(
                      title: store.itemName(item),
                      color: item.accent,
                      child: ShopItemArt(item: item, size: 58),
                    ),
                    const SizedBox(width: 10),
                  ],
                  for (final cosmetic in cosmetics) ...[
                    _CollectionItem(
                      title: cosmetic.name,
                      color: cosmetic.accent,
                      child: Icon(
                        cosmetic.icon,
                        color: cosmetic.accent,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthSummaryCard extends StatelessWidget {
  const _MonthSummaryCard({
    required this.store,
    required this.minutes,
    required this.target,
  });

  final CatudyDemoStore store;
  final int minutes;
  final int target;

  @override
  Widget build(BuildContext context) {
    return CatudyStagePanel(
      title: store.t('profile.monthlyTitle'),
      subtitle: store.t('profile.monthlyBody', {
        'minutes': minutes,
        'target': target,
      }),
      icon: Icons.calendar_month_rounded,
      progress: target == 0 ? 0 : (minutes / target).clamp(0.0, 1.0),
      progressLabel: '${((target == 0 ? 0 : minutes / target) * 100).round()}%',
      accentColor: CatudyColors.teal,
      secondaryColor: CatudyColors.violet,
    );
  }
}

class _FriendsCard extends StatelessWidget {
  const _FriendsCard({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return CatudyStagePanel(
      title: store.t('social.friends'),
      subtitle: store.t('profile.friendsBody', {
        'count': store.friendProfiles.length,
      }),
      icon: Icons.groups_rounded,
      accentColor: CatudyColors.violet,
      secondaryColor: CatudyColors.teal,
      actions: [
        FilledButton.icon(
          onPressed: () => context.push('/community?tab=friends&from=profile'),
          icon: const Icon(Icons.chevron_right_rounded),
          label: Text(store.t('community.title')),
        ),
      ],
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.icon,
    required this.title,
    this.action,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: CatudyColors.violet),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: CatudyColors.blueFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (action != null && onTap != null)
          TextButton(onPressed: onTap, child: Text(action!)),
      ],
    );
  }
}

class _CollectionItem extends StatelessWidget {
  const _CollectionItem({
    required this.title,
    required this.child,
    required this.color,
  });

  final String title;
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          Expanded(
            child: CatudyAssetSlot(
              accentColor: color,
              size: 74,
              child: Center(child: child),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
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
        color: CatudyColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(size * 0.31),
        border: Border.all(color: CatudyColors.teal.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: CatudyColors.violet.withValues(alpha: 0.18),
            blurRadius: 24,
          ),
        ],
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
