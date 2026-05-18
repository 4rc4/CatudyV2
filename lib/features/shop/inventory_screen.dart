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

enum _InventoryCategory { room, pet, profile, extras }

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  _InventoryCategory _category = _InventoryCategory.room;

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
        final petItems = ownedItems
            .where((item) => item.slot == 'pet')
            .toList();
        final profileItems = ownedItems
            .where((item) => item.slot == 'profile')
            .toList();
        final petStyles = _ownedCosmeticsFor(store, {'pet_style'});
        final roomEffects = _ownedCosmeticsFor(store, {'room_effect'});
        final profileThemes = _ownedCosmeticsFor(store, {'profile_theme'});
        final profileBadges = _ownedCosmeticsFor(store, {'profile_badge'});
        final widgetThemes = _ownedCosmeticsFor(store, {'widget_theme'});
        final dialoguePacks = _ownedCosmeticsFor(store, {'dialogue_pack'});
        final categoryChildren = switch (_category) {
          _InventoryCategory.room => _roomChildren(
            store,
            roomItems: roomItems,
            roomEffects: roomEffects,
          ),
          _InventoryCategory.pet => _petChildren(
            store,
            petItems: petItems,
            petStyles: petStyles,
          ),
          _InventoryCategory.profile => _profileChildren(
            store,
            profileItems: profileItems,
            profileThemes: profileThemes,
            profileBadges: profileBadges,
          ),
          _InventoryCategory.extras => _extraChildren(
            store,
            widgetThemes: widgetThemes,
            dialoguePacks: dialoguePacks,
          ),
        };

        return ScreenScaffold(
          title: store.t('inventory.title'),
          showBack: true,
          fallbackBackPath: '/pet-room',
          children: [
            _InventorySummary(
              store: store,
              ownedItems: ownedItems.length,
              equippedRoomCount: store.equippedRoomItems.length,
            ),
            const SizedBox(height: 14),
            CatudyFilterTabs<_InventoryCategory>(
              selected: _category,
              onChanged: (category) => setState(() => _category = category),
              tabs: [
                CatudyFilterTab(
                  value: _InventoryCategory.room,
                  label: store.t('inventory.category.room'),
                  icon: Icons.weekend_rounded,
                  count: roomItems.length + roomEffects.length,
                ),
                CatudyFilterTab(
                  value: _InventoryCategory.pet,
                  label: store.t('inventory.category.pet'),
                  icon: Icons.pets_rounded,
                  count:
                      store.unlockedPetIds.length +
                      petItems.length +
                      petStyles.length,
                ),
                CatudyFilterTab(
                  value: _InventoryCategory.profile,
                  label: store.t('inventory.category.profile'),
                  icon: Icons.badge_rounded,
                  count:
                      profileItems.length +
                      profileThemes.length +
                      profileBadges.length,
                ),
                CatudyFilterTab(
                  value: _InventoryCategory.extras,
                  label: store.t('inventory.category.extras'),
                  icon: Icons.auto_awesome_rounded,
                  count: widgetThemes.length + dialoguePacks.length,
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
        _InventoryPanel(
          title: _roomSlotTitle(store, slot),
          icon: _roomSlotIcon(slot),
          accentColor: _roomSlotColor(slot),
          children: [
            for (final item in items)
              _InventoryItemCard(store: store, item: item),
          ],
        ),
      );
      children.add(const SizedBox(height: 12));
    }
    if (roomEffects.isNotEmpty) {
      children.add(
        _InventoryPanel(
          title: store.t('inventory.roomEffects'),
          icon: Icons.auto_awesome_motion_rounded,
          accentColor: CatudyColors.violet,
          children: [
            for (final item in roomEffects)
              _PremiumInventoryCard(store: store, item: item),
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
      _InventoryPanel(
        title: store.t('inventory.pets'),
        icon: Icons.pets_rounded,
        accentColor: CatudyColors.coral,
        children: [
          for (final pet in store.unlockablePets)
            _PetSelectionCard(store: store, pet: pet),
        ],
      ),
      if (petItems.isNotEmpty) ...[
        const SizedBox(height: 12),
        _InventoryPanel(
          title: store.t('inventory.petCosmetic'),
          icon: Icons.checkroom_rounded,
          accentColor: CatudyColors.teal,
          children: [
            for (final item in petItems)
              _InventoryItemCard(store: store, item: item),
          ],
        ),
      ],
      if (petStyles.isNotEmpty) ...[
        const SizedBox(height: 12),
        _InventoryPanel(
          title: store.t('inventory.petStyles'),
          icon: Icons.auto_awesome_rounded,
          accentColor: CatudyColors.violet,
          children: [
            for (final item in petStyles)
              _PremiumInventoryCard(store: store, item: item),
          ],
        ),
      ],
    ];
  }

  List<Widget> _profileChildren(
    CatudyDemoStore store, {
    required List<ShopItem> profileItems,
    required List<CosmeticItem> profileThemes,
    required List<CosmeticItem> profileBadges,
  }) {
    return [
      if (profileItems.isNotEmpty)
        _InventoryPanel(
          title: store.t('inventory.profileCosmetic'),
          icon: Icons.military_tech_rounded,
          accentColor: CatudyColors.teal,
          children: [
            for (final item in profileItems)
              _InventoryItemCard(store: store, item: item),
          ],
        ),
      if (profileThemes.isNotEmpty) ...[
        if (profileItems.isNotEmpty) const SizedBox(height: 12),
        _InventoryPanel(
          title: store.t('inventory.profileStyles'),
          icon: Icons.crop_square_rounded,
          accentColor: CatudyColors.violet,
          children: [
            for (final item in profileThemes)
              _PremiumInventoryCard(store: store, item: item),
          ],
        ),
      ],
      if (profileBadges.isNotEmpty) ...[
        if (profileItems.isNotEmpty || profileThemes.isNotEmpty)
          const SizedBox(height: 12),
        _InventoryPanel(
          title: store.t('inventory.profileBadges'),
          icon: Icons.workspace_premium_rounded,
          accentColor: CatudyColors.coral,
          children: [
            for (final item in profileBadges)
              _PremiumInventoryCard(store: store, item: item),
          ],
        ),
      ],
    ];
  }

  List<Widget> _extraChildren(
    CatudyDemoStore store, {
    required List<CosmeticItem> widgetThemes,
    required List<CosmeticItem> dialoguePacks,
  }) {
    return [
      if (widgetThemes.isNotEmpty)
        _InventoryPanel(
          title: store.t('inventory.widgetThemes'),
          icon: Icons.widgets_rounded,
          accentColor: CatudyColors.teal,
          children: [
            for (final item in widgetThemes)
              _PremiumInventoryCard(store: store, item: item),
          ],
        ),
      if (dialoguePacks.isNotEmpty) ...[
        if (widgetThemes.isNotEmpty) const SizedBox(height: 12),
        _InventoryPanel(
          title: store.t('inventory.dialoguePacks'),
          icon: Icons.chat_bubble_rounded,
          accentColor: CatudyColors.coral,
          children: [
            for (final item in dialoguePacks)
              _PremiumInventoryCard(store: store, item: item),
          ],
        ),
      ],
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

  String _roomSlotTitle(CatudyDemoStore store, String slot) {
    return switch (slot) {
      'room_study' => store.t('shop.room.slot.study'),
      'room_bed' => store.t('shop.room.slot.bed'),
      'room_decor' => store.t('shop.room.slot.decor'),
      'room_shelf' => store.t('shop.room.slot.shelf'),
      _ => store.t('inventory.roomFurniture'),
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

class _InventorySummary extends StatelessWidget {
  const _InventorySummary({
    required this.store,
    required this.ownedItems,
    required this.equippedRoomCount,
  });

  final CatudyDemoStore store;
  final int ownedItems;
  final int equippedRoomCount;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      color: CatudyColors.cream,
      accentColor: CatudyColors.teal,
      child: Row(
        children: [
          Expanded(
            child: _InventoryMetric(
              icon: Icons.pets_rounded,
              value: store.selectedPet.name,
              label: store.t('profile.myPet'),
              color: store.selectedPet.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _InventoryMetric(
              icon: Icons.inventory_2_rounded,
              value: '$ownedItems',
              label: store.t('inventory.ownedItems'),
              color: CatudyColors.violet,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _InventoryMetric(
              icon: Icons.weekend_rounded,
              value: '$equippedRoomCount',
              label: store.t('inventory.roomEquipped'),
              color: CatudyColors.teal,
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryMetric extends StatelessWidget {
  const _InventoryMetric({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
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

class _PetSelectionCard extends StatelessWidget {
  const _PetSelectionCard({required this.store, required this.pet});

  final CatudyDemoStore store;
  final UnlockablePet pet;

  @override
  Widget build(BuildContext context) {
    final unlocked = store.unlockedPetIds.contains(pet.id);
    return _InventoryCard(
      accent: pet.accent,
      art: Icon(Icons.pets_rounded, color: pet.accent, size: 54),
      title: pet.name,
      body: unlocked
          ? pet.description
          : '${pet.requiredPoints} ${store.t('common.points')}',
      action: FilledButton(
        onPressed: unlocked ? () => store.selectPet(pet.id) : null,
        child: Text(
          store.selectedPetId == pet.id
              ? store.t('common.selected')
              : store.t('common.select'),
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
        : item.slot == 'pet'
        ? store.equippedPetItemId == item.id
        : store.equippedProfileItemId == item.id;
    final status = item.isRoomFurniture
        ? isEquipped
              ? store.t('inventory.roomEquipped')
              : store.t('inventory.roomFurniture')
        : item.slot == 'pet'
        ? isEquipped
              ? store.t('inventory.petEquipped')
              : store.t('inventory.petCosmetic')
        : isEquipped
        ? store.t('inventory.profileEquipped')
        : store.t('inventory.profileCosmetic');

    return _InventoryCard(
      accent: item.accent,
      art: ShopItemArt(item: item, size: 92),
      title: store.itemName(item),
      body: status,
      action: FilledButton(
        onPressed: isEquipped
            ? () => context.go('/pet-room')
            : () => store.equipItem(item.id),
        child: Text(
          isEquipped
              ? store.t('profile.petRoom')
              : store.t('inventory.equipped'),
        ),
      ),
    );
  }
}

class _PremiumInventoryCard extends StatelessWidget {
  const _PremiumInventoryCard({required this.store, required this.item});

  final CatudyDemoStore store;
  final CosmeticItem item;

  @override
  Widget build(BuildContext context) {
    final isEquipped = switch (item.slot) {
      'pet_style' => store.selectedPetStyleId == item.id,
      'room_effect' => store.selectedRoomEffectId == item.id,
      'profile_theme' => store.selectedProfileThemeId == item.id,
      'widget_theme' => store.selectedWidgetThemeId == item.id,
      'dialogue_pack' => store.selectedDialoguePackId == item.id,
      _ => false,
    };
    return _InventoryCard(
      accent: item.accent,
      art: _InventoryCosmeticArt(item: item),
      title: item.name,
      body: store.t('inventory.cosmeticSlot.${item.slot}'),
      action: FilledButton(
        onPressed: isEquipped
            ? () => context.go('/pet-room')
            : () => store.equipCosmetic(item.id),
        child: Text(
          isEquipped
              ? store.t('profile.petRoom')
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

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.art,
    required this.title,
    required this.body,
    required this.action,
    required this.accent,
  });

  final Widget art;
  final String title;
  final String body;
  final Widget action;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
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
          const SizedBox(height: 8),
          SizedBox(height: 38, child: action),
        ],
      ),
    );
  }
}

class _InventoryCosmeticArt extends StatelessWidget {
  const _InventoryCosmeticArt({required this.item});

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
