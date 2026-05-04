import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/shop_item_art.dart';
import '../../shared/widgets/store_builder.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        final roomItems = store.roomFurnitureItems.toList();
        final cosmeticItems = store.shopItems
            .where((item) => !item.isRoomFurniture)
            .toList();

        return ScreenScaffold(
          title: store.t('shop.title'),
          showBack: true,
          fallbackBackPath: '/pet-room',
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Chip(
                label: Text('${store.focusPoints} ${store.t('common.points')}'),
              ),
            ),
          ],
          children: [
            CatudyPanel(
              accentColor: CatudyColors.coral,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.t('shop.petUnlocks'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: CatudyColors.muted,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final pet in store.unlockablePets)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PetUnlockTile(
                        name: pet.name,
                        description: pet.description,
                        accent: pet.accent,
                        requiredPoints: pet.requiredPoints,
                        currentPoints: store.focusPoints,
                        unlocked: store.unlockedPetIds.contains(pet.id),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (roomItems.isNotEmpty) ...[
              Text(
                store.t('shop.roomFurniture'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: CatudyColors.muted,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              for (final item in roomItems)
                _ShopItemTile(store: store, item: item),
              const SizedBox(height: 2),
            ],
            Text(
              store.t('shop.cosmetics'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: CatudyColors.muted,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            for (final item in cosmeticItems)
              _ShopItemTile(store: store, item: item),
            OutlinedButton.icon(
              onPressed: () => context.go('/inventory'),
              icon: const Icon(Icons.inventory_2_rounded),
              label: Text(store.t('shop.openInventory')),
            ),
          ],
        );
      },
    );
  }
}

class _ShopItemTile extends StatelessWidget {
  const _ShopItemTile({required this.store, required this.item});

  final CatudyDemoStore store;
  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final owned = store.ownedItems.contains(item.id);
    final detail = item.isRoomFurniture
        ? '+${store.rewardBoostPercentFor(item).toStringAsFixed(1)}% '
              '${store.t('shop.rewardBoost')} - ${item.price} '
              '${store.t('common.gold')}'
        : '${item.rarity} - ${item.slot} - ${item.price} '
              '${store.t('common.gold')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CatudyPanel(
        child: Row(
          children: [
            ShopItemArt(item: item),
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
                    detail,
                    style: const TextStyle(color: CatudyColors.muted),
                  ),
                  Text(store.itemDescription(item)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: owned ? null : () => store.buyItem(item.id),
              child: Text(owned ? store.t('shop.owned') : store.t('shop.buy')),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetUnlockTile extends StatelessWidget {
  const _PetUnlockTile({
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: accent.withValues(alpha: 0.18),
            child: Icon(Icons.pets_rounded, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(
                  description,
                  style: const TextStyle(color: CatudyColors.muted),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    color: accent,
                    backgroundColor: CatudyColors.lavenderSoft,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            unlocked
                ? catudyDemoStore.t('shop.unlocked')
                : '$currentPoints/$requiredPoints',
            style: const TextStyle(
              color: CatudyColors.blue,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
