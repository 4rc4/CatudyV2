import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/premium/catudy_premium_models.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/catudy_pet_avatar.dart';
import '../../shared/widgets/catudy_section_header.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/shop_item_art.dart';
import '../../shared/widgets/store_builder.dart';

enum _ShopCategory { room, accessories, cats, profile }

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  _ShopCategory _category = _ShopCategory.accessories;

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        final roomItems = store.shopItems
            .where((item) => item.isRoomFurniture)
            .toList();
        final accessoryItems = store.shopItems
            .where((item) => item.isPetAccessory)
            .toList();
        final profileItems = store.shopItems
            .where((item) => item.slot == 'profile')
            .toList();
        final profileStyles = _cosmeticsFor(store, {
          'profile_theme',
          'profile_badge',
        });

        return ScreenScaffold(
          title: store.t('shop.title'),
          showBack: true,
          fallbackBackPath: '/pet-room',
          children: [
            _ShopWalletSummary(store: store),
            const SizedBox(height: 14),
            _CategoryBar<_ShopCategory>(
              selected: _category,
              onChanged: (category) => setState(() => _category = category),
              tabs: [
                _CategoryTab(
                  value: _ShopCategory.room,
                  label: store.t('shop.category.room'),
                  icon: Icons.weekend_rounded,
                  count: roomItems.length,
                ),
                _CategoryTab(
                  value: _ShopCategory.accessories,
                  label: store.t('shop.category.accessories'),
                  icon: Icons.checkroom_rounded,
                  count: accessoryItems.length,
                ),
                _CategoryTab(
                  value: _ShopCategory.cats,
                  label: store.t('shop.category.cats'),
                  icon: Icons.pets_rounded,
                  count: store.unlockablePets.length,
                ),
                _CategoryTab(
                  value: _ShopCategory.profile,
                  label: store.t('shop.category.profile'),
                  icon: Icons.badge_rounded,
                  count: profileItems.length + profileStyles.length,
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
                  ),
                  _ShopCategory.accessories => _accessoryChildren(
                    store,
                    accessoryItems: accessoryItems,
                  ),
                  _ShopCategory.cats => _catChildren(store),
                  _ShopCategory.profile => _profileChildren(
                    store,
                    profileItems: profileItems,
                    profileStyles: profileStyles,
                  ),
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
  }) {
    if (roomItems.isEmpty) {
      return [_CatalogEmptyPanel(message: store.t('inventory.emptyCategory'))];
    }
    return [
      _CatalogPanel(
        title: store.t('shop.roomFurniture'),
        icon: Icons.weekend_rounded,
        accentColor: CatudyColors.teal,
        children: [
          for (final item in roomItems) _ShopItemCard(store: store, item: item),
        ],
      ),
    ];
  }

  List<Widget> _accessoryChildren(
    CatudyDemoStore store, {
    required List<ShopItem> accessoryItems,
  }) {
    return [
      _CatalogPanel(
        title: store.t('shop.section.accessories'),
        icon: Icons.checkroom_rounded,
        accentColor: CatudyColors.violet,
        children: [
          for (final item in accessoryItems)
            _ShopItemCard(store: store, item: item),
        ],
      ),
    ];
  }

  List<Widget> _catChildren(CatudyDemoStore store) {
    return [
      _CatalogPanel(
        title: store.t('shop.section.cats'),
        icon: Icons.pets_rounded,
        accentColor: CatudyColors.coral,
        children: [
          for (final pet in store.unlockablePets)
            _CatUnlockCard(store: store, pet: pet),
        ],
      ),
    ];
  }

  List<Widget> _profileChildren(
    CatudyDemoStore store, {
    required List<ShopItem> profileItems,
    required List<CosmeticItem> profileStyles,
  }) {
    final children = <Widget>[
      for (final item in profileItems) _ShopItemCard(store: store, item: item),
      for (final item in profileStyles)
        _PremiumCosmeticCard(store: store, item: item),
    ];
    if (children.isEmpty) {
      return [_CatalogEmptyPanel(message: store.t('inventory.emptyCategory'))];
    }
    return [
      _CatalogPanel(
        title: store.t('shop.category.profile'),
        icon: Icons.badge_rounded,
        accentColor: CatudyColors.teal,
        children: children,
      ),
    ];
  }

  List<CosmeticItem> _cosmeticsFor(CatudyDemoStore store, Set<String> slots) {
    return store.directPurchaseCosmetics
        .where((item) => slots.contains(item.slot))
        .toList();
  }
}

class _CategoryTab<T> {
  const _CategoryTab({
    required this.value,
    required this.label,
    required this.icon,
    required this.count,
  });

  final T value;
  final String label;
  final IconData icon;
  final int count;
}

class _CategoryBar<T> extends StatelessWidget {
  const _CategoryBar({
    required this.tabs,
    required this.selected,
    required this.onChanged,
  });

  final List<_CategoryTab<T>> tabs;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      padding: const EdgeInsets.all(8),
      accentColor: CatudyColors.violet,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 8.0;
          final width = (constraints.maxWidth - spacing) / 2;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final tab in tabs)
                SizedBox(
                  width: width,
                  child: _CategoryButton<T>(
                    tab: tab,
                    selected: selected == tab.value,
                    onTap: () => onChanged(tab.value),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryButton<T> extends StatelessWidget {
  const _CategoryButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _CategoryTab<T> tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? CatudyColors.violet
        : CatudyColors.surfaceFor(context);
    final foreground = selected ? Colors.white : CatudyColors.blueFor(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? CatudyColors.violet
                : CatudyColors.violet.withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          children: [
            Icon(tab.icon, color: foreground, size: 19),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.18)
                    : CatudyColors.violet.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${tab.count}',
                style: TextStyle(
                  color: foreground,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
      padding: const EdgeInsets.all(12),
      accentColor: accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CatudySectionHeader(
            title: title,
            icon: icon,
            accentColor: accentColor,
          ),
          const SizedBox(height: 10),
          _ProductGrid(children: children),
        ],
      ),
    );
  }
}

class _CatalogEmptyPanel extends StatelessWidget {
  const _CatalogEmptyPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      color: CatudyColors.lavenderSoft,
      accentColor: CatudyColors.violet,
      child: Text(
        message,
        style: TextStyle(
          color: CatudyColors.mutedFor(context),
          fontWeight: FontWeight.w800,
        ),
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
      padding: const EdgeInsets.all(12),
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
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
      art: ShopItemArt(item: item, size: 58),
      title: store.itemName(item),
      chips: [
        _MetaChip(label: '${item.price} ${store.t('common.gold')}'),
        if (owned) _MetaChip(label: store.t('shop.owned')),
      ],
      action: FilledButton(
        onPressed: owned
            ? () =>
                  context.go(item.isRoomFurniture ? '/pet-room' : '/inventory')
            : () => store.buyItem(item.id),
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
      chips: [
        if (item.directPrice != null)
          _MetaChip(label: '${item.directPrice} ${store.t('common.gold')}'),
        if (item.premiumOnly) _MetaChip(label: store.t('shop.plusOnly')),
        if (owned) _MetaChip(label: store.t('shop.owned')),
      ],
      action: FilledButton(
        onPressed: owned
            ? () => context.push('/inventory')
            : locked
            ? null
            : () => store.buyCosmetic(item.id),
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

class _CatUnlockCard extends StatelessWidget {
  const _CatUnlockCard({required this.store, required this.pet});

  final CatudyDemoStore store;
  final UnlockablePet pet;

  @override
  Widget build(BuildContext context) {
    final unlocked = store.unlockedPetIds.contains(pet.id);
    final progress = (store.focusPoints / pet.requiredPoints)
        .clamp(0.0, 1.0)
        .toDouble();
    return _ProductCard(
      accent: pet.accent,
      art: CatudyPetAvatar(
        assetPath: pet.assetPath,
        width: 58,
        height: 58,
        fit: BoxFit.contain,
      ),
      title: unlocked
          ? store.t('shop.unlocked')
          : store.t('shop.catRequiredMinutes', {'minutes': pet.requiredPoints}),
      chips: [
        _MetaChip(
          label: unlocked
              ? store.t('shop.unlocked')
              : '${store.focusPoints}/${pet.requiredPoints}',
        ),
      ],
      progress: progress,
      action: FilledButton(
        onPressed: unlocked ? () => store.selectPet(pet.id) : null,
        child: Text(
          unlocked
              ? store.t('common.select')
              : store.t('shop.catRequiredMinutes', {
                  'minutes': pet.requiredPoints,
                }),
        ),
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
        const spacing = 7.0;
        final columns = constraints.maxWidth >= 285 ? 3 : 2;
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
    required this.chips,
    required this.action,
    required this.accent,
    this.progress,
  });

  final Widget art;
  final String title;
  final List<Widget> chips;
  final Widget action;
  final Color accent;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 184,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.24), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: FittedBox(fit: BoxFit.contain, child: art),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CatudyColors.blueFor(context),
                    fontSize: 11.5,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 3,
                  runSpacing: 3,
                  children: chips,
                ),
              ],
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
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
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            child: SizedBox(height: 28, child: action),
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
    return Icon(item.icon, color: item.accent, size: 34);
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceStrongFor(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: CatudyColors.mutedFor(context),
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
