// ignore_for_file: unused_element

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../features/onboarding/pet_intro_tour.dart';
import '../../shared/widgets/catudy_info_bubble.dart';
import '../../shared/widgets/catudy_visual_system.dart';
import '../../shared/widgets/floating_mascot.dart';
import '../../shared/widgets/shop_item_art.dart';
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
  bool _petNameDialogOpen = false;

  static const _dialoguesTr = [
    'Burada olduÄŸunu bilmiyordum! OdayÄ± biraz daha gÃ¼zelleÅŸtirelim mi?',
    'Ders Ã§alÄ±ÅŸmaya hazÄ±r mÄ±sÄ±n? Ben bugÃ¼n masanÄ±n yanÄ±nda bekliyorum.',
    'Bir odak seansÄ± yaparsan battaniyemi kabartÄ±p seni alkÄ±ÅŸlarÄ±m.',
    'BugÃ¼n biraz sakinim. KÄ±sa bir Ã§alÄ±ÅŸma ritmi iyi gelebilir.',
    'Masadaki Ä±ÅŸÄ±k tam yerinde. BaÅŸlamak iÃ§in gÃ¼zel bir gÃ¼n.',
    'Ben buradayÄ±m. Sen odaklanÄ±rken odaya gÃ¶z kulak olurum.',
    'Koltuk Ã§ok rahat ama Ã¶nce kÃ¼Ã§Ã¼k bir odak turu yapalÄ±m mÄ±?',
    'YataÄŸÄ±ma zÄ±plamadÄ±m. Tamam, belki biraz zÄ±plamÄ±ÅŸ olabilirim.',
    'BugÃ¼n oda Ã§ok sakin. Bir sÃ¼re Ã§alÄ±ÅŸÄ±rsan ben de burada beklerim.',
    'Yeni bir eÅŸya aÃ§Ä±nca odamÄ±z daha tatlÄ± gÃ¶rÃ¼necek, sÃ¶z.',
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

  static const _storybookDialoguesTr = [
    'Bir sayfa daha, sonra birlikte yÄ±ldÄ±zlarÄ± sayarÄ±z.',
    'BugÃ¼nÃ¼n kÃ¼Ã§Ã¼k gayreti yarÄ±nÄ±n masalÄ±nÄ± biraz daha gÃ¼zelleÅŸtirir.',
    'Sen Ã§alÄ±ÅŸÄ±rken ben de sessizce nÃ¶bet tutuyorum.',
  ];

  static const _storybookDialoguesEn = [
    'One more page, then we can count the stars together.',
    'A small effort today makes tomorrowâ€™s story kinder.',
    'While you study, I keep quiet watch beside you.',
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
        final visited = store.visitedRoomProfile;
        if (visited == null) {
          _schedulePetNameDialog(context, store);
        }
        final equippedItem = store.equippedPetItemForProfile(visited);
        final premiumPetStyle = visited == null
            ? store.cosmeticById(store.selectedPetStyleId)
            : null;
        final equipped =
            premiumPetStyle?.name ??
            (equippedItem == null
                ? store.t('pet.noCosmetic')
                : store.itemName(equippedItem));
        final premiumDialogueActive =
            visited == null &&
            store.selectedDialoguePackId == 'storybook_dialogues' &&
            store.ownedCosmeticIds.contains('storybook_dialogues');
        final dialoguePool = store.languageCode == 'en'
            ? [
                ..._dialoguesEn,
                if (premiumDialogueActive) ..._storybookDialoguesEn,
              ]
            : [
                ..._dialoguesTr,
                if (premiumDialogueActive) ..._storybookDialoguesTr,
              ];
        final dialogue = dialoguePool[_dialogueIndex % dialoguePool.length];
        final studyItem = store.roomItemForSlot('room_study', profile: visited);
        final bedItem = store.roomItemForSlot('room_bed', profile: visited);
        final decorItem = store.roomItemForSlot('room_decor', profile: visited);
        final shelfItem = store.roomItemForSlot('room_shelf', profile: visited);
        final roomEffect = visited == null
            ? store.cosmeticById(store.selectedRoomEffectId)
            : null;

        return SizedBox.expand(
          child: _RoomScene(
            petName: visited == null
                ? store.petDisplayName
                : store.t('pet.roomName', {'pet': visited.petName}),
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
            roomEffectAccent: roomEffect?.accent,
            maintenanceTitle: store.t('pet.roomMaintenanceTitle'),
            maintenanceBody: store.t('pet.roomMaintenanceBody'),
            visiting: visited != null,
            onSettings: () => context.push('/settings'),
            onInfo: () => showPetIntroTour(context),
            onShop: () => context.go('/shop'),
            onInventory: () => context.go('/inventory'),
            onReturnHome: store.clearVisitedRoom,
          ),
        );
      },
    );
  }

  void _schedulePetNameDialog(BuildContext context, CatudyDemoStore store) {
    if (store.petNameChosen || _petNameDialogOpen) {
      return;
    }
    _petNameDialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || store.petNameChosen) {
        _petNameDialogOpen = false;
        return;
      }
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _PetNameDialog(store: store),
      );
      if (mounted) {
        setState(() => _petNameDialogOpen = false);
      } else {
        _petNameDialogOpen = false;
      }
    });
  }
}

class _PetNameDialog extends StatefulWidget {
  const _PetNameDialog({required this.store});

  final CatudyDemoStore store;

  @override
  State<_PetNameDialog> createState() => _PetNameDialogState();
}

class _PetNameDialogState extends State<_PetNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.store.petNameSuggestions.first,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return AlertDialog(
      title: Text(store.t('pet.nameDialogTitle')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            store.t('pet.nameDialogBody'),
            style: TextStyle(
              color: CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: store.t('pet.nameField')),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in store.petNameSuggestions)
                ChoiceChip(
                  label: Text(name),
                  selected: _controller.text.trim() == name,
                  onSelected: (_) => setState(() {
                    _controller.text = name;
                    _controller.selection = TextSelection.collapsed(
                      offset: _controller.text.length,
                    );
                  }),
                ),
            ],
          ),
        ],
      ),
      actions: [
        FilledButton(onPressed: _save, child: Text(store.t('pet.nameSave'))),
      ],
    );
  }

  void _save() {
    widget.store.updatePetName(_controller.text);
    Navigator.of(context).pop();
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
    required this.roomEffectAccent,
    required this.maintenanceTitle,
    required this.maintenanceBody,
    required this.visiting,
    required this.onSettings,
    required this.onInfo,
    required this.onShop,
    required this.onInventory,
    required this.onReturnHome,
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
  final Color? roomEffectAccent;
  final String maintenanceTitle;
  final String maintenanceBody;
  final bool visiting;
  final VoidCallback onSettings;
  final VoidCallback onInfo;
  final VoidCallback onShop;
  final VoidCallback onInventory;
  final VoidCallback onReturnHome;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final roomWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 390.0;
          final roomHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 760.0;
          final controlsReserve = (roomHeight * 0.25)
              .clamp(188.0, 220.0)
              .toDouble();
          final horizontalInset = (roomWidth * 0.06)
              .clamp(18.0, 28.0)
              .toDouble();
          final window = _RoomSlotGeometry(
            left: (roomWidth - (roomWidth * 0.40).clamp(150.0, 188.0)) / 2,
            top: (roomHeight * 0.145).clamp(104.0, 140.0).toDouble(),
            width: (roomWidth * 0.40).clamp(150.0, 188.0).toDouble(),
            aspectRatio: 330 / 440,
          );
          final bookcase = _RoomSlotGeometry(
            left: roomWidth * 0.055,
            top: (roomHeight * 0.235).clamp(158.0, 196.0).toDouble(),
            width: (roomWidth * 0.29).clamp(112.0, 148.0).toDouble(),
            aspectRatio: 270 / 520,
          );
          final wallShelf = _RoomSlotGeometry(
            left: roomWidth * 0.66,
            top: (roomHeight * 0.205).clamp(142.0, 182.0).toDouble(),
            width: (roomWidth * 0.38).clamp(150.0, 196.0).toDouble(),
            aspectRatio: 340 / 230,
          );
          final studyDesk = _RoomSlotGeometry(
            left: roomWidth * 0.58,
            bottom: controlsReserve + 92,
            width: (roomWidth * 0.49).clamp(188.0, 238.0).toDouble(),
            aspectRatio: 420 / 360,
          );
          final catBed = _RoomSlotGeometry(
            left: -roomWidth * 0.025,
            bottom: controlsReserve + 86,
            width: (roomWidth * 0.43).clamp(166.0, 212.0).toDouble(),
            aspectRatio: 360 / 300,
          );
          final rug = _RoomSlotGeometry(
            left: (roomWidth * 0.10).clamp(30.0, 46.0).toDouble(),
            right: (roomWidth * 0.10).clamp(30.0, 46.0).toDouble(),
            bottom: controlsReserve + 38,
            height: (roomHeight * 0.18).clamp(122.0, 154.0).toDouble(),
          );
          final petSize = (roomWidth * (studying ? 0.25 : 0.27))
              .clamp(96.0, 122.0)
              .toDouble();
          final petBoxWidth = petSize * (studying ? 1.32 : 1.18);
          final petBoxHeight = petSize * (studying ? 1.05 : 1.14);
          final petCenterX = roomWidth * (studying ? 0.53 : 0.50);
          final maxPetLeft = (roomWidth - petBoxWidth - 24).clamp(
            24.0,
            roomWidth,
          );
          final petLeft = (petCenterX - petBoxWidth / 2)
              .clamp(24.0, maxPetLeft)
              .toDouble();
          final petBottom = (controlsReserve + 58)
              .clamp(226.0, 276.0)
              .toDouble();
          final speechBottom = (petBottom + petBoxHeight - 8)
              .clamp(roomHeight * 0.43, roomHeight * 0.62)
              .toDouble();

          return Stack(
            fit: StackFit.expand,
            children: [
              const Positioned.fill(child: _RoomBackground()),
              if (roomEffectAccent != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topCenter,
                          radius: 1.15,
                          colors: [
                            roomEffectAccent!.withValues(alpha: 0.24),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              window.positioned(
                child: _RoomWindow(
                  width: window.resolvedWidth,
                  height: window.resolvedHeight,
                ),
              ),
              bookcase.positioned(
                child: _TinyShelf(
                  item: shelfItem,
                  width: bookcase.resolvedWidth,
                  height: bookcase.resolvedHeight,
                ),
              ),
              wallShelf.positioned(
                child: _RoomLamp(
                  item: decorItem,
                  width: wallShelf.resolvedWidth,
                  height: wallShelf.resolvedHeight,
                ),
              ),
              rug.positioned(child: const _PerspectiveRug()),
              catBed.positioned(
                child: _PetBed(
                  item: bedItem,
                  width: catBed.resolvedWidth,
                  height: catBed.resolvedHeight,
                ),
              ),
              studyDesk.positioned(
                child: _StudyDesk(
                  item: studyItem,
                  width: studyDesk.resolvedWidth,
                  height: studyDesk.resolvedHeight,
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
                    if (visiting)
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: FilledButton.icon(
                          onPressed: onReturnHome,
                          icon: const Icon(Icons.home_rounded, size: 19),
                          label: Text(catudyDemoStore.t('pet.returnMyRoom')),
                        ),
                      )
                    else
                      _RoomCustomizeStrip(
                        onInventory: onInventory,
                        onShop: onShop,
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

class _RoomSlotGeometry {
  const _RoomSlotGeometry({
    this.left,
    this.right,
    this.top,
    this.bottom,
    this.width,
    this.height,
    this.aspectRatio,
  }) : assert(width != null || (left != null && right != null));

  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double? width;
  final double? height;
  final double? aspectRatio;

  double get resolvedWidth => width!;

  double get resolvedHeight {
    if (height != null) {
      return height!;
    }
    return resolvedWidth / aspectRatio!;
  }

  Widget positioned({required Widget child}) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      width: width,
      height: height ?? (width != null ? resolvedHeight : null),
      child: child,
    );
  }
}

class _RoomBackground extends StatelessWidget {
  const _RoomBackground();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/room/corner_room_background_v1.png',
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
    );
  }
}

class _RoomLayerAsset extends StatelessWidget {
  const _RoomLayerAsset({
    required this.path,
    required this.width,
    required this.height,
  });

  final String path;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
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
  const _RoomPerspectivePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final wallTop = size.height * 0.07;
    final wallBottom = size.height * 0.56;
    final sideInset = size.width * 0.12;
    final vanishingPoint = Offset(size.width * 0.50, wallBottom + 10);

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE6F4F6),
    );

    final ceiling = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - sideInset, wallTop)
      ..lineTo(sideInset, wallTop)
      ..close();
    canvas.drawPath(ceiling, Paint()..color = const Color(0xFFF3FAFA));

    final leftWall = Path()
      ..moveTo(0, 0)
      ..lineTo(sideInset, wallTop)
      ..lineTo(sideInset, wallBottom)
      ..lineTo(0, wallBottom + 56)
      ..close();
    final rightWall = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width - sideInset, wallTop)
      ..lineTo(size.width - sideInset, wallBottom)
      ..lineTo(size.width, wallBottom + 56)
      ..close();
    canvas.drawPath(leftWall, Paint()..color = const Color(0xFFC4E4E9));
    canvas.drawPath(rightWall, Paint()..color = const Color(0xFFAED2DA));

    final backWall = Rect.fromLTRB(
      sideInset,
      wallTop,
      size.width - sideInset,
      wallBottom,
    );
    canvas.drawRect(backWall, Paint()..color = const Color(0xFFD7ECF0));

    final floor = Path()
      ..moveTo(0, wallBottom)
      ..lineTo(size.width, wallBottom)
      ..lineTo(size.width + 36, size.height)
      ..lineTo(-36, size.height)
      ..close();
    final floorPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFC8863F), Color(0xFFA9652A)],
      ).createShader(Rect.fromLTWH(0, wallBottom, size.width, size.height));
    canvas.drawPath(floor, floorPaint);

    final cornerPaint = Paint()
      ..color = const Color(0xFF6F9DA8).withValues(alpha: 0.32)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(sideInset, wallTop),
      Offset(sideInset, wallBottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - sideInset, wallTop),
      Offset(size.width - sideInset, wallBottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(sideInset, wallTop),
      Offset(size.width - sideInset, wallTop),
      cornerPaint,
    );

    final baseboardPaint = Paint()
      ..color = const Color(0xFF8B5A30)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(8, wallBottom - 3),
      Offset(size.width - 8, wallBottom - 3),
      baseboardPaint,
    );
    final baseboardHighlight = Paint()
      ..color = const Color(0xFFE7B672).withValues(alpha: 0.62)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(10, wallBottom - 8),
      Offset(size.width - 10, wallBottom - 8),
      baseboardHighlight,
    );

    final floorLinePaint = Paint()
      ..color = const Color(0xFF5B381F).withValues(alpha: 0.24)
      ..strokeWidth = 1.1;
    for (var i = 0; i < 7; i++) {
      final y = wallBottom + 34 + i * 42;
      canvas.drawLine(
        Offset(-24, y),
        Offset(size.width + 24, y + 4),
        floorLinePaint,
      );
    }
    for (final x in <double>[
      -size.width * 0.08,
      size.width * 0.16,
      size.width * 0.34,
      size.width * 0.50,
      size.width * 0.66,
      size.width * 0.84,
      size.width * 1.08,
    ]) {
      canvas.drawLine(
        Offset(x, size.height + 12),
        vanishingPoint,
        floorLinePaint,
      );
    }

    final framePaint = Paint()..color = const Color(0xFF3A2D35);
    final frameMatPaint = Paint()..color = const Color(0xFFFFE7B7);
    final leftFrame = Rect.fromLTWH(
      size.width * 0.16,
      size.height * 0.19,
      size.width * 0.065,
      size.height * 0.072,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(leftFrame, const Radius.circular(2)),
      framePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(leftFrame.deflate(4), const Radius.circular(1)),
      frameMatPaint,
    );
    canvas.drawOval(
      leftFrame.deflate(8),
      Paint()..color = const Color(0xFFAF8DD5),
    );

    final lowerFrame = leftFrame.translate(
      size.width * 0.045,
      size.height * 0.075,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lowerFrame, const Radius.circular(2)),
      framePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lowerFrame.deflate(4), const Radius.circular(1)),
      frameMatPaint,
    );
    canvas.drawOval(
      lowerFrame.deflate(8),
      Paint()..color = const Color(0xFF8FC6C4),
    );

    final wallShelfPaint = Paint()
      ..color = const Color(0xFF5E4A78)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.78, size.height * 0.20),
      Offset(size.width * 0.92, size.height * 0.20),
      wallShelfPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RoomPerspectivePainter oldDelegate) => false;
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
    final store = catudyDemoStore;
    final level = (store.focusPoints ~/ 120) + 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceFor(context).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CatudyColors.teal.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
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
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _CareStatTile(
                  icon: Icons.sentiment_satisfied_rounded,
                  label: store.t('pet.mood'),
                  value: mood,
                  color: CatudyColors.tealDark,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _CareStatTile(
                  icon: Icons.local_cafe_rounded,
                  label: store.t('home.hunger'),
                  value: 100 - hunger,
                  color: CatudyColors.violet,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _CareStatTile(
                  icon: Icons.bolt_rounded,
                  label: store.t('pet.energy'),
                  value: energy,
                  color: CatudyColors.yellow,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _CareStatTile(
                  icon: Icons.star_rounded,
                  label: store.t('pet.level'),
                  value: (level * 10).clamp(0, 100),
                  valueLabel: '$level',
                  color: CatudyColors.coral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _CareActionButton(
                  icon: Icons.cake_rounded,
                  label: store.t('pet.feed'),
                  color: CatudyColors.teal,
                  onTap: store.feedPet,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _CareActionButton(
                  icon: Icons.sports_esports_rounded,
                  label: store.t('pet.play'),
                  color: CatudyColors.violet,
                  onTap: store.playWithPet,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _CareActionButton(
                  icon: Icons.nightlight_round,
                  label: store.t('pet.sleep'),
                  color: CatudyColors.lavender,
                  onTap: store.restPet,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _CareActionButton(
                  icon: Icons.favorite_rounded,
                  label: store.t('pet.love'),
                  color: CatudyColors.coral,
                  onTap: store.petPet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CareStatTile extends StatelessWidget {
  const _CareStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.valueLabel,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final String? valueLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceStrongFor(context).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value.clamp(0, 100) / 100,
              minHeight: 6,
              color: color,
              backgroundColor: CatudyColors.surfaceFor(context),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            valueLabel ?? '${value.clamp(0, 100)}/100',
            style: TextStyle(
              color: CatudyColors.blueFor(context),
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _CareActionButton extends StatelessWidget {
  const _CareActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: CatudyColors.blueFor(context),
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomCustomizeStrip extends StatelessWidget {
  const _RoomCustomizeStrip({required this.onInventory, required this.onShop});

  final VoidCallback onInventory;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    final store = catudyDemoStore;
    final items = store.equippedRoomItems.toList();
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceFor(context).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: CatudyColors.violet.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onInventory,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 108,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: CatudyColors.violet.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.weekend_rounded,
                    color: CatudyColors.violet,
                    size: 19,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.t('pet.customizeTitle'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: CatudyColors.mutedFor(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          store.t('inventory.title'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: CatudyColors.blueFor(context),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: items.isEmpty
                ? OutlinedButton.icon(
                    onPressed: onShop,
                    icon: const Icon(Icons.storefront_rounded),
                    label: Text(store.t('pet.shop')),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return InkWell(
                        onTap: onInventory,
                        borderRadius: BorderRadius.circular(16),
                        child: CatudyAssetSlot(
                          size: 54,
                          accentColor: item.accent,
                          child: ShopItemArt(item: item, size: 44),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: onShop,
            icon: const Icon(Icons.storefront_rounded),
            tooltip: store.t('pet.shop'),
          ),
        ],
      ),
    );
  }
}

class _PerspectiveRug extends StatelessWidget {
  const _PerspectiveRug();

  @override
  Widget build(BuildContext context) {
    return const _RoomLayerAsset(
      path: 'assets/room/corner_round_rug_v1.png',
      width: double.infinity,
      height: double.infinity,
    );
  }
}

class _RugPainter extends CustomPainter {
  const _RugPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final shadowRect = Rect.fromLTWH(
      size.width * 0.10,
      size.height * 0.26,
      size.width * 0.80,
      size.height * 0.58,
    );
    canvas.drawOval(
      shadowRect.translate(0, size.height * 0.07),
      Paint()..color = Colors.black.withValues(alpha: 0.11),
    );
    canvas.drawOval(shadowRect, Paint()..color = accent);
    canvas.drawOval(
      shadowRect.deflate(size.width * 0.07),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: 0.34),
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.30,
        size.height * 0.40,
        size.width * 0.38,
        size.height * 0.22,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.22),
    );
  }

  @override
  bool shouldRepaint(covariant _RugPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

class _RoomWindow extends StatelessWidget {
  const _RoomWindow({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _RoomLayerAsset(
      path: 'assets/room/corner_window_v1.png',
      width: width,
      height: height,
    );
  }
}

class _RoomWindowPainter extends CustomPainter {
  const _RoomWindowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.04,
        size.height * 0.05,
        size.width * 0.92,
        size.height * 0.90,
      ),
      Radius.circular(size.width * 0.04),
    );
    canvas.drawRRect(
      shadow,
      Paint()..color = Colors.black.withValues(alpha: 0.10),
    );

    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.94),
      Radius.circular(size.width * 0.035),
    );
    canvas.drawRRect(frame, Paint()..color = const Color(0xFFD58A23));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        frame.outerRect.deflate(size.width * 0.07),
        Radius.circular(size.width * 0.015),
      ),
      Paint()..color = const Color(0xFF2B98E5),
    );

    final pane = frame.outerRect.deflate(size.width * 0.10);
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF58B9FF), Color(0xFF1784D4)],
      ).createShader(pane);
    canvas.drawRect(pane, skyPaint);

    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.86);
    void cloud(double x, double y, double scale) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * x, size.height * y),
          width: size.width * 0.22 * scale,
          height: size.height * 0.09 * scale,
        ),
        cloudPaint,
      );
      canvas.drawCircle(
        Offset(
          size.width * (x - 0.04 * scale),
          size.height * (y - 0.025 * scale),
        ),
        size.width * 0.045 * scale,
        cloudPaint,
      );
      canvas.drawCircle(
        Offset(
          size.width * (x + 0.045 * scale),
          size.height * (y - 0.03 * scale),
        ),
        size.width * 0.055 * scale,
        cloudPaint,
      );
    }

    cloud(0.37, 0.28, 1.00);
    cloud(0.66, 0.20, 0.82);

    final buildingPaint = Paint()..color = const Color(0xFF6F5A46);
    for (final rect in <Rect>[
      Rect.fromLTWH(
        size.width * 0.20,
        size.height * 0.61,
        size.width * 0.16,
        size.height * 0.23,
      ),
      Rect.fromLTWH(
        size.width * 0.37,
        size.height * 0.70,
        size.width * 0.13,
        size.height * 0.14,
      ),
      Rect.fromLTWH(
        size.width * 0.53,
        size.height * 0.58,
        size.width * 0.18,
        size.height * 0.26,
      ),
    ]) {
      canvas.drawRect(rect, buildingPaint);
    }
    final lightPaint = Paint()..color = const Color(0xFFFFF356);
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 5; col++) {
        canvas.drawRect(
          Rect.fromLTWH(
            size.width * (0.24 + col * 0.08),
            size.height * (0.66 + row * 0.06),
            size.width * 0.035,
            size.height * 0.026,
          ),
          lightPaint,
        );
      }
    }

    final muntinPaint = Paint()
      ..color = const Color(0xFF7A4A1F)
      ..strokeWidth = size.width * 0.035
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.50, size.height * 0.08),
      Offset(size.width * 0.50, size.height * 0.88),
      muntinPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.10, size.height * 0.49),
      Offset(size.width * 0.90, size.height * 0.49),
      muntinPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RoomWindowPainter oldDelegate) => false;
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
    required this.width,
    required this.height,
  });

  final ShopItem? item;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _RoomLayerAsset(
      path: item?.assetPath ?? 'assets/room/corner_study_desk_v1.png',
      width: width,
      height: height,
    );
  }
}

class _StudyDeskPainter extends CustomPainter {
  const _StudyDeskPainter({
    required this.accent,
    required this.upgraded,
    required this.studying,
  });

  final Color accent;
  final bool upgraded;
  final bool studying;

  @override
  void paint(Canvas canvas, Size size) {
    final wood = Color.lerp(
      const Color(0xFF8C4F2B),
      accent,
      upgraded ? 0.24 : 0.08,
    )!;
    final woodDark = Color.lerp(wood, Colors.black, 0.22)!;
    final woodLight = Color.lerp(wood, Colors.white, 0.16)!;
    final linePaint = Paint()
      ..color = const Color(0xFF3C2A22).withValues(alpha: 0.22)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.13,
        size.height * 0.75,
        size.width * 0.78,
        size.height * 0.18,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.13),
    );

    final legPaint = Paint()..color = woodDark;
    for (final leg in <Rect>[
      Rect.fromLTWH(
        size.width * 0.25,
        size.height * 0.58,
        size.width * 0.06,
        size.height * 0.28,
      ),
      Rect.fromLTWH(
        size.width * 0.76,
        size.height * 0.51,
        size.width * 0.06,
        size.height * 0.30,
      ),
      Rect.fromLTWH(
        size.width * 0.37,
        size.height * 0.67,
        size.width * 0.05,
        size.height * 0.22,
      ),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(leg, Radius.circular(size.width * 0.025)),
        legPaint,
      );
    }

    final top = Path()
      ..moveTo(size.width * 0.18, size.height * 0.42)
      ..lineTo(size.width * 0.76, size.height * 0.34)
      ..lineTo(size.width * 0.94, size.height * 0.48)
      ..lineTo(size.width * 0.34, size.height * 0.59)
      ..close();
    canvas.drawPath(top, Paint()..color = woodLight);
    canvas.drawPath(top, linePaint);

    final front = Path()
      ..moveTo(size.width * 0.34, size.height * 0.59)
      ..lineTo(size.width * 0.94, size.height * 0.48)
      ..lineTo(size.width * 0.88, size.height * 0.72)
      ..lineTo(size.width * 0.35, size.height * 0.84)
      ..close();
    canvas.drawPath(front, Paint()..color = wood);
    canvas.drawPath(front, linePaint);

    final side = Path()
      ..moveTo(size.width * 0.18, size.height * 0.42)
      ..lineTo(size.width * 0.34, size.height * 0.59)
      ..lineTo(size.width * 0.35, size.height * 0.84)
      ..lineTo(size.width * 0.20, size.height * 0.67)
      ..close();
    canvas.drawPath(side, Paint()..color = woodDark);
    canvas.drawPath(side, linePaint);

    final drawerPaint = Paint()
      ..color = Color.lerp(accent, Colors.white, 0.18)!;
    for (var index = 0; index < 2; index++) {
      final drawer = Rect.fromLTWH(
        size.width * 0.65,
        size.height * (0.54 + index * 0.10),
        size.width * 0.18,
        size.height * 0.072,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(drawer, Radius.circular(size.width * 0.015)),
        drawerPaint,
      );
      canvas.drawCircle(
        Offset(drawer.right - size.width * 0.035, drawer.center.dy),
        size.width * 0.009,
        Paint()..color = woodDark,
      );
    }

    final monitorFrame = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.48,
        size.height * 0.08,
        size.width * 0.30,
        size.height * 0.27,
      ),
      Radius.circular(size.width * 0.018),
    );
    canvas.drawRRect(monitorFrame, Paint()..color = const Color(0xFFFFE6BA));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        monitorFrame.outerRect.deflate(size.width * 0.025),
        Radius.circular(size.width * 0.010),
      ),
      Paint()..color = const Color(0xFF1C2130),
    );
    canvas.drawLine(
      Offset(size.width * 0.63, size.height * 0.35),
      Offset(size.width * 0.62, size.height * 0.43),
      Paint()
        ..color = const Color(0xFFFFE6BA)
        ..strokeWidth = size.width * 0.025
        ..strokeCap = StrokeCap.round,
    );

    final bookColors = [
      const Color(0xFF58B7B4),
      const Color(0xFFFFD86B),
      const Color(0xFF8E73C7),
    ];
    for (var index = 0; index < 3; index++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * (0.26 + index * 0.055),
            size.height * (0.34 - index * 0.015),
            size.width * 0.045,
            size.height * 0.14,
          ),
          Radius.circular(size.width * 0.010),
        ),
        Paint()..color = bookColors[index],
      );
    }

    final lampGlow = Paint()
      ..color = (studying ? CatudyColors.yellow : accent).withValues(
        alpha: studying ? 0.23 : 0.12,
      );
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.27),
      size.width * 0.16,
      lampGlow,
    );
    canvas.drawLine(
      Offset(size.width * 0.84, size.height * 0.30),
      Offset(size.width * 0.79, size.height * 0.45),
      Paint()
        ..color = woodDark
        ..strokeWidth = size.width * 0.018
        ..strokeCap = StrokeCap.round,
    );
    final shade = Path()
      ..moveTo(size.width * 0.78, size.height * 0.22)
      ..lineTo(size.width * 0.93, size.height * 0.20)
      ..lineTo(size.width * 0.88, size.height * 0.31)
      ..lineTo(size.width * 0.75, size.height * 0.32)
      ..close();
    canvas.drawPath(
      shade,
      Paint()
        ..color = studying
            ? CatudyColors.yellow
            : Color.lerp(accent, Colors.white, 0.22)!,
    );
  }

  @override
  bool shouldRepaint(covariant _StudyDeskPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.upgraded != upgraded ||
        oldDelegate.studying != studying;
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
    return _RoomLayerAsset(
      path: item?.assetPath ?? 'assets/room/corner_cat_bed_v1.png',
      width: width,
      height: height,
    );
  }
}

class _PetCushionPainter extends CustomPainter {
  const _PetCushionPainter({required this.accent, required this.upgraded});

  final Color accent;
  final bool upgraded;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.10,
        size.height * 0.56,
        size.width * 0.80,
        size.height * 0.30,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );
    final base = Rect.fromLTWH(
      size.width * 0.06,
      size.height * 0.26,
      size.width * 0.88,
      size.height * 0.48,
    );
    canvas.drawOval(
      base,
      Paint()..color = accent.withValues(alpha: upgraded ? 0.70 : 0.54),
    );
    canvas.drawOval(
      base.deflate(size.width * 0.08),
      Paint()
        ..color = Color.lerp(accent, Colors.white, upgraded ? 0.34 : 0.22)!,
    );
    canvas.drawArc(
      base.deflate(size.width * 0.15),
      3.24,
      2.82,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.38),
    );
  }

  @override
  bool shouldRepaint(covariant _PetCushionPainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.upgraded != upgraded;
  }
}

class _CozySofa extends StatelessWidget {
  const _CozySofa({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _RoomLayerAsset(
      path: 'assets/room/corner_cat_bed_v1.png',
      width: width,
      height: height,
    );
  }
}

class _RoomLamp extends StatelessWidget {
  const _RoomLamp({
    required this.item,
    required this.width,
    required this.height,
  });

  final ShopItem? item;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _RoomLayerAsset(
      path: item?.assetPath ?? 'assets/room/corner_right_shelf_lights_v1.png',
      width: width,
      height: height,
    );
  }
}

class _RightFacingSofaPainter extends CustomPainter {
  const _RightFacingSofaPainter({required this.accent, required this.upgraded});

  final Color accent;
  final bool upgraded;

  @override
  void paint(Canvas canvas, Size size) {
    final main = Color.lerp(accent, Colors.white, upgraded ? 0.08 : 0.16)!;
    final side = Color.lerp(accent, Colors.black, 0.14)!;
    final dark = Color.lerp(accent, Colors.black, 0.28)!;

    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.10,
        size.height * 0.78,
        size.width * 0.76,
        size.height * 0.16,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.10),
    );

    final back = RRect.fromRectAndCorners(
      Rect.fromLTWH(
        size.width * 0.05,
        size.height * 0.24,
        size.width * 0.46,
        size.height * 0.48,
      ),
      topLeft: Radius.circular(size.width * 0.16),
      bottomLeft: Radius.circular(size.width * 0.10),
      topRight: Radius.circular(size.width * 0.10),
      bottomRight: Radius.circular(size.width * 0.04),
    );
    canvas.drawRRect(back, Paint()..color = main);

    final seatTop = Path()
      ..moveTo(size.width * 0.18, size.height * 0.54)
      ..lineTo(size.width * 0.70, size.height * 0.48)
      ..lineTo(size.width * 0.92, size.height * 0.62)
      ..lineTo(size.width * 0.34, size.height * 0.76)
      ..close();
    canvas.drawPath(
      seatTop,
      Paint()..color = Color.lerp(main, Colors.white, 0.10)!,
    );

    final front = Path()
      ..moveTo(size.width * 0.34, size.height * 0.76)
      ..lineTo(size.width * 0.92, size.height * 0.62)
      ..lineTo(size.width * 0.86, size.height * 0.80)
      ..lineTo(size.width * 0.32, size.height * 0.92)
      ..close();
    canvas.drawPath(front, Paint()..color = side);

    final rightArm = RRect.fromRectAndCorners(
      Rect.fromLTWH(
        size.width * 0.70,
        size.height * 0.36,
        size.width * 0.24,
        size.height * 0.34,
      ),
      topLeft: Radius.circular(size.width * 0.08),
      topRight: Radius.circular(size.width * 0.14),
      bottomRight: Radius.circular(size.width * 0.08),
      bottomLeft: Radius.circular(size.width * 0.04),
    );
    canvas.drawRRect(
      rightArm,
      Paint()..color = Color.lerp(main, Colors.black, 0.08)!,
    );

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = dark.withValues(alpha: 0.42);
    canvas.drawRRect(back, outline);
    canvas.drawPath(seatTop, outline);
    canvas.drawRRect(rightArm, outline);

    final pillow = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.24,
        size.height * 0.48,
        size.width * 0.20,
        size.height * 0.19,
      ),
      Radius.circular(size.width * 0.045),
    );
    canvas.drawRRect(pillow, Paint()..color = const Color(0xFFFFC466));

    final legPaint = Paint()..color = dark;
    for (final point in <Offset>[
      Offset(size.width * 0.30, size.height * 0.86),
      Offset(size.width * 0.80, size.height * 0.76),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: point,
            width: size.width * 0.035,
            height: size.height * 0.12,
          ),
          Radius.circular(size.width * 0.02),
        ),
        legPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RightFacingSofaPainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.upgraded != upgraded;
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
    return _RoomLayerAsset(
      path: item?.assetPath ?? 'assets/room/corner_bookcase_v1.png',
      width: width,
      height: height,
    );
  }
}

class _BookshelfPainter extends CustomPainter {
  const _BookshelfPainter({required this.accent, required this.upgraded});

  final Color accent;
  final bool upgraded;

  @override
  void paint(Canvas canvas, Size size) {
    final frontColor = Color.lerp(
      const Color(0xFF3D817E),
      accent,
      upgraded ? 0.42 : 0.20,
    )!;
    final sideColor = Color.lerp(frontColor, Colors.black, 0.18)!;
    final trimColor = Color.lerp(frontColor, Colors.white, 0.18)!;

    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.88,
        size.width * 0.78,
        size.height * 0.10,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.10),
    );

    final side = Path()
      ..moveTo(size.width * 0.76, size.height * 0.12)
      ..lineTo(size.width * 0.90, size.height * 0.20)
      ..lineTo(size.width * 0.88, size.height * 0.88)
      ..lineTo(size.width * 0.74, size.height * 0.80)
      ..close();
    canvas.drawPath(side, Paint()..color = sideColor);

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.06,
        size.height * 0.08,
        size.width * 0.72,
        size.height * 0.76,
      ),
      Radius.circular(size.width * 0.12),
    );
    canvas.drawRRect(body, Paint()..color = frontColor);
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = trimColor.withValues(alpha: 0.48),
    );

    final shelfPaint = Paint()
      ..color = Color.lerp(frontColor, Colors.black, 0.24)!
      ..strokeWidth = size.height * 0.045
      ..strokeCap = StrokeCap.round;
    for (final y in <double>[0.31, 0.50, 0.69]) {
      canvas.drawLine(
        Offset(size.width * 0.13, size.height * y),
        Offset(size.width * 0.69, size.height * (y + 0.015)),
        shelfPaint,
      );
    }

    final bookColors = [
      const Color(0xFFFFA057),
      const Color(0xFFB38CE3),
      const Color(0xFFFFDD6E),
      const Color(0xFF70C9BF),
      const Color(0xFFEB6F66),
    ];
    var bookIndex = 0;
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 4; col++) {
        final bookHeight = size.height * (0.12 + ((row + col) % 2) * 0.035);
        final left = size.width * (0.15 + col * 0.12);
        final top =
            size.height * (0.18 + row * 0.19) +
            (size.height * 0.14 - bookHeight);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, size.width * 0.055, bookHeight),
            Radius.circular(size.width * 0.012),
          ),
          Paint()..color = bookColors[bookIndex % bookColors.length],
        );
        bookIndex++;
      }
    }

    canvas.drawCircle(
      Offset(size.width * 0.56, size.height * 0.17),
      size.width * 0.085,
      Paint()..color = const Color(0xFFFFCF62),
    );
  }

  @override
  bool shouldRepaint(covariant _BookshelfPainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.upgraded != upgraded;
  }
}

class _PetMeter extends StatelessWidget {
  const _PetMeter({
    required this.label,
    required this.value,
    required this.color,
    required this.info,
  });

  final String label;
  final int value;
  final Color color;
  final String info;

  @override
  Widget build(BuildContext context) {
    final displayValue = value;
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
