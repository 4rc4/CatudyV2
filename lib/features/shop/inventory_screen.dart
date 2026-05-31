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

enum _InventoryCategory { room, accessories, cats, profile }

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  _InventoryCategory _category = _InventoryCategory.accessories;

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        final ownedItems = store.shopItems
            .where((item) => store.ownedItems.contains(item.id))
            .toList();
        final roomItems = ownedItems
            .where((item) => item.isRoomFurniture)
            .toList();
        final accessoryItems = ownedItems
            .where((item) => item.isPetAccessory)
            .toList();
        final profileItems = ownedItems
            .where((item) => item.slot == 'profile')
            .toList();
        final profileThemes = _ownedCosmeticsFor(store, {'profile_theme'});
        final profileBadges = _ownedCosmeticsFor(store, {'profile_badge'});
        final categoryChildren = switch (_category) {
          _InventoryCategory.room => _roomChildren(store, roomItems: roomItems),
          _InventoryCategory.accessories => _accessoryChildren(
            store,
            accessoryItems: accessoryItems,
          ),
          _InventoryCategory.cats => _catChildren(store),
          _InventoryCategory.profile => _profileChildren(
            store,
            profileItems: profileItems,
            profileThemes: profileThemes,
            profileBadges: profileBadges,
          ),
        };

        return ScreenScaffold(
          title: store.t('inventory.title'),
          showBack: true,
          fallbackBackPath: '/pet-room',
          children: [
            _CategoryBar<_InventoryCategory>(
              selected: _category,
              onChanged: (category) => setState(() => _category = category),
              tabs: [
                _CategoryTab(
                  value: _InventoryCategory.room,
                  label: store.t('inventory.category.room'),
                  icon: Icons.weekend_rounded,
                  count: roomItems.length,
                ),
                _CategoryTab(
                  value: _InventoryCategory.accessories,
                  label: store.t('inventory.category.accessories'),
                  icon: Icons.checkroom_rounded,
                  count: accessoryItems.length,
                ),
                _CategoryTab(
                  value: _InventoryCategory.cats,
                  label: store.t('inventory.category.cats'),
                  icon: Icons.pets_rounded,
                  count: store.unlockedPetIds.length,
                ),
                _CategoryTab(
                  value: _InventoryCategory.profile,
                  label: store.t('inventory.category.profile'),
                  icon: Icons.badge_rounded,
                  count:
                      profileItems.length +
                      profileThemes.length +
                      profileBadges.length,
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
                children: categoryChildren.isEmpty
                    ? [_InventoryEmptyPanel(store: store)]
                    : categoryChildren,
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
      return const [];
    }
    return [
      _InventoryPanel(
        title: store.t('inventory.roomFurniture'),
        icon: Icons.weekend_rounded,
        accentColor: CatudyColors.teal,
        children: [
          for (final item in roomItems)
            _InventoryItemCard(store: store, item: item),
        ],
      ),
    ];
  }

  List<Widget> _accessoryChildren(
    CatudyDemoStore store, {
    required List<ShopItem> accessoryItems,
  }) {
    if (accessoryItems.isEmpty) {
      return const [];
    }
    return [
      _InventoryPanel(
        title: store.t('inventory.accessories'),
        icon: Icons.checkroom_rounded,
        accentColor: CatudyColors.violet,
        children: [
          for (final item in accessoryItems)
            _InventoryItemCard(store: store, item: item),
        ],
      ),
    ];
  }

  List<Widget> _catChildren(CatudyDemoStore store) {
    return [
      _InventoryPanel(
        title: store.t('inventory.category.cats'),
        icon: Icons.pets_rounded,
        accentColor: CatudyColors.coral,
        children: [
          for (final pet in store.unlockablePets)
            _CatSelectionCard(store: store, pet: pet),
        ],
      ),
    ];
  }

  List<Widget> _profileChildren(
    CatudyDemoStore store, {
    required List<ShopItem> profileItems,
    required List<CosmeticItem> profileThemes,
    required List<CosmeticItem> profileBadges,
  }) {
    final children = <Widget>[
      for (final item in profileItems)
        _InventoryItemCard(store: store, item: item),
      for (final item in profileThemes)
        _PremiumInventoryCard(store: store, item: item),
      for (final item in profileBadges)
        _PremiumInventoryCard(store: store, item: item),
    ];
    if (children.isEmpty) {
      return const [];
    }
    return [
      _InventoryPanel(
        title: store.t('inventory.category.profile'),
        icon: Icons.badge_rounded,
        accentColor: CatudyColors.teal,
        children: children,
      ),
    ];
  }

  List<CosmeticItem> _ownedCosmeticsFor(
    CatudyDemoStore store,
    Set<String> slots,
  ) {
    return store.cosmeticItems
        .where(
          (item) =>
              slots.contains(item.slot) &&
              store.ownedCosmeticIds.contains(item.id),
        )
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

class _InventoryPanel extends StatelessWidget {
  const _InventoryPanel({
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
          _InventoryGrid(children: children),
        ],
      ),
    );
  }
}

class _InventoryEmptyPanel extends StatelessWidget {
  const _InventoryEmptyPanel({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      color: CatudyColors.lavenderSoft,
      accentColor: CatudyColors.violet,
      child: Row(
        children: [
          const Icon(Icons.inbox_rounded, color: CatudyColors.violet),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              store.t('inventory.emptyCategory'),
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

class _CatSelectionCard extends StatelessWidget {
  const _CatSelectionCard({required this.store, required this.pet});

  final CatudyDemoStore store;
  final UnlockablePet pet;

  @override
  Widget build(BuildContext context) {
    final unlocked = store.unlockedPetIds.contains(pet.id);
    final selected = store.selectedPetId == pet.id;
    return _InventoryCard(
      accent: pet.accent,
      art: CatudyPetAvatar(
        assetPath: pet.assetPath,
        width: 94,
        height: 94,
        fit: BoxFit.contain,
      ),
      title: store.t('shop.catRequiredMinutes', {
        'minutes': pet.requiredPoints,
      }),
      chips: [
        _MetaChip(
          label: unlocked
              ? store.t('shop.unlocked')
              : '${store.focusPoints}/${pet.requiredPoints}',
        ),
      ],
      action: FilledButton(
        onPressed: unlocked ? () => store.selectPet(pet.id) : null,
        child: Text(
          selected
              ? store.t('common.selected')
              : unlocked
              ? store.t('common.select')
              : store.t('shop.catRequiredMinutes', {
                  'minutes': pet.requiredPoints,
                }),
        ),
      ),
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  const _InventoryItemCard({required this.store, required this.item});

  final CatudyDemoStore store;
  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final isEquipped = item.isRoomFurniture
        ? store.equippedRoomItemIds[item.slot] == item.id
        : item.isPetAccessory
        ? store.isPetAccessoryEquipped(item)
        : store.equippedProfileItemId == item.id;

    return _InventoryCard(
      accent: item.accent,
      art: ShopItemArt(item: item, size: 96, showBackground: false),
      title: store.itemName(item),
      chips: [
        if (item.isPetAccessory)
          for (final slot in item.occupiedSlots)
            _MetaChip(label: _slotLabel(store, slot)),
        if (isEquipped) _MetaChip(label: store.t('common.selected')),
      ],
      extra: item.isPetAccessory && item.hasVariants
          ? _VariantSelector(
              item: item,
              selectedId: store.equippedVariantIdFor(item),
              onSelected: store.equipItem,
            )
          : null,
      action: FilledButton(
        onPressed: isEquipped
            ? () => context.go('/pet-room')
            : () => store.equipItem(item.id),
        child: Text(
          isEquipped
              ? store.t('common.selected')
              : store.t('inventory.equipped'),
        ),
      ),
    );
  }

  String _slotLabel(CatudyDemoStore store, String slot) {
    return switch (slot) {
      'head' => store.t('inventory.slot.head'),
      'eyes' => store.t('inventory.slot.eyes'),
      'nose' => store.t('inventory.slot.nose'),
      'mouth' => store.t('inventory.slot.mouth'),
      _ => slot,
    };
  }
}

class _PremiumInventoryCard extends StatelessWidget {
  const _PremiumInventoryCard({required this.store, required this.item});

  final CatudyDemoStore store;
  final CosmeticItem item;

  @override
  Widget build(BuildContext context) {
    final isEquipped = switch (item.slot) {
      'profile_theme' => store.selectedProfileThemeId == item.id,
      _ => false,
    };
    return _InventoryCard(
      accent: item.accent,
      art: Icon(item.icon, color: item.accent, size: 56),
      title: item.name,
      chips: [if (isEquipped) _MetaChip(label: store.t('common.selected'))],
      action: FilledButton(
        onPressed: isEquipped
            ? () => context.go('/profile')
            : () => store.equipCosmetic(item.id),
        child: Text(
          isEquipped
              ? store.t('common.selected')
              : store.t('inventory.equipped'),
        ),
      ),
    );
  }
}

class _InventoryGrid extends StatelessWidget {
  const _InventoryGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 7.0;
        const columns = 2;
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

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.art,
    required this.title,
    required this.chips,
    required this.action,
    required this.accent,
    this.extra,
  });

  final Widget art;
  final String title;
  final List<Widget> chips;
  final Widget action;
  final Color accent;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: extra == null ? 216 : 244,
      padding: const EdgeInsets.all(8),
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
                  width: 106,
                  height: 106,
                  padding: const EdgeInsets.all(4),
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
                    fontSize: 10.8,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 3,
                  runSpacing: 3,
                  children: chips,
                ),
                if (extra != null) ...[const SizedBox(height: 6), extra!],
              ],
            ),
          ),
          const SizedBox(height: 5),
          Theme(
            data: Theme.of(context).copyWith(
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 26),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 10.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            child: SizedBox(height: 32, child: action),
          ),
        ],
      ),
    );
  }
}

class _VariantSelector extends StatelessWidget {
  const _VariantSelector({
    required this.item,
    required this.selectedId,
    required this.onSelected,
  });

  final ShopItem item;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final variant in item.variants)
          Tooltip(
            message: variant.label,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onSelected(variant.id),
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: variant.accent.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selectedId == variant.id
                        ? variant.accent
                        : variant.accent.withValues(alpha: 0.35),
                    width: selectedId == variant.id ? 2 : 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
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
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
