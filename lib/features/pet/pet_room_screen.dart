import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../features/onboarding/pet_intro_tour.dart';
import '../../shared/widgets/catudy_info_bubble.dart';
import '../../shared/widgets/floating_mascot.dart';
import '../../shared/widgets/store_builder.dart';

class PetRoomScreen extends StatefulWidget {
  const PetRoomScreen({super.key});

  @override
  State<PetRoomScreen> createState() => _PetRoomScreenState();
}

class _PetRoomScreenState extends State<PetRoomScreen> {
  static const _greetingVisibleDuration = Duration(seconds: 4);

  late final int _dialogueIndex;
  Timer? _greetingTimer;
  bool _showGreeting = true;

  static const _dialoguesTr = [
    'Burada olduğunu bilmiyordum! Odayı biraz daha güzelleştirelim mi?',
    'Ders çalışmaya hazır mısın? Ben bugün masanın yanında bekliyorum.',
    'Bir odak seansı yaparsan battaniyemi kabartıp seni alkışlarım.',
    'Bugün biraz sakinim. Kısa bir çalışma ritmi iyi gelebilir.',
    'Masadaki ışık tam yerinde. Başlamak için güzel bir gün.',
    'Ben buradayım. Sen odaklanırken odaya göz kulak olurum.',
    'Koltuk çok rahat ama önce küçük bir odak turu yapalım mı?',
    'Yatağıma zıplamadım. Tamam, belki biraz zıplamış olabilirim.',
    'Bugün oda çok sakin. Bir süre çalışırsan ben de burada beklerim.',
    'Yeni bir eşya açınca odamız daha tatlı görünecek, söz.',
  ];

  static const _dialoguesEn = [
    'I did not know you were here! Should we make the room cuter?',
    'Ready to study? I will wait by your desk today.',
    'Finish a focus session and I will cheer for you from my blanket.',
    'I feel calm today. A short study rhythm could be nice.',
    'The desk light is just right. Good day to begin.',
    'I am here. I will watch the room while you focus.',
    'The sofa is comfy, but maybe one small focus round first?',
    'I did not jump on my bed. Okay, maybe just a little.',
    'The room is quiet today. I can wait here while you study.',
    'Unlock a new item and our room will look even sweeter.',
  ];

  @override
  void initState() {
    super.initState();
    _dialogueIndex =
        DateTime.now().millisecondsSinceEpoch % _dialoguesTr.length;
    _greetingTimer = Timer(_greetingVisibleDuration, _hideGreeting);
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    super.dispose();
  }

  void _hideGreeting() {
    if (!mounted || !_showGreeting) {
      return;
    }
    setState(() => _showGreeting = false);
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        final equippedItem = store.equippedPetItemId == null
            ? null
            : store.shopItemById(store.equippedPetItemId!);
        final equipped = equippedItem == null
            ? store.t('pet.noCosmetic')
            : store.itemName(equippedItem);
        final dialogue = store.languageCode == 'en'
            ? _dialoguesEn[_dialogueIndex % _dialoguesEn.length]
            : _dialoguesTr[_dialogueIndex];
        final studyItem = store.roomItemForSlot('room_study');
        final bedItem = store.roomItemForSlot('room_bed');
        final decorItem = store.roomItemForSlot('room_decor');
        final shelfItem = store.roomItemForSlot('room_shelf');

        return SizedBox.expand(
          child: _RoomScene(
            petName: store.selectedPet.name,
            equipped: equipped,
            dialogue: dialogue,
            showGreeting: _showGreeting,
            mood: store.petMood,
            hunger: store.petHunger,
            energy: store.petEnergy,
            gold: store.gold,
            studying: store.activeSession != null,
            rewardBoostPercent: store.focusRewardBoostPercent,
            studyItem: studyItem,
            bedItem: bedItem,
            decorItem: decorItem,
            shelfItem: shelfItem,
            maintenanceTitle: store.t('pet.roomMaintenanceTitle'),
            maintenanceBody: store.t('pet.roomMaintenanceBody'),
            onSettings: () => context.go('/settings'),
            onInfo: () => showPetIntroTour(context),
            onShop: () => context.go('/shop'),
            onInventory: () => context.go('/inventory'),
          ),
        );
      },
    );
  }
}

class _RoomScene extends StatelessWidget {
  const _RoomScene({
    required this.petName,
    required this.equipped,
    required this.dialogue,
    required this.showGreeting,
    required this.mood,
    required this.hunger,
    required this.energy,
    required this.gold,
    required this.studying,
    required this.rewardBoostPercent,
    required this.studyItem,
    required this.bedItem,
    required this.decorItem,
    required this.shelfItem,
    required this.maintenanceTitle,
    required this.maintenanceBody,
    required this.onSettings,
    required this.onInfo,
    required this.onShop,
    required this.onInventory,
  });

  final String petName;
  final String equipped;
  final String dialogue;
  final bool showGreeting;
  final int mood;
  final int hunger;
  final int energy;
  final int gold;
  final bool studying;
  final double rewardBoostPercent;
  final ShopItem? studyItem;
  final ShopItem? bedItem;
  final ShopItem? decorItem;
  final ShopItem? shelfItem;
  final String maintenanceTitle;
  final String maintenanceBody;
  final VoidCallback onSettings;
  final VoidCallback onInfo;
  final VoidCallback onShop;
  final VoidCallback onInventory;

  @override
  Widget build(BuildContext context) {
    final dark = CatudyColors.isDark(context);

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final roomWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 390.0;
          final roomHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 760.0;
          final wallBottom = roomHeight * 0.55;
          final controlsReserve = (roomHeight * 0.23)
              .clamp(178.0, 202.0)
              .toDouble();
          final sceneBottom = roomHeight - controlsReserve;
          final floorTop = wallBottom + 4;
          final floorItemBottom = sceneBottom - 8;
          final horizontalInset = (roomWidth * 0.06)
              .clamp(18.0, 28.0)
              .toDouble();
          final shelfWidth = (roomWidth * 0.31).clamp(126.0, 158.0).toDouble();
          final shelfHeight = shelfWidth * 1.20;
          final windowWidth = (roomWidth * 0.30).clamp(130.0, 160.0).toDouble();
          final windowHeight = windowWidth * 0.78;
          final lanternWidth = (roomWidth * 0.20).clamp(74.0, 104.0).toDouble();
          final lanternHeight = lanternWidth * 1.94;
          final bedWidth = (roomWidth * 0.32).clamp(128.0, 170.0).toDouble();
          final bedHeight = bedWidth * 0.86;
          final studyWidth = (roomWidth * 0.38).clamp(152.0, 196.0).toDouble();
          final studyHeight = studyWidth * 0.72;
          final rugHeight = (roomHeight * 0.18).clamp(126.0, 158.0).toDouble();
          final rugInset = (roomWidth * 0.08).clamp(24.0, 42.0).toDouble();
          final petSize = (roomWidth * (studying ? 0.34 : 0.38))
              .clamp(138.0, 188.0)
              .toDouble();
          final petBoxWidth = petSize * (studying ? 1.32 : 1.18);
          final petBoxHeight = petSize * (studying ? 1.05 : 1.14);
          final petCenterX = roomWidth * (studying ? 0.60 : 0.50);
          final maxPetLeft = (roomWidth - petBoxWidth - 24).clamp(
            24.0,
            roomWidth,
          );
          final petLeft = (petCenterX - petBoxWidth / 2)
              .clamp(24.0, maxPetLeft)
              .toDouble();
          final petBottom = (roomHeight - sceneBottom + 2)
              .clamp(188.0, 226.0)
              .toDouble();
          final speechBottom = (petBottom + petBoxHeight - 8)
              .clamp(roomHeight * 0.43, roomHeight * 0.62)
              .toDouble();
          double floorTopFor(double itemHeight, double extraLift) {
            final maxTop = floorItemBottom - itemHeight;
            if (maxTop <= floorTop) {
              return maxTop
                  .clamp(roomHeight * 0.32, floorItemBottom)
                  .toDouble();
            }
            return (maxTop - extraLift).clamp(floorTop, maxTop).toDouble();
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: _RoomBackground(dark: dark)),
              Positioned(
                left: horizontalInset,
                right: horizontalInset,
                top: (roomHeight * 0.02).clamp(10.0, 18.0).toDouble(),
                child: _RoomTopBar(
                  petName: petName,
                  gold: gold,
                  rewardBoostPercent: rewardBoostPercent,
                  onSettings: onSettings,
                  onInfo: onInfo,
                ),
              ),
              Positioned(
                left: horizontalInset,
                right: horizontalInset,
                top: (roomHeight * 0.108).clamp(78.0, 98.0).toDouble(),
                child: _RoomMaintenanceBanner(
                  title: maintenanceTitle,
                  body: maintenanceBody,
                ),
              ),
              Positioned(
                left: roomWidth * 0.07,
                top: roomHeight * 0.245,
                child: _TinyShelf(
                  item: shelfItem,
                  width: shelfWidth,
                  height: shelfHeight,
                ),
              ),
              Positioned(
                right: roomWidth * 0.07,
                top: roomHeight * 0.205,
                child: _RoomWindow(width: windowWidth, height: windowHeight),
              ),
              Positioned(
                right: roomWidth * 0.045,
                top: floorTopFor(lanternHeight, 18),
                child: _CozySofa(
                  item: decorItem,
                  width: lanternWidth,
                  height: lanternHeight,
                ),
              ),
              Positioned(
                right: roomWidth * 0.095,
                top: floorTopFor(bedHeight, 6),
                child: _PetBed(
                  item: bedItem,
                  width: bedWidth,
                  height: bedHeight,
                ),
              ),
              Positioned(
                left: roomWidth * 0.045,
                top: floorTopFor(studyHeight, 8),
                child: _StudyDesk(
                  item: studyItem,
                  studying: studying,
                  width: studyWidth,
                  height: studyHeight,
                ),
              ),
              Positioned(
                left: rugInset,
                right: rugInset,
                bottom: (roomHeight - sceneBottom + 14)
                    .clamp(196.0, 236.0)
                    .toDouble(),
                height: rugHeight,
                child: Image.asset(
                  'assets/room/generated/roomfit_focus_rug.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  isAntiAlias: true,
                ),
              ),
              Positioned(
                left: petLeft,
                bottom: petBottom,
                child: _RoomPet(
                  studying: studying,
                  mascotSize: petSize,
                  boxWidth: petBoxWidth,
                  boxHeight: petBoxHeight,
                ),
              ),
              Positioned(
                left: horizontalInset + 8,
                right: horizontalInset + 8,
                bottom: speechBottom,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: showGreeting ? 1 : 0,
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                    child: _SpeechBubble(message: dialogue),
                  ),
                ),
              ),
              Positioned(
                left: horizontalInset,
                right: horizontalInset,
                bottom: 18,
                child: Column(
                  children: [
                    _CarePanel(
                      mood: mood,
                      hunger: hunger,
                      energy: energy,
                      equipped: equipped,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: FilledButton.icon(
                              onPressed: onShop,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 42),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              icon: const Icon(
                                Icons.storefront_rounded,
                                size: 19,
                              ),
                              label: Text(catudyDemoStore.t('pet.shop')),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: FilledButton.icon(
                              onPressed: onInventory,
                              style: FilledButton.styleFrom(
                                backgroundColor: CatudyColors.tealDark,
                                minimumSize: const Size(0, 42),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              icon: const Icon(
                                Icons.inventory_2_rounded,
                                size: 19,
                              ),
                              label: Text(catudyDemoStore.t('pet.inventory')),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoomBackground extends StatelessWidget {
  const _RoomBackground({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RoomPerspectivePainter(dark: dark),
      child: Stack(
        children: [
          Positioned(
            left: 30,
            top: 118,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: CatudyColors.teal.withValues(alpha: 0.42),
              size: 24,
            ),
          ),
          Positioned(
            right: 110,
            top: 156,
            child: Icon(
              Icons.star_rounded,
              color: CatudyColors.violet.withValues(alpha: 0.26),
              size: 20,
            ),
          ),
          Positioned(
            left: 54,
            right: 54,
            top: 96,
            child: Container(
              height: 2,
              color: (dark ? Colors.white : CatudyColors.violet).withValues(
                alpha: dark ? 0.08 : 0.10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomMaintenanceBanner extends StatelessWidget {
  const _RoomMaintenanceBanner({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final dark = CatudyColors.isDark(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceFor(context).withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (dark ? CatudyColors.yellow : CatudyColors.coral).withValues(
            alpha: 0.30,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: (dark ? Colors.black : CatudyColors.violet).withValues(
              alpha: dark ? 0.20 : 0.10,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: CatudyColors.yellow.withValues(alpha: dark ? 0.22 : 0.34),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.construction_rounded,
              color: CatudyColors.coral,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CatudyColors.blueFor(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CatudyColors.mutedFor(context),
                    fontSize: 11,
                    height: 1.16,
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

class _RoomPerspectivePainter extends CustomPainter {
  const _RoomPerspectivePainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final wallBottom = size.height * 0.54;
    final vanishingPoint = Offset(size.width / 2, wallBottom - 18);
    final backWall = Rect.fromLTWH(0, 0, size.width, wallBottom + 18);
    final wallPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: dark
            ? const [Color(0xFF211B3A), Color(0xFF28224A)]
            : const [Color(0xFFF2EEFF), Color(0xFFE9FAF7)],
      ).createShader(backWall);
    canvas.drawRect(backWall, wallPaint);

    final floor = Path()
      ..moveTo(0, wallBottom)
      ..lineTo(size.width, wallBottom)
      ..lineTo(size.width + 72, size.height)
      ..lineTo(-72, size.height)
      ..close();
    final floorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: dark
            ? const [Color(0xFF19142C), Color(0xFF120E22)]
            : const [Color(0xFFFFF7F0), Color(0xFFFFE8D8)],
      ).createShader(Rect.fromLTWH(0, wallBottom, size.width, size.height));
    canvas.drawPath(floor, floorPaint);

    final leftWall = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.11, 0)
      ..lineTo(size.width * 0.19, wallBottom)
      ..lineTo(0, wallBottom + 62)
      ..close();
    final rightWall = Path()
      ..moveTo(size.width * 0.89, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, wallBottom + 62)
      ..lineTo(size.width * 0.81, wallBottom)
      ..close();
    final sidePaint = Paint()
      ..color = (dark ? Colors.black : CatudyColors.violet).withValues(
        alpha: dark ? 0.14 : 0.06,
      );
    canvas.drawPath(leftWall, sidePaint);
    canvas.drawPath(rightWall, sidePaint);

    final linePaint = Paint()
      ..color = (dark ? Colors.white : CatudyColors.violet).withValues(
        alpha: dark ? 0.08 : 0.10,
      )
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, wallBottom),
      Offset(size.width, wallBottom),
      linePaint,
    );
    final baseboardPaint = Paint()
      ..color = (dark ? const Color(0xFF504673) : const Color(0xFFD8C8FF))
          .withValues(alpha: dark ? 0.40 : 0.42)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(14, wallBottom - 4),
      Offset(size.width - 14, wallBottom - 4),
      baseboardPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.19, wallBottom),
      Offset(0, wallBottom + 62),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.81, wallBottom),
      Offset(size.width, wallBottom + 62),
      linePaint,
    );

    final floorLinePaint = Paint()
      ..color = (dark ? Colors.white : CatudyColors.tealDark).withValues(
        alpha: dark ? 0.05 : 0.065,
      )
      ..strokeWidth = 1;

    for (var i = 0; i < 6; i++) {
      final y = wallBottom + 26 + i * 42;
      canvas.drawLine(
        Offset(-32, y),
        Offset(size.width + 32, y + 10),
        floorLinePaint,
      );
    }
    for (final x in <double>[
      size.width * 0.20,
      size.width * 0.34,
      size.width * 0.50,
      size.width * 0.66,
      size.width * 0.80,
    ]) {
      canvas.drawLine(Offset(x, size.height), vanishingPoint, floorLinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoomPerspectivePainter oldDelegate) {
    return oldDelegate.dark != dark;
  }
}

class _RoomTopBar extends StatelessWidget {
  const _RoomTopBar({
    required this.petName,
    required this.gold,
    required this.rewardBoostPercent,
    required this.onSettings,
    required this.onInfo,
  });

  final String petName;
  final int gold;
  final double rewardBoostPercent;
  final VoidCallback onSettings;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                catudyDemoStore.t('pet.room'),
                style: TextStyle(
                  color: CatudyColors.tealDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                catudyDemoStore.t('pet.roomName', {'pet': petName}),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: CatudyColors.blueFor(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                catudyDemoStore.t('pet.roomSubtitle'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: CatudyColors.mutedFor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Chip(
          avatar: const Icon(Icons.savings_rounded, size: 16),
          label: Text('$gold'),
        ),
        if (rewardBoostPercent > 0) ...[
          const SizedBox(width: 6),
          Chip(
            avatar: const Icon(Icons.trending_up_rounded, size: 16),
            label: Text('+${rewardBoostPercent.toStringAsFixed(1)}%'),
          ),
        ],
        const SizedBox(width: 6),
        IconButton.filledTonal(
          onPressed: onInfo,
          tooltip: catudyDemoStore.t('pet.showTour'),
          icon: const Icon(Icons.info_rounded),
        ),
        const SizedBox(width: 4),
        IconButton.filledTonal(
          onPressed: onSettings,
          tooltip: catudyDemoStore.t('pet.settings'),
          icon: const Icon(Icons.settings_rounded),
        ),
      ],
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: CatudyColors.surfaceFor(context).withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: CatudyColors.teal.withValues(alpha: 0.30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: CatudyColors.violet.withValues(alpha: 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: CatudyColors.mutedFor(context),
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Positioned(
              left: 34,
              bottom: -10,
              child: Transform.rotate(
                angle: 0.78,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: CatudyColors.surfaceFor(
                      context,
                    ).withValues(alpha: 0.78),
                    border: Border(
                      right: BorderSide(
                        color: CatudyColors.teal.withValues(alpha: 0.30),
                      ),
                      bottom: BorderSide(
                        color: CatudyColors.teal.withValues(alpha: 0.30),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarePanel extends StatelessWidget {
  const _CarePanel({
    required this.mood,
    required this.hunger,
    required this.energy,
    required this.equipped,
  });

  final int mood;
  final int hunger;
  final int energy;
  final String equipped;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceFor(context).withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CatudyColors.teal.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: CatudyColors.tealDark,
                size: 16,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  equipped,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CatudyColors.mutedFor(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          _PetMeter(
            label: catudyDemoStore.t('pet.mood'),
            value: mood,
            color: CatudyColors.tealDark,
            info:
                'Mutluluk, düzenli odaklanma ve pet için alınan eşyalarla artar. Mutlu pet odada daha canlı görünür.',
          ),
          const SizedBox(height: 4),
          _PetMeter(
            label: catudyDemoStore.t('home.hunger'),
            value: hunger,
            color: CatudyColors.violet,
            inverse: true,
            info:
                'Açlık yükseldikçe bakım dengesi düşer. İleride yiyecek ve mobilya sistemleriyle daha ayrıntılı yönetilecek.',
          ),
          const SizedBox(height: 4),
          _PetMeter(
            label: catudyDemoStore.t('pet.energy'),
            value: energy,
            color: CatudyColors.teal,
            info:
                'Enerji, petin çalışma temposunu gösterir. Odak seansları enerji harcar; iyi ritim peti dengede tutar.',
          ),
        ],
      ),
    );
  }
}

class _RoomWindow extends StatelessWidget {
  const _RoomWindow({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _RoomFurnitureAsset(
      path: 'assets/room/generated/roomfit_window.png',
      width: width,
      height: height,
    );
  }
}

class _RoomPet extends StatelessWidget {
  const _RoomPet({
    required this.studying,
    required this.mascotSize,
    required this.boxWidth,
    required this.boxHeight,
  });

  final bool studying;
  final double mascotSize;
  final double boxWidth;
  final double boxHeight;

  @override
  Widget build(BuildContext context) {
    final shadowWidth = mascotSize * (studying ? 0.64 : 0.70);
    final shadowHeight = mascotSize * 0.14;
    final noteScale = (mascotSize / 190).clamp(0.78, 1.05).toDouble();

    return SizedBox(
      width: boxWidth,
      height: boxHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: studying ? 4 : 0,
            child: Container(
              width: shadowWidth,
              height: shadowHeight,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            bottom: shadowHeight * 0.12,
            child: FloatingMascot(width: mascotSize, height: mascotSize),
          ),
          if (studying)
            Positioned(
              right: mascotSize * 0.16,
              bottom: mascotSize * 0.15,
              child: Transform.scale(
                scale: noteScale,
                child: const _StudyMotion(),
              ),
            ),
        ],
      ),
    );
  }
}

class _StudyMotion extends StatefulWidget {
  const _StudyMotion();

  @override
  State<_StudyMotion> createState() => _StudyMotionState();
}

class _StudyMotionState extends State<_StudyMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.rotate(
          angle: -0.16 + t * 0.32,
          child: Container(
            width: 56,
            height: 42,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: CatudyColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: CatudyColors.teal.withValues(alpha: 0.32),
              ),
              boxShadow: [
                BoxShadow(
                  color: CatudyColors.violet.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: CatudyColors.tealDark,
            ),
          ),
        );
      },
    );
  }
}

class _StudyDesk extends StatelessWidget {
  const _StudyDesk({
    required this.item,
    required this.studying,
    required this.width,
    required this.height,
  });

  final ShopItem? item;
  final bool studying;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final assetPath = item?.assetPath;
    if (assetPath != null) {
      return _RoomFurnitureAsset(
        path: assetPath,
        width: width,
        height: height,
        overlay: studying
            ? Positioned(
                right: 24,
                top: 8,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: CatudyColors.yellow.withValues(alpha: 0.30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: CatudyColors.coral,
                    size: 18,
                  ),
                ),
              )
            : null,
      );
    }
    final accent = item?.accent ?? CatudyColors.teal;
    final premium = item != null;
    return SizedBox(
      width: 172,
      height: 150,
      child: Stack(
        children: [
          Positioned(
            left: 14,
            right: 4,
            top: 92,
            child: Container(
              height: 22,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 10,
            top: 58,
            child: Container(
              height: premium ? 34 : 28,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: premium ? 0.72 : 0.46),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accent.withValues(alpha: 0.22)),
              ),
            ),
          ),
          Positioned(left: 30, top: 84, child: _FurnitureLeg(color: accent)),
          Positioned(right: 34, top: 84, child: _FurnitureLeg(color: accent)),
          Positioned(
            left: premium ? 16 : 20,
            top: premium ? 12 : 22,
            child: Container(
              width: premium ? 58 : 46,
              height: premium ? 44 : 34,
              decoration: BoxDecoration(
                color: CatudyColors.surfaceFor(context).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withValues(alpha: 0.22)),
              ),
              child: Icon(
                premium ? Icons.auto_stories_rounded : Icons.menu_book_rounded,
                color: accent,
              ),
            ),
          ),
          Positioned(
            right: 18,
            top: premium ? 2 : 12,
            child: Container(
              width: premium ? 42 : 34,
              height: premium ? 64 : 52,
              decoration: BoxDecoration(
                color: (studying ? CatudyColors.yellow : accent).withValues(
                  alpha: studying ? 0.36 : 0.18,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.lightbulb_rounded,
                color: studying ? CatudyColors.coral : accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PetBed extends StatelessWidget {
  const _PetBed({
    required this.item,
    required this.width,
    required this.height,
  });

  final ShopItem? item;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final assetPath = item?.assetPath;
    if (assetPath != null) {
      return _RoomFurnitureAsset(path: assetPath, width: width, height: height);
    }
    final accent = item?.accent ?? CatudyColors.lavender;
    final premium = item != null;
    return SizedBox(
      width: 158,
      height: 126,
      child: Stack(
        children: [
          Positioned(
            left: 10,
            right: 8,
            bottom: 8,
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 20,
            child: Container(
              height: premium ? 62 : 50,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: premium ? 0.32 : 0.22),
                borderRadius: BorderRadius.circular(premium ? 34 : 28),
                border: Border.all(
                  color: accent.withValues(alpha: premium ? 0.38 : 0.22),
                ),
              ),
            ),
          ),
          Positioned(
            left: premium ? 28 : 34,
            top: premium ? 20 : 28,
            child: Container(
              width: premium ? 88 : 74,
              height: premium ? 46 : 36,
              decoration: BoxDecoration(
                color: CatudyColors.surfaceFor(context).withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withValues(alpha: 0.18)),
              ),
              child: Icon(
                premium ? Icons.nights_stay_rounded : Icons.bed_rounded,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CozySofa extends StatelessWidget {
  const _CozySofa({
    required this.item,
    required this.width,
    required this.height,
  });

  final ShopItem? item;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final assetPath = item?.assetPath;
    if (assetPath != null) {
      return _RoomFurnitureAsset(path: assetPath, width: width, height: height);
    }
    final accent = item?.accent ?? CatudyColors.violet;
    return SizedBox(
      width: 136,
      height: 118,
      child: Stack(
        children: [
          Positioned(
            left: 18,
            right: 10,
            bottom: 8,
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: 32,
            bottom: 20,
            child: Container(
              width: item == null ? 48 : 58,
              height: item == null ? 56 : 72,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: item == null ? 0.22 : 0.34),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: accent.withValues(alpha: 0.20)),
              ),
              child: Icon(
                item == null
                    ? Icons.local_florist_rounded
                    : Icons.emoji_objects_rounded,
                color: accent,
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 12,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: CatudyColors.surfaceFor(context).withValues(alpha: 0.62),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome_rounded, color: accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyShelf extends StatelessWidget {
  const _TinyShelf({
    required this.item,
    required this.width,
    required this.height,
  });

  final ShopItem? item;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final assetPath = item?.assetPath;
    if (assetPath != null) {
      return _RoomFurnitureAsset(path: assetPath, width: width, height: height);
    }
    final accent = item?.accent ?? CatudyColors.tealDark;
    return SizedBox(
      width: 126,
      height: 132,
      child: Stack(
        children: [
          Positioned(
            left: 8,
            right: 16,
            bottom: 8,
            child: Container(
              height: 18,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          for (var index = 0; index < 3; index++)
            Positioned(
              top: 28.0 + (index * 26),
              left: 8,
              right: 18,
              child: Container(
                height: item == null ? 8 : 10,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: item == null ? 0.34 : 0.50),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          Positioned(
            left: 14,
            top: 4,
            child: Icon(
              item == null
                  ? Icons.local_florist_rounded
                  : Icons.menu_book_rounded,
              color: accent,
              size: item == null ? 28 : 34,
            ),
          ),
          Positioned(
            right: 8,
            top: 48,
            child: Icon(Icons.auto_awesome_rounded, color: accent),
          ),
        ],
      ),
    );
  }
}

class _RoomFurnitureAsset extends StatelessWidget {
  const _RoomFurnitureAsset({
    required this.path,
    required this.width,
    required this.height,
    this.overlay,
  });

  final String path;
  final double width;
  final double height;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Image.asset(
              path,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              isAntiAlias: true,
            ),
          ),
          ?overlay,
        ],
      ),
    );
  }
}

class _FurnitureLeg extends StatelessWidget {
  const _FurnitureLeg({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _PetMeter extends StatelessWidget {
  const _PetMeter({
    required this.label,
    required this.value,
    required this.color,
    required this.info,
    this.inverse = false,
  });

  final String label;
  final int value;
  final Color color;
  final String info;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final displayValue = inverse ? 100 - value : value;
    return CatudyInfoTap(
      title: label,
      message: info,
      child: Container(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 12,
                      color: CatudyColors.tealDark,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Text('$value/100', style: const TextStyle(fontSize: 11)),
              ],
            ),
            const SizedBox(height: 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: displayValue / 100,
                minHeight: 7,
                color: color,
                backgroundColor: CatudyColors.surfaceStrongFor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
