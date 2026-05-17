import 'package:flutter/material.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/premium/catudy_premium_models.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/shop_item_art.dart';
import '../../shared/widgets/store_builder.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) => ScreenScaffold(
        title: store.t('inventory.title'),
        showBack: true,
        fallbackBackPath: '/pet-room',
        children: [
          CatudyPanel(
            accentColor: CatudyColors.coral,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.t('inventory.pets'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: CatudyColors.muted,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                for (final pet in store.unlockablePets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: pet.accent.withValues(alpha: 0.16),
                          child: Icon(Icons.pets_rounded, color: pet.accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            store.unlockedPetIds.contains(pet.id)
                                ? pet.name
                                : '${pet.name} (${pet.requiredPoints} ${store.t('common.points')})',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        FilledButton(
                          onPressed: store.unlockedPetIds.contains(pet.id)
                              ? () => store.selectPet(pet.id)
                              : null,
                          child: Text(
                            store.selectedPetId == pet.id
                                ? store.t('common.selected')
                                : store.t('common.select'),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final item in store.shopItems.where(
            (i) => store.ownedItems.contains(i.id),
          ))
            _InventoryItemTile(store: store, item: item),
          if (store.ownedCosmeticIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              store.t('inventory.premiumCosmetics'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: CatudyColors.mutedFor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            for (final item in store.cosmeticItems.where(
              (item) => store.ownedCosmeticIds.contains(item.id),
            ))
              _PremiumInventoryTile(store: store, item: item),
          ],
        ],
      ),
    );
  }
}

class _PremiumInventoryTile extends StatelessWidget {
  const _PremiumInventoryTile({required this.store, required this.item});

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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CatudyPanel(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: item.accent.withValues(alpha: 0.14),
              child: Icon(item.icon, color: item.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    store.t('inventory.cosmeticSlot.${item.slot}'),
                    style: TextStyle(color: CatudyColors.mutedFor(context)),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: isEquipped ? null : () => store.equipCosmetic(item.id),
              child: Text(
                isEquipped
                    ? store.t('common.selected')
                    : store.t('inventory.equipped'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryItemTile extends StatelessWidget {
  const _InventoryItemTile({required this.store, required this.item});

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CatudyPanel(
        child: Row(
          children: [
            ShopItemArt(item: item, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.itemName(item),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    status,
                    style: const TextStyle(color: CatudyColors.muted),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: isEquipped ? null : () => store.equipItem(item.id),
              child: Text(
                isEquipped
                    ? store.t('common.selected')
                    : store.t('inventory.equipped'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
