import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/premium/catudy_premium_models.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_filter_tabs.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/catudy_section_header.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/shop_item_art.dart';
import '../../shared/widgets/store_builder.dart';

enum _ShopCategory { room, pet, profile, extras }

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  _ShopCategory _category = _ShopCategory.room;

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        final roomItems = store.roomFurnitureItems.toList();
        final petItems = store.shopItems
            .where((item) => item.slot == 'pet')
            .toList();
        final profileItems = store.shopItems
            .where((item) => item.slot == 'profile')
            .toList();
        final petStyles = _cosmeticsFor(store, {'pet_style'});
        final roomEffects = _cosmeticsFor(store, {'room_effect'});
        final profileStyles = _cosmeticsFor(store, {
          'profile_theme',
          'profile_badge',
        });
        final extras = _cosmeticsFor(store, {'widget_theme', 'dialogue_pack'});

        return ScreenScaffold(
          title: store.t('shop.title'),
          showBack: true,
          fallbackBackPath: '/pet-room',
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Chip(
                label: Text('${store.gold} ${store.t('common.gold')}'),
              ),
            ),
          ],
          children: [
            _ShopWalletSummary(store: store),
            const SizedBox(height: 14),
            CatudyFilterTabs<_ShopCategory>(
              selected: _category,
              onChanged: (category) => setState(() => _category = category),
              tabs: [
                CatudyFilterTab(
                  value: _ShopCategory.room,
                  label: store.t('shop.category.room'),
                  icon: Icons.weekend_rounded,
                  count: roomItems.length + roomEffects.length,
                ),
                CatudyFilterTab(
                  value: _ShopCategory.pet,
                  label: store.t('shop.category.pet'),
                  icon: Icons.pets_rounded,
                  count:
                      store.unlockablePets.length +
                      petItems.length +
                      petStyles.length,
                ),
                CatudyFilterTab(
                  value: _ShopCategory.profile,
                  label: store.t('shop.category.profile'),
                  icon: Icons.badge_rounded,
                  count: profileItems.length + profileStyles.length,
                ),
                CatudyFilterTab(
                  value: _ShopCategory.extras,
                  label: store.t('shop.category.extras'),
                  icon: Icons.auto_awesome_rounded,
                  count: extras.length,
                ),
              ],
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: Column(
                key: ValueKey(_category),
                children: switch (_category) {
                  _ShopCategory.room => _roomChildren(
                    store,
                    roomItems: roomItems,
                    roomEffects: roomEffects,
                  ),
                  _ShopCategory.pet => _petChildren(
                    store,
                    petItems: petItems,
                    petStyles: petStyles,
                  ),
                  _ShopCategory.profile => _profileChildren(
                    store,
                    profileItems: profileItems,
                    profileStyles: profileStyles,
                  ),
                  _ShopCategory.extras => _extraChildren(store, extras: extras),
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _roomChildren(
    CatudyDemoStore store, {
    required List<ShopItem> roomItems,
    required List<CosmeticItem> roomEffects,
  }) {
    final children = <Widget>[];
    for (final slot in const [
      'room_study',
      'room_bed',
      'room_decor',
      'room_shelf',
    ]) {
      final items = roomItems.where((item) => item.slot == slot).toList();
      if (items.isEmpty) {
        continue;
      }
      children.add(
        _CatalogPanel(
          title: _roomSlotTitle(store, slot),
          icon: _roomSlotIcon(slot),
          accentColor: _roomSlotColor(slot),
          children: [
            for (final item in items) _ShopItemCard(store: store, item: item),
          ],
        ),
      );
      children.add(const SizedBox(height: 12));
    }
    if (roomEffects.isNotEmpty) {
      children.add(
        _CatalogPanel(
          title: store.t('shop.section.roomEffects'),
          icon: Icons.auto_awesome_motion_rounded,
          accentColor: CatudyColors.violet,
          children: [
            for (final item in roomEffects)
              _PremiumCosmeticCard(store: store, item: item),
          ],
        ),
      );
    }
    return children;
  }

  List<Widget> _petChildren(
    CatudyDemoStore store, {
    required List<ShopItem> petItems,
    required List<CosmeticItem> petStyles,
  }) {
    return [
      _CatalogPanel(
        title: store.t('shop.petUnlocks'),
        icon: Icons.pets_rounded,
        accentColor: CatudyColors.coral,
          children: [
            for (final pet in store.unlockablePets)
              _PetUnlockCard(
                name: pet.name,
                description: pet.description,
              accent: pet.accent,
              requiredPoints: pet.requiredPoints,
              currentPoints: store.focusPoints,
              unlocked: store.unlockedPetIds.contains(pet.id),
            ),
        ],
      ),
      const SizedBox(height: 12),
      if (petItems.isNotEmpty) ...[
        _CatalogPanel(
          title: store.t('shop.section.petItems'),
          icon: Icons.checkroom_rounded,
          accentColor: CatudyColors.teal,
          children: [
            for (final item in petItems) _ShopItemCard(store: store, item: item),
          ],
        ),
        const SizedBox(height: 12),
      ],
      if (petStyles.isNotEmpty)
        _CatalogPanel(
          title: store.t('shop.section.petStyles'),
          icon: Icons.auto_awesome_rounded,
          accentColor: CatudyColors.violet,
          children: [
            for (final item in petStyles)
              _PremiumCosmeticCard(store: store, item: item),
          ],
        ),
    ];
  }

  List<Widget> _profileChildren(
    CatudyDemoStore store, {
    required List<ShopItem> profileItems,
    required List<CosmeticItem> profileStyles,
  }) {
    return [
      if (profileItems.isNotEmpty) ...[
        _CatalogPanel(
          title: store.t('shop.section.profileItems'),
          icon: Icons.military_tech_rounded,
          accentColor: CatudyColors.teal,
          children: [
            for (final item in profileItems)
              _ShopItemCard(store: store, item: item),
          ],
        ),
        const SizedBox(height: 12),
      ],
      if (profileStyles.isNotEmpty)
        _CatalogPanel(
          title: store.t('shop.section.profileStyles'),
          icon: Icons.crop_square_rounded,
          accentColor: CatudyColors.coral,
          children: [
            for (final item in profileStyles)
              _PremiumCosmeticCard(store: store, item: item),
          ],
        ),
    ];
  }

  List<Widget> _extraChildren(
    CatudyDemoStore store, {
    required List<CosmeticItem> extras,
  }) {
    return [
      _CratesPromoPanel(store: store),
      const SizedBox(height: 12),
      if (extras.isNotEmpty)
        _CatalogPanel(
          title: store.t('shop.section.extras'),
          icon: Icons.widgets_rounded,
          accentColor: CatudyColors.violet,
          children: [
            for (final item in extras)
              _PremiumCosmeticCard(store: store, item: item),
          ],
        ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () => context.go('/inventory'),
        icon: const Icon(Icons.inventory_2_rounded),
        label: Text(store.t('shop.openInventory')),
      ),
    ];
  }

  List<CosmeticItem> _cosmeticsFor(CatudyDemoStore store, Set<String> slots) {
    return store.directPurchaseCosmetics
        .where((item) => slots.contains(item.slot))
        .toList();
  }

  String _roomSlotTitle(CatudyDemoStore store, String slot) {
    return switch (slot) {
      'room_study' => store.t('shop.room.slot.study'),
      'room_bed' => store.t('shop.room.slot.bed'),
      'room_decor' => store.t('shop.room.slot.decor'),
      'room_shelf' => store.t('shop.room.slot.shelf'),
      _ => store.t('shop.roomFurniture'),
    };
  }

  IconData _roomSlotIcon(String slot) {
    return switch (slot) {
      'room_study' => Icons.auto_stories_rounded,
      'room_bed' => Icons.bed_rounded,
      'room_decor' => Icons.lightbulb_rounded,
      'room_shelf' => Icons.menu_book_rounded,
      _ => Icons.weekend_rounded,
    };
  }

  Color _roomSlotColor(String slot) {
    return switch (slot) {
      'room_study' => CatudyColors.teal,
      'room_bed' => CatudyColors.lavender,
      'room_decor' => CatudyColors.yellow,
      'room_shelf' => CatudyColors.tealDark,
      _ => CatudyColors.violet,
    };
  }
}

class _CatalogPanel extends StatelessWidget {
  const _CatalogPanel({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      accentColor: accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CatudySectionHeader(
            title: title,
            icon: icon,
            accentColor: accentColor,
          ),
          const SizedBox(height: 12),
          _ProductGrid(children: children),
        ],
      ),
    );
  }
}

class _ShopWalletSummary extends StatelessWidget {
  const _ShopWalletSummary({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      color: CatudyColors.cream,
      accentColor: CatudyColors.teal,
      child: Row(
        children: [
          Expanded(
            child: _ShopMetric(
              icon: Icons.monetization_on_rounded,
              value: '${store.gold}',
              label: store.t('common.gold'),
              color: CatudyColors.yellow,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ShopMetric(
              icon: Icons.bolt_rounded,
              value: '${store.focusPoints}',
              label: store.t('common.points'),
              color: CatudyColors.teal,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopMetric extends StatelessWidget {
  const _ShopMetric({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: CatudyColors.blueFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: CatudyColors.mutedFor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({required this.store, required this.item});

  final CatudyDemoStore store;
  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final owned = store.ownedItems.contains(item.id);
    return _ProductCard(
      accent: item.accent,
      art: ShopItemArt(item: item, size: 92),
      title: store.itemName(item),
      body: store.itemDescription(item),
      chips: [
        _MetaChip(label: item.rarity),
        if (item.isRoomFurniture)
          _MetaChip(
            label:
                '+${store.rewardBoostPercentFor(item).toStringAsFixed(1)}% '
                '${store.t('shop.rewardBoost')}',
          ),
        _MetaChip(label: '${item.price} ${store.t('common.gold')}'),
      ],
      action: FilledButton(
        onPressed: owned ? null : () => store.buyItem(item.id),
        child: Text(owned ? store.t('shop.owned') : store.t('shop.buy')),
      ),
    );
  }
}

class _PremiumCosmeticCard extends StatelessWidget {
  const _PremiumCosmeticCard({required this.store, required this.item});

  final CatudyDemoStore store;
  final CosmeticItem item;

  @override
  Widget build(BuildContext context) {
    final owned = store.ownedCosmeticIds.contains(item.id);
    final locked = item.premiumOnly && !store.hasPremiumAccess;
    return _ProductCard(
      accent: item.accent,
      art: _CosmeticArt(item: item),
      title: item.name,
      body: item.description,
      chips: [
        _MetaChip(label: item.rarity.code),
        if (item.premiumOnly) _MetaChip(label: store.t('shop.plusOnly')),
        if (item.directPrice != null)
          _MetaChip(label: '${item.directPrice} ${store.t('common.gold')}'),
      ],
      action: FilledButton(
        onPressed: owned || locked ? null : () => store.buyCosmetic(item.id),
        child: Text(
          owned
              ? store.t('shop.owned')
              : locked
              ? store.t('shop.plusOnly')
              : store.t('shop.buy'),
        ),
      ),
    );
  }
}

class _PetUnlockCard extends StatelessWidget {
  const _PetUnlockCard({
    required this.name,
    required this.description,
    required this.accent,
    required this.requiredPoints,
    required this.currentPoints,
    required this.unlocked,
  });

  final String name;
  final String description;
  final Color accent;
  final int requiredPoints;
  final int currentPoints;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final progress = requiredPoints == 0
        ? 1.0
        : (currentPoints / requiredPoints).clamp(0.0, 1.0);
    return _ProductCard(
      accent: accent,
      art: Icon(Icons.pets_rounded, color: accent, size: 54),
      title: name,
      body: description,
      chips: [
        _MetaChip(
          label: unlocked
              ? catudyDemoStore.t('shop.unlocked')
              : '$currentPoints/$requiredPoints',
        ),
      ],
      progress: progress,
      action: FilledButton(
        onPressed: null,
        child: Text(
          unlocked
              ? catudyDemoStore.t('shop.unlocked')
              : '$currentPoints/$requiredPoints',
        ),
      ),
    );
  }
}

class _CratesPromoPanel extends StatelessWidget {
  const _CratesPromoPanel({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      color: CatudyColors.lavenderSoft,
      accentColor: CatudyColors.violet,
      child: Row(
        children: [
          const Icon(Icons.inventory_2_rounded, color: CatudyColors.violet),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              store.t('shop.cratesBody'),
              style: TextStyle(
                color: CatudyColors.mutedFor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.go('/crates'),
            child: Text(store.t('shop.openCrates')),
          ),
        ],
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final columns = constraints.maxWidth >= 640
            ? 3
            : constraints.maxWidth >= 330
            ? 2
            : 1;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
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

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.art,
    required this.title,
    required this.body,
    required this.chips,
    required this.action,
    required this.accent,
    this.progress,
  });

  final Widget art;
  final String title;
  final String body;
  final List<Widget> chips;
  final Widget action;
  final Color accent;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.78,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: CatudyColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(child: art),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: CatudyColors.blueFor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: CatudyColors.mutedFor(context),
                fontSize: 12,
                height: 1.18,
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  color: accent,
                  backgroundColor: CatudyColors.surfaceStrongFor(context),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(spacing: 5, runSpacing: 5, children: chips),
            const SizedBox(height: 8),
            SizedBox(height: 38, child: action),
          ],
        ),
      ),
    );
  }
}

class _CosmeticArt extends StatelessWidget {
  const _CosmeticArt({required this.item});

  final CosmeticItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: item.accent.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(item.icon, color: item.accent, size: 42),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceStrongFor(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: CatudyColors.mutedFor(context),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
