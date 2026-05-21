import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/premium/catudy_premium_models.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/catudy_section_header.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

class CratesScreen extends StatelessWidget {
  const CratesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) => ScreenScaffold(
        title: store.t('crates.title'),
        showBack: true,
        fallbackBackPath: '/plus',
        children: [
          CatudyPanel(
            color: CatudyColors.cream,
            accentColor: CatudyColors.coral,
            child: Row(
              children: [
                const Icon(Icons.diamond_rounded, color: CatudyColors.coral),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    store.t('crates.wallet', {
                      'points': store.focusPoints,
                      'coin': store.gold,
                      'shards': store.shardWallet.shards,
                    }),
                    style: TextStyle(
                      color: CatudyColors.blueFor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CatudyPanel(
            accentColor: CatudyColors.teal,
            child: Row(
              children: [
                const Icon(Icons.balance_rounded, color: CatudyColors.teal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    store.t('crates.economyNote'),
                    style: TextStyle(
                      color: CatudyColors.mutedFor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final crate in store.lootCrates)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CrateTile(crate: crate, store: store),
            ),
          const SizedBox(height: 6),
          CatudySectionHeader(
            title: store.t('crates.collection'),
            icon: Icons.collections_bookmark_rounded,
            accentColor: CatudyColors.violet,
          ),
          const SizedBox(height: 10),
          for (final item in store.cosmeticItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CosmeticTile(item: item, store: store),
            ),
        ],
      ),
    );
  }
}

class _CrateTile extends StatelessWidget {
  const _CrateTile({required this.crate, required this.store});

  final LootCrate crate;
  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final count = store.crateInventory[crate.id] ?? 0;
    final locked = crate.premiumOnly && !store.hasPremiumAccess;
    final canBuy = !locked && store.focusPoints >= crate.price;
    return CatudyPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _crateColor(
                  crate.type,
                ).withValues(alpha: 0.14),
                child: Icon(
                  _crateIcon(crate.type),
                  color: _crateColor(crate.type),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crate.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      crate.description,
                      style: TextStyle(color: CatudyColors.mutedFor(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(store.t('crates.owned', {'count': count}))),
              if (crate.price > 0)
                Chip(
                  label: Text(store.t('crates.price', {'points': crate.price})),
                ),
              if (locked) Chip(label: Text(store.t('crates.plusOnly'))),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final buyButton = crate.price > 0
                  ? OutlinedButton.icon(
                      onPressed: canBuy ? () => store.buyCrate(crate.id) : null,
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      label: Text(store.t('crates.buy')),
                    )
                  : null;
              final openButton = FilledButton.icon(
                onPressed: count > 0 && !locked
                    ? () => _openCrate(context, store, crate.id)
                    : null,
                icon: const Icon(Icons.inventory_2_rounded),
                label: Text(store.t('crates.open')),
              );

              if (constraints.maxWidth < 360) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (buyButton != null) ...[
                      buyButton,
                      const SizedBox(height: 10),
                    ],
                    openButton,
                  ],
                );
              }

              return Row(
                children: [
                  if (buyButton != null) ...[
                    Expanded(child: buyButton),
                    const SizedBox(width: 10),
                  ],
                  Expanded(child: openButton),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openCrate(
    BuildContext context,
    CatudyDemoStore store,
    String crateId,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CrateOpeningDialog(store: store, crateId: crateId),
    );
  }
}

class _CosmeticTile extends StatelessWidget {
  const _CosmeticTile({required this.item, required this.store});

  final CosmeticItem item;
  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final owned = store.ownedCosmeticIds.contains(item.id);
    final shardCost = item.rarity.shardValue * 4;
    return CatudyPanel(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: item.accent.withValues(alpha: 0.14),
            child: Icon(item.icon, color: item.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  '${item.rarity.code} · ${item.description}',
                  style: TextStyle(color: CatudyColors.mutedFor(context)),
                ),
              ],
            ),
          ),
          if (owned)
            FilledButton(
              onPressed: () => store.equipCosmetic(item.id),
              child: Text(store.t('inventory.equipped')),
            )
          else if (item.directPrice != null)
            FilledButton.tonal(
              onPressed: item.premiumOnly && !store.hasPremiumAccess
                  ? null
                  : () => store.buyCosmetic(item.id),
              child: Text('${item.directPrice} ${store.t('common.gold')}'),
            )
          else
            OutlinedButton(
              onPressed:
                  (!item.premiumOnly || store.hasPremiumAccess) &&
                      store.shardWallet.shards >= shardCost
                  ? () => store.craftCosmetic(item.id)
                  : null,
              child: Text('$shardCost'),
            ),
        ],
      ),
    );
  }
}

class _CrateOpeningDialog extends StatefulWidget {
  const _CrateOpeningDialog({required this.store, required this.crateId});

  final CatudyDemoStore store;
  final String crateId;

  @override
  State<_CrateOpeningDialog> createState() => _CrateOpeningDialogState();
}

class _CrateOpeningDialogState extends State<_CrateOpeningDialog> {
  CosmeticItem? _result;
  Timer? _timer;
  var _pulse = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 140), (_) {
      if (!mounted || _result != null) {
        return;
      }
      setState(() => _pulse++);
    });
    Future<void>.delayed(const Duration(milliseconds: 1300), () {
      if (!mounted) {
        return;
      }
      setState(() => _result = widget.store.openCrate(widget.crateId));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final crate = widget.store.crateById(widget.crateId);
    final pool = crate == null ? null : widget.store.lootPoolById(crate.poolId);
    final candidates =
        pool?.itemIds
            .map(widget.store.cosmeticById)
            .whereType<CosmeticItem>()
            .toList() ??
        const <CosmeticItem>[];
    return AlertDialog(
      title: Text(widget.store.t('crates.opening')),
      content: SizedBox(
        width: 260,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LootReel(candidates: candidates, pulse: _pulse, result: result),
            const SizedBox(height: 14),
            Text(
              result == null ? widget.store.t('crates.rolling') : result.name,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            if (result != null) ...[
              const SizedBox(height: 6),
              Text(
                result.rarity.code,
                style: TextStyle(
                  color: result.accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(result.description, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: result == null ? null : () => Navigator.of(context).pop(),
          child: Text(widget.store.t('common.done')),
        ),
      ],
    );
  }
}

class _LootReel extends StatelessWidget {
  const _LootReel({
    required this.candidates,
    required this.pulse,
    required this.result,
  });

  final List<CosmeticItem> candidates;
  final int pulse;
  final CosmeticItem? result;

  @override
  Widget build(BuildContext context) {
    final fallback = result;
    return Container(
      height: 78,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: CatudyColors.violet.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < 5; index++)
            Expanded(
              child: _LootReelCell(
                item: _itemForSlot(
                  index: index,
                  candidates: candidates,
                  pulse: pulse,
                  result: fallback,
                ),
                highlighted: index == 2,
              ),
            ),
        ],
      ),
    );
  }

  CosmeticItem? _itemForSlot({
    required int index,
    required List<CosmeticItem> candidates,
    required int pulse,
    required CosmeticItem? result,
  }) {
    if (result != null && index == 2) {
      return result;
    }
    if (candidates.isEmpty) {
      return result;
    }
    return candidates[(pulse + index) % candidates.length];
  }
}

class _LootReelCell extends StatelessWidget {
  const _LootReelCell({required this.item, required this.highlighted});

  final CosmeticItem? item;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final effective = item;
    final accent = effective?.accent ?? CatudyColors.violet;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: highlighted ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: highlighted
            ? Border.all(color: accent.withValues(alpha: 0.45), width: 1.4)
            : null,
      ),
      child: Icon(
        effective?.icon ?? Icons.inventory_2_rounded,
        color: accent,
        size: highlighted ? 30 : 24,
      ),
    );
  }
}

Color _crateColor(LootCrateType type) => switch (type) {
  LootCrateType.cat => CatudyColors.coral,
  LootCrateType.room => CatudyColors.teal,
  LootCrateType.style => CatudyColors.violet,
};

IconData _crateIcon(LootCrateType type) => switch (type) {
  LootCrateType.cat => Icons.pets_rounded,
  LootCrateType.room => Icons.weekend_rounded,
  LootCrateType.style => Icons.style_rounded,
};
