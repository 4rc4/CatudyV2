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

enum _ShopCategory { room, pet, profile, crates, extras }

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
                  icon: Icons.imagesearch_roller_rounded,
                  count: roomEffects.length,
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
                  value: _ShopCategory.crates,
                  label: store.t('shop.category.crates'),
                  icon: Icons.inventory_2_rounded,
                  count: store.lootCrates
                      .where((crate) => !crate.seasonal)
                      .length,
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
                  _ShopCategory.crates => _crateChildren(store),
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
    required List<CosmeticItem> roomEffects,
  }) {
    return [
      if (roomEffects.isNotEmpty)
        _CatalogPanel(
          title: store.t('shop.section.roomBackgrounds'),
          icon: Icons.auto_awesome_motion_rounded,
          accentColor: CatudyColors.violet,
          children: [
            for (final item in roomEffects)
              _PremiumCosmeticCard(store: store, item: item),
          ],
        )
      else
        CatudyPanel(
          accentColor: CatudyColors.violet,
          child: Text(store.t('shop.noRoomBackgrounds')),
        ),
    ];
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
            for (final item in petItems)
              _ShopItemCard(store: store, item: item),
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
        onPressed: () => context.push('/inventory'),
        icon: const Icon(Icons.inventory_2_rounded),
        label: Text(store.t('shop.openInventory')),
      ),
    ];
  }

  List<Widget> _crateChildren(CatudyDemoStore store) {
    return [
      _CratesPromoPanel(store: store),
      const SizedBox(height: 12),
      _CatalogPanel(
        title: store.t('shop.category.crates'),
        icon: Icons.inventory_2_rounded,
        accentColor: CatudyColors.teal,
        children: [
          for (final crate in store.lootCrates.where(
            (crate) => !crate.seasonal,
          ))
            _CrateCard(store: store, crate: crate),
        ],
      ),
    ];
  }

  List<CosmeticItem> _cosmeticsFor(CatudyDemoStore store, Set<String> slots) {
    return store.directPurchaseCosmetics
        .where((item) => slots.contains(item.slot))
        .toList();
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
              icon: Icons.savings_rounded,
              value: '${store.gold}',
              label: store.t('common.gold'),
              color: CatudyColors.violet,
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
      art: ShopItemArt(item: item, size: 52),
      title: store.itemName(item),
      body: store.itemDescription(item),
      chips: [
        _MetaChip(label: item.rarity),
        if (item.hasVariants)
          _MetaChip(
            label: store.languageCode == 'tr'
                ? '${item.variants.length} stil'
                : '${item.variants.length} styles',
          ),
        if (item.isRoomFurniture)
          _MetaChip(
            label:
                '+${store.rewardBoostPercentFor(item).toStringAsFixed(1)}% '
                '${store.t('shop.rewardBoost')}',
          ),
        _MetaChip(label: '${item.price} ${store.t('common.gold')}'),
      ],
      action: FilledButton(
        onPressed: owned
            ? () =>
                  context.go(item.isRoomFurniture ? '/pet-room' : '/inventory')
            : () => store.buyItem(item.id),
        child: Text(
          owned
              ? item.isRoomFurniture
                    ? store.t('profile.petRoom')
                    : store.t('pet.inventory')
              : store.t('shop.buy'),
        ),
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
        onPressed: owned
            ? () => context.push('/inventory')
            : locked
            ? null
            : () => store.buyCosmetic(item.id),
        child: Text(
          owned
              ? store.t('pet.inventory')
              : locked
              ? store.t('shop.plusOnly')
              : store.t('shop.buy'),
        ),
      ),
    );
  }
}

class _CrateCard extends StatelessWidget {
  const _CrateCard({required this.store, required this.crate});

  final CatudyDemoStore store;
  final LootCrate crate;

  @override
  Widget build(BuildContext context) {
    final owned = store.crateInventory[crate.id] ?? 0;
    final accent = switch (crate.type) {
      LootCrateType.cat => CatudyColors.coral,
      LootCrateType.room => CatudyColors.violet,
      LootCrateType.style => CatudyColors.teal,
    };
    return _ProductCard(
      accent: accent,
      art: Icon(Icons.inventory_2_rounded, color: accent, size: 34),
      title: crate.name,
      body: crate.description,
      chips: [
        _MetaChip(label: '${crate.price} ${store.t('common.points')}'),
        if (owned > 0) _MetaChip(label: 'x$owned'),
      ],
      action: FilledButton(
        onPressed: () => context.push('/crates'),
        child: Text(store.t('shop.openCrates')),
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
      art: Icon(Icons.pets_rounded, color: accent, size: 34),
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
            onPressed: () => context.push('/crates'),
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
        const spacing = 6.0;
        final columns = constraints.maxWidth >= 300 ? 2 : 1;
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
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: FittedBox(fit: BoxFit.contain, child: art),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: CatudyColors.blueFor(context),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: CatudyColors.mutedFor(context),
                        fontSize: 10.5,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(spacing: 3, runSpacing: 3, children: chips),
                  ],
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                color: accent,
                backgroundColor: CatudyColors.surfaceStrongFor(context),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Theme(
            data: Theme.of(context).copyWith(
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            child: SizedBox(height: 30, child: action),
          ),
        ],
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
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: item.accent.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(item.icon, color: item.accent, size: 24),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceStrongFor(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: CatudyColors.mutedFor(context),
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
