import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/catudy_section_header.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final _buddyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(catudyDemoStore.refreshPremiumNow());
    });
  }

  @override
  void dispose() {
    _buddyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) => ScreenScaffold(
        title: store.t('premium.title'),
        showBack: true,
        fallbackBackPath: '/',
        children: [
          CatudyPanel(
            color: CatudyColors.cream,
            accentColor: CatudyColors.violet,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CatudySectionHeader(
                  title: store.hasPremiumAccess
                      ? store.t('premium.active')
                      : store.t('premium.pitch'),
                  icon: Icons.workspace_premium_rounded,
                  accentColor: CatudyColors.violet,
                ),
                const SizedBox(height: 10),
                Text(
                  store.t('premium.body'),
                  style: TextStyle(
                    color: CatudyColors.mutedFor(context),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FeatureChip(label: store.t('premium.featureCoach')),
                    _FeatureChip(label: store.t('premium.featureStats')),
                    _FeatureChip(label: store.t('premium.featureSeason')),
                    _FeatureChip(label: store.t('premium.featureCosmetics')),
                  ],
                ),
                const SizedBox(height: 14),
                if (!store.hasPremiumAccess)
                  FilledButton.icon(
                    onPressed: store.activatePremiumDemo,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: Text(store.t('premium.activateDemo')),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: store.clearPremiumEntitlement,
                    icon: const Icon(Icons.lock_open_rounded),
                    label: Text(store.t('premium.clearDemo')),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _QuickLinks(store: store),
          const SizedBox(height: 14),
          _PremiumSyncPanel(store: store),
          if (store.premiumError != null) ...[
            const SizedBox(height: 10),
            Text(
              store.premiumError!,
              style: const TextStyle(
                color: CatudyColors.coral,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _BuddyPassPanel(store: store, controller: _buddyController),
          const SizedBox(height: 14),
          _WidgetThemePanel(store: store),
        ],
      ),
    );
  }
}

class _PremiumSyncPanel extends StatelessWidget {
  const _PremiumSyncPanel({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final accountLabel =
        store.authEmail ?? store.authUserId ?? store.t('premium.notSignedIn');
    final statusLabel = store.hasPremiumAccess
        ? store.t('premium.statusActive')
        : store.t('premium.statusInactive');
    return CatudyPanel(
      accentColor: CatudyColors.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CatudySectionHeader(
            title: store.t('premium.backendTitle'),
            icon: Icons.cloud_sync_rounded,
            accentColor: CatudyColors.blue,
          ),
          const SizedBox(height: 8),
          Text(
            store.canSyncPremiumOnline
                ? store.t('premium.backendOnline')
                : store.t('premium.backendOffline'),
            style: TextStyle(
              color: CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${store.t('premium.account')}: $accountLabel',
            style: TextStyle(color: CatudyColors.mutedFor(context)),
          ),
          const SizedBox(height: 4),
          Text(
            '${store.t('premium.status')}: $statusLabel',
            style: TextStyle(color: CatudyColors.mutedFor(context)),
          ),
          if (store.authUserId != null) ...[
            const SizedBox(height: 4),
            SelectableText(
              store.authUserId!,
              style: TextStyle(
                color: CatudyColors.blueFor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: store.canSyncPremiumOnline && !store.premiumBusy
                ? store.refreshPremiumNow
                : null,
            icon: const Icon(Icons.sync_rounded),
            label: Text(store.t('premium.refresh')),
          ),
        ],
      ),
    );
  }
}

class _QuickLinks extends StatelessWidget {
  const _QuickLinks({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final buttons = [
      FilledButton.tonalIcon(
        onPressed: () => context.go('/season'),
        icon: const Icon(Icons.emoji_events_rounded),
        label: Text(store.t('premium.openSeason')),
      ),
      FilledButton.tonalIcon(
        onPressed: () => context.go('/crates'),
        icon: const Icon(Icons.inventory_2_rounded),
        label: Text(store.t('premium.openCrates')),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [buttons[0], const SizedBox(height: 10), buttons[1]],
          );
        }

        return Row(
          children: [
            Expanded(child: buttons[0]),
            const SizedBox(width: 10),
            Expanded(child: buttons[1]),
          ],
        );
      },
    );
  }
}

class _BuddyPassPanel extends StatelessWidget {
  const _BuddyPassPanel({required this.store, required this.controller});

  final CatudyDemoStore store;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final latestPass = store.issuedBuddyPasses.isEmpty
        ? null
        : store.issuedBuddyPasses.last;
    return CatudyPanel(
      accentColor: CatudyColors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CatudySectionHeader(
            title: store.t('buddy.title'),
            icon: Icons.card_giftcard_rounded,
            accentColor: CatudyColors.teal,
          ),
          const SizedBox(height: 8),
          Text(
            store.t('buddy.body'),
            style: TextStyle(
              color: CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            store.t('buddy.requirements'),
            style: TextStyle(
              color: CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (latestPass != null) ...[
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    latestPass.code,
                    style: TextStyle(
                      color: CatudyColors.blueFor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: store.t('buddy.copy'),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: latestPass.code),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(store.t('buddy.copied'))),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          FilledButton.icon(
            onPressed: store.canSendBuddyPass && !store.premiumBusy
                ? () async {
                    final pass = await store.createBuddyPass();
                    if (pass != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(store.t('buddy.created'))),
                      );
                    }
                  }
                : null,
            icon: const Icon(Icons.card_giftcard_rounded),
            label: Text(store.t('buddy.create')),
          ),
          const Divider(height: 24),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: store.t('buddy.redeemLabel'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: store.canRedeemBuddyPass && !store.premiumBusy
                ? () async {
                    final ok = await store.redeemBuddyPass(controller.text);
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? store.t('buddy.redeemed')
                              : store.t('buddy.invalid'),
                        ),
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.redeem_rounded),
            label: Text(store.t('buddy.redeem')),
          ),
        ],
      ),
    );
  }
}

class _WidgetThemePanel extends StatelessWidget {
  const _WidgetThemePanel({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final widgetThemes = store.cosmeticItems
        .where((item) => item.slot == 'widget_theme')
        .toList();
    return CatudyPanel(
      accentColor: CatudyColors.coral,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CatudySectionHeader(
            title: store.t('premium.widgetThemes'),
            icon: Icons.widgets_rounded,
            accentColor: CatudyColors.coral,
          ),
          const SizedBox(height: 10),
          _WidgetPreview(store: store),
          const SizedBox(height: 12),
          for (final item in widgetThemes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(item.icon, color: item.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  FilledButton(
                    onPressed: store.ownedCosmeticIds.contains(item.id)
                        ? () => store.equipCosmetic(item.id)
                        : null,
                    child: Text(
                      store.selectedWidgetThemeId == item.id
                          ? store.t('common.selected')
                          : store.t('inventory.equipped'),
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

class _WidgetPreview extends StatelessWidget {
  const _WidgetPreview({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final theme = store.cosmeticById(store.selectedWidgetThemeId);
    final accent = theme?.accent ?? CatudyColors.teal;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(theme?.icon ?? Icons.widgets_rounded, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  theme?.name ?? store.t('premium.widgetClassic'),
                  style: TextStyle(
                    color: CatudyColors.blueFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  store.t('premium.widgetPreview', {
                    'done': store.todayMinutes,
                    'goal': store.dailyGoalMinutes,
                  }),
                  style: TextStyle(color: CatudyColors.mutedFor(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}
