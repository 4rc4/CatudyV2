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
        fallbackBackPath: '/profile',
        children: [
          _PlusHero(store: store),
          const SizedBox(height: 14),
          _PlusBenefitsGrid(store: store),
          const SizedBox(height: 14),
          _PlusComparison(store: store),
          const SizedBox(height: 14),
          _PlanSelector(store: store),
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

class _PlusHero extends StatelessWidget {
  const _PlusHero({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      padding: const EdgeInsets.all(18),
      accentColor: CatudyColors.violet,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: CatudyColors.yellow,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        store.t('premium.heroTitle'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: CatudyColors.blueFor(context),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  store.t('premium.heroHeadline'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: CatudyColors.blueFor(context),
                    fontWeight: FontWeight.w900,
                    height: 1.04,
                  ),
                ),
                Text(
                  store.t('premium.heroAccent'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: CatudyColors.teal,
                    fontWeight: FontWeight.w900,
                    height: 1.04,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  store.t('premium.heroBody'),
                  style: TextStyle(
                    color: CatudyColors.mutedFor(context),
                    fontWeight: FontWeight.w800,
                    height: 1.28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 112,
            height: 126,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CatudyColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: CatudyColors.violet.withValues(alpha: 0.26),
              ),
            ),
            child: Image.asset('assets/brand/catudy-mascot.png'),
          ),
        ],
      ),
    );
  }
}

class _PlusBenefitsGrid extends StatelessWidget {
  const _PlusBenefitsGrid({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final benefits = [
      _BenefitData(
        Icons.wallpaper_rounded,
        store.t('premium.benefitRoomsTitle'),
        store.t('premium.benefitRoomsBody'),
      ),
      _BenefitData(
        Icons.checkroom_rounded,
        store.t('premium.benefitPetTitle'),
        store.t('premium.benefitPetBody'),
      ),
      _BenefitData(
        Icons.card_giftcard_rounded,
        store.t('premium.benefitSeasonTitle'),
        store.t('premium.benefitSeasonBody'),
      ),
      _BenefitData(
        Icons.query_stats_rounded,
        store.t('premium.benefitStatsTitle'),
        store.t('premium.benefitStatsBody'),
      ),
      _BenefitData(
        Icons.headphones_rounded,
        store.t('premium.benefitSoundTitle'),
        store.t('premium.benefitSoundBody'),
      ),
      _BenefitData(
        Icons.rocket_launch_rounded,
        store.t('premium.benefitEarlyTitle'),
        store.t('premium.benefitEarlyBody'),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          store.t('premium.whatYouGet'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: CatudyColors.blueFor(context),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: benefits.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.78,
          ),
          itemBuilder: (context, index) => _BenefitCard(data: benefits[index]),
        ),
      ],
    );
  }
}

class _BenefitData {
  const _BenefitData(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({required this.data});

  final _BenefitData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceStrongFor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: CatudyColors.violet.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: CatudyColors.violet.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(data.icon, color: CatudyColors.violet),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CatudyColors.blueFor(context),
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CatudyColors.mutedFor(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.12,
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

class _PlusComparison extends StatelessWidget {
  const _PlusComparison({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final rows = [
      (
        Icons.home_rounded,
        store.t('premium.compareRooms'),
        '3',
        store.t('premium.compareAll'),
      ),
      (
        Icons.checkroom_rounded,
        store.t('premium.comparePet'),
        store.t('premium.compareBasic'),
        store.t('premium.compareExclusive'),
      ),
      (
        Icons.card_giftcard_rounded,
        store.t('premium.compareSeason'),
        '—',
        store.t('common.yes'),
      ),
      (
        Icons.bar_chart_rounded,
        store.t('premium.compareStats'),
        store.t('premium.compareBasic'),
        store.t('premium.compareAdvanced'),
      ),
      (
        Icons.workspace_premium_rounded,
        store.t('premium.compareBadges'),
        '—',
        store.t('common.yes'),
      ),
    ];
    return CatudyPanel(
      padding: const EdgeInsets.all(14),
      accentColor: CatudyColors.violet,
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: SizedBox()),
              Expanded(
                child: Center(
                  child: Text(
                    store.t('premium.freeColumn'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    store.t('premium.plusColumn'),
                    style: const TextStyle(
                      color: CatudyColors.teal,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(row.$1, size: 18, color: CatudyColors.violet),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            row.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: Center(child: Text(row.$3))),
                  Expanded(
                    child: Center(
                      child: Text(
                        row.$4,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: CatudyColors.teal,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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

class _PlanSelector extends StatelessWidget {
  const _PlanSelector({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      accentColor: CatudyColors.teal,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _PlanCard(
                  title: store.t('premium.monthly'),
                  price: store.t('premium.monthlyPrice'),
                  selected: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PlanCard(
                  title: store.t('premium.yearly'),
                  price: store.t('premium.yearlyPrice'),
                  badge: store.t('premium.bestValue'),
                  selected: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: store.hasPremiumAccess
                  ? store.clearPremiumEntitlement
                  : store.activatePremiumDemo,
              icon: const Icon(Icons.workspace_premium_rounded),
              label: Text(
                store.hasPremiumAccess
                    ? store.t('premium.clearDemo')
                    : store.t('premium.trialCta'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            store.t('premium.cancelAnytime'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.selected,
    this.badge,
  });

  final String title;
  final String price;
  final bool selected;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected
                ? CatudyColors.violet.withValues(alpha: 0.14)
                : CatudyColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? CatudyColors.teal
                  : CatudyColors.lineFor(context),
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? CatudyColors.yellow
                    : CatudyColors.mutedFor(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: CatudyColors.blueFor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      price,
                      style: TextStyle(color: CatudyColors.mutedFor(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (badge != null)
          Positioned(
            top: -10,
            left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: CatudyColors.violet,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
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
        onPressed: () => context.push('/season?from=profile'),
        icon: const Icon(Icons.emoji_events_rounded),
        label: Text(store.t('premium.openSeason')),
      ),
      FilledButton.tonalIcon(
        onPressed: () => context.push('/crates?from=profile'),
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
