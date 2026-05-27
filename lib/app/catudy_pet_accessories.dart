import 'package:flutter/material.dart';

import 'theme/catudy_colors.dart';

class CatudyPetAccessoryVariant {
  const CatudyPetAccessoryVariant({
    required this.id,
    required this.label,
    required this.accent,
  });

  final String id;
  final String label;
  final Color accent;

  String get trimmedAssetPath =>
      'assets/cat_accessories/wearables/trimmed/$id.png';
}

class CatudyPetAccessory {
  const CatudyPetAccessory({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.rarity,
    required this.accent,
    required this.icon,
    this.variantGroupId,
    this.occupiedSlots = const <String>[],
    this.variants = const <CatudyPetAccessoryVariant>[],
  });

  const CatudyPetAccessory.hat({
    required String id,
    required String name,
    int price = 170,
    String rarity = 'common',
    Color accent = CatudyColors.violet,
    String? variantGroupId,
    List<String> occupiedSlots = const <String>['head'],
    List<CatudyPetAccessoryVariant> variants =
        const <CatudyPetAccessoryVariant>[],
  }) : this(
         id: id,
         name: name,
         description: 'A head accessory aligned for your Catudy pet.',
         price: price,
         rarity: rarity,
         accent: accent,
         icon: Icons.checkroom_rounded,
         variantGroupId: variantGroupId,
         occupiedSlots: occupiedSlots,
         variants: variants,
       );

  const CatudyPetAccessory.face({
    required String id,
    required String name,
    int price = 140,
    String rarity = 'common',
    Color accent = CatudyColors.coral,
    String? variantGroupId,
    List<String> occupiedSlots = const <String>['mouth'],
    List<CatudyPetAccessoryVariant> variants =
        const <CatudyPetAccessoryVariant>[],
  }) : this(
         id: id,
         name: name,
         description: 'A face accessory aligned for your Catudy pet.',
         price: price,
         rarity: rarity,
         accent: accent,
         icon: Icons.face_rounded,
         variantGroupId: variantGroupId,
         occupiedSlots: occupiedSlots,
         variants: variants,
       );

  const CatudyPetAccessory.glasses({
    required String id,
    required String name,
    int price = 160,
    String rarity = 'common',
    Color accent = CatudyColors.blue,
    String? variantGroupId,
    List<String> occupiedSlots = const <String>['eyes'],
    List<CatudyPetAccessoryVariant> variants =
        const <CatudyPetAccessoryVariant>[],
  }) : this(
         id: id,
         name: name,
         description: 'A glasses accessory aligned for your Catudy pet.',
         price: price,
         rarity: rarity,
         accent: accent,
         icon: Icons.visibility_rounded,
         variantGroupId: variantGroupId,
         occupiedSlots: occupiedSlots,
         variants: variants,
       );

  const CatudyPetAccessory.decor({
    required String id,
    required String name,
    int price = 150,
    String rarity = 'common',
    Color accent = CatudyColors.teal,
    String? variantGroupId,
    List<String> occupiedSlots = const <String>['head'],
    List<CatudyPetAccessoryVariant> variants =
        const <CatudyPetAccessoryVariant>[],
  }) : this(
         id: id,
         name: name,
         description: 'A playful accessory aligned for your Catudy pet.',
         price: price,
         rarity: rarity,
         accent: accent,
         icon: Icons.auto_awesome_rounded,
         variantGroupId: variantGroupId,
         occupiedSlots: occupiedSlots,
         variants: variants,
       );

  final String id;
  final String name;
  final String description;
  final int price;
  final String rarity;
  final Color accent;
  final IconData icon;
  final String? variantGroupId;
  final List<String> occupiedSlots;
  final List<CatudyPetAccessoryVariant> variants;

  bool get isShopVisible => variantGroupId == null;
  bool get hasVariants => variants.length > 1;

  String get trimmedAssetPath =>
      'assets/cat_accessories/wearables/trimmed/$id.png';

  String get alignedAssetPath =>
      'assets/cat_accessories/wearables/aligned/$id.png';
}

class CatudyPetAccessoryPlacement {
  const CatudyPetAccessoryPlacement({
    required this.targetAnchor,
    required this.targetWidth,
    this.sourceAnchor = const Offset(0.5, 0.5),
    this.scaleMultiplier = 1.0,
    this.useAlignedCanvas = false,
  });

  const CatudyPetAccessoryPlacement.canvas()
    : targetAnchor = Offset.zero,
      targetWidth = 0,
      sourceAnchor = Offset.zero,
      scaleMultiplier = 1,
      useAlignedCanvas = true;

  final Offset targetAnchor;
  final double targetWidth;
  final Offset sourceAnchor;
  final double scaleMultiplier;
  final bool useAlignedCanvas;
}

class CatudyPetAccessories {
  const CatudyPetAccessories._();

  static const all = <CatudyPetAccessory>[
    CatudyPetAccessory.hat(
      id: 'purple_witch_hat',
      name: 'Witch Hat',
      price: 220,
      rarity: 'rare',
      accent: CatudyColors.violet,
    ),
    CatudyPetAccessory.decor(
      id: 'pink_flower_clip',
      name: 'Flower',
      price: 130,
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.decor(
      id: 'gold_halo',
      name: 'Halo',
      price: 220,
      rarity: 'rare',
      accent: CatudyColors.yellow,
    ),
    CatudyPetAccessory.hat(
      id: 'silver_viking_helmet',
      name: 'Viking',
      price: 260,
      rarity: 'rare',
      accent: CatudyColors.yellow,
    ),
    CatudyPetAccessory.hat(
      id: 'blue_backwards_cap',
      name: 'Cap',
      price: 160,
      accent: CatudyColors.blue,
    ),
    CatudyPetAccessory.glasses(
      id: 'gold_monocle',
      name: 'Monocle',
      price: 170,
      accent: CatudyColors.yellow,
    ),
    CatudyPetAccessory.decor(
      id: 'green_bow_tie',
      name: 'Bow Tie',
      price: 140,
      accent: CatudyColors.teal,
      occupiedSlots: ['mouth'],
    ),
    CatudyPetAccessory.hat(
      id: 'black_top_hat',
      name: 'Top Hat',
      price: 210,
      rarity: 'rare',
      accent: CatudyColors.violetDark,
    ),
    CatudyPetAccessory.glasses(
      id: 'purple_eye_mask',
      name: 'Mask',
      price: 150,
      accent: CatudyColors.violet,
    ),
    CatudyPetAccessory.hat(
      id: 'pineapple_hat',
      name: 'Pineapple',
      price: 180,
      accent: CatudyColors.yellow,
    ),
    CatudyPetAccessory.glasses(
      id: 'black_sunglasses',
      name: 'Sunglasses',
      price: 150,
      accent: CatudyColors.violetDark,
      variants: [
        CatudyPetAccessoryVariant(
          id: 'black_sunglasses',
          label: 'Black',
          accent: CatudyColors.violetDark,
        ),
        CatudyPetAccessoryVariant(
          id: 'red_cat_eye_glasses',
          label: 'Red',
          accent: CatudyColors.coral,
        ),
        CatudyPetAccessoryVariant(
          id: 'green_shutter_glasses',
          label: 'Green',
          accent: CatudyColors.teal,
        ),
        CatudyPetAccessoryVariant(
          id: 'pixel_sunglasses',
          label: 'Pixel',
          accent: CatudyColors.blue,
        ),
        CatudyPetAccessoryVariant(
          id: 'red_shutter_glasses',
          label: 'Shutter',
          accent: CatudyColors.coral,
        ),
        CatudyPetAccessoryVariant(
          id: 'heart_sunglasses',
          label: 'Heart',
          accent: CatudyColors.coral,
        ),
        CatudyPetAccessoryVariant(
          id: 'yellow_star_sunglasses',
          label: 'Star',
          accent: CatudyColors.yellow,
        ),
        CatudyPetAccessoryVariant(
          id: 'pink_round_glasses',
          label: 'Pink',
          accent: CatudyColors.coral,
        ),
        CatudyPetAccessoryVariant(
          id: 'rainbow_ski_goggles',
          label: 'Rainbow',
          accent: CatudyColors.teal,
        ),
      ],
    ),
    CatudyPetAccessory.hat(
      id: 'yellow_sun_hat',
      name: 'Sun Hat',
      price: 200,
      rarity: 'rare',
      accent: CatudyColors.yellow,
    ),
    CatudyPetAccessory.hat(
      id: 'brown_aviator_cap',
      name: 'Aviator',
      price: 210,
      rarity: 'rare',
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.decor(
      id: 'pink_bow',
      name: 'Pink Bow',
      price: 130,
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.hat(
      id: 'detective_cap',
      name: 'Detective',
      price: 170,
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.glasses(
      id: 'red_cat_eye_glasses',
      name: 'Red',
      price: 160,
      accent: CatudyColors.coral,
      variantGroupId: 'black_sunglasses',
    ),
    CatudyPetAccessory.decor(
      id: 'gold_tiara',
      name: 'Tiara',
      price: 230,
      rarity: 'rare',
      accent: CatudyColors.yellow,
    ),
    CatudyPetAccessory.hat(
      id: 'blue_party_hat',
      name: 'Party Hat',
      price: 150,
      accent: CatudyColors.blue,
    ),
    CatudyPetAccessory.glasses(
      id: 'green_shutter_glasses',
      name: 'Green',
      price: 160,
      accent: CatudyColors.teal,
      variantGroupId: 'black_sunglasses',
    ),
    CatudyPetAccessory.hat(
      id: 'cowboy_hat',
      name: 'Cowboy Hat',
      price: 180,
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.hat(
      id: 'graduation_cap',
      name: 'Grad Cap',
      price: 220,
      rarity: 'rare',
      accent: CatudyColors.violetDark,
    ),
    CatudyPetAccessory.glasses(
      id: 'gold_monocle_chain',
      name: 'Chain',
      price: 180,
      accent: CatudyColors.yellow,
    ),
    CatudyPetAccessory.face(
      id: 'black_mustache',
      name: 'Mustache',
      price: 120,
      accent: CatudyColors.violetDark,
      variants: [
        CatudyPetAccessoryVariant(
          id: 'black_mustache',
          label: 'Black',
          accent: CatudyColors.violetDark,
        ),
        CatudyPetAccessoryVariant(
          id: 'brown_mustache',
          label: 'Brown',
          accent: CatudyColors.coral,
        ),
        CatudyPetAccessoryVariant(
          id: 'gray_mustache',
          label: 'Gray',
          accent: CatudyColors.muted,
        ),
      ],
    ),
    CatudyPetAccessory.face(
      id: 'brown_mustache',
      name: 'Brown',
      price: 120,
      accent: CatudyColors.coral,
      variantGroupId: 'black_mustache',
    ),
    CatudyPetAccessory.face(
      id: 'gray_mustache',
      name: 'Gray',
      price: 120,
      accent: CatudyColors.muted,
      variantGroupId: 'black_mustache',
    ),
    CatudyPetAccessory.face(
      id: 'white_beard',
      name: 'White',
      price: 150,
      accent: CatudyColors.lavender,
      variantGroupId: 'black_beard',
    ),
    CatudyPetAccessory.face(
      id: 'black_beard',
      name: 'Beard',
      price: 150,
      accent: CatudyColors.violetDark,
      variants: [
        CatudyPetAccessoryVariant(
          id: 'black_beard',
          label: 'Black',
          accent: CatudyColors.violetDark,
        ),
        CatudyPetAccessoryVariant(
          id: 'white_beard',
          label: 'White',
          accent: CatudyColors.lavender,
        ),
      ],
    ),
    CatudyPetAccessory.face(
      id: 'red_clown_nose',
      name: 'Red Nose',
      price: 100,
      accent: CatudyColors.coral,
      occupiedSlots: ['nose'],
    ),
    CatudyPetAccessory.glasses(
      id: 'groucho_glasses',
      name: 'Groucho',
      price: 170,
      accent: CatudyColors.coral,
      occupiedSlots: ['eyes', 'nose', 'mouth'],
    ),
    CatudyPetAccessory.glasses(
      id: 'pixel_sunglasses',
      name: 'Pixel',
      price: 150,
      accent: CatudyColors.blue,
      variantGroupId: 'black_sunglasses',
    ),
    CatudyPetAccessory.glasses(
      id: 'red_shutter_glasses',
      name: 'Shutter',
      price: 160,
      accent: CatudyColors.coral,
      variantGroupId: 'black_sunglasses',
    ),
    CatudyPetAccessory.glasses(
      id: 'heart_sunglasses',
      name: 'Heart',
      price: 170,
      accent: CatudyColors.coral,
      variantGroupId: 'black_sunglasses',
    ),
    CatudyPetAccessory.glasses(
      id: 'yellow_star_sunglasses',
      name: 'Star',
      price: 190,
      rarity: 'rare',
      accent: CatudyColors.yellow,
      variantGroupId: 'black_sunglasses',
    ),
    CatudyPetAccessory.glasses(
      id: 'pink_round_glasses',
      name: 'Pink',
      price: 160,
      accent: CatudyColors.coral,
      variantGroupId: 'black_sunglasses',
    ),
    CatudyPetAccessory.glasses(
      id: 'rainbow_ski_goggles',
      name: 'Rainbow',
      price: 220,
      rarity: 'rare',
      accent: CatudyColors.teal,
      variantGroupId: 'black_sunglasses',
    ),
    CatudyPetAccessory.decor(
      id: 'pink_tiara',
      name: 'Pink Tiara',
      price: 230,
      rarity: 'rare',
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.hat(
      id: 'fur_viking_helmet',
      name: 'Fur Viking',
      price: 240,
      rarity: 'rare',
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.hat(
      id: 'classic_top_hat',
      name: 'Classic Hat',
      price: 210,
      rarity: 'rare',
      accent: CatudyColors.violetDark,
    ),
    CatudyPetAccessory.decor(
      id: 'flower_crown',
      name: 'Crown',
      price: 190,
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.decor(
      id: 'hibiscus_flower',
      name: 'Hibiscus',
      price: 130,
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.decor(
      id: 'leaf_clips',
      name: 'Leaf Clips',
      price: 140,
      accent: CatudyColors.teal,
    ),
    CatudyPetAccessory.decor(
      id: 'thin_gold_halo',
      name: 'Thin Halo',
      price: 220,
      rarity: 'rare',
      accent: CatudyColors.yellow,
    ),
    CatudyPetAccessory.hat(
      id: 'rainbow_party_hat',
      name: 'Rainbow Hat',
      price: 170,
      accent: CatudyColors.coral,
    ),
  ];

  static List<CatudyPetAccessory> get shopCatalog =>
      all.where((accessory) => accessory.isShopVisible).toList();

  static CatudyPetAccessory? byId(String id) {
    for (final accessory in all) {
      if (accessory.id == id) {
        return accessory;
      }
    }
    return null;
  }

  static CatudyPetAccessory? parentForVariant(String id) {
    for (final accessory in all) {
      if (!accessory.isShopVisible) {
        continue;
      }
      if (accessory.id == id ||
          accessory.variants.any((variant) => variant.id == id)) {
        return accessory;
      }
    }
    return null;
  }

  static String? alignedAssetPathFor(String? id) =>
      id == null ? null : byId(id)?.alignedAssetPath;

  static String? trimmedAssetPathFor(String? id) =>
      id == null ? null : byId(id)?.trimmedAssetPath;

  static CatudyPetAccessoryPlacement? placementFor(String? id) =>
      id == null ? null : _placements[id];

  static const _placements = <String, CatudyPetAccessoryPlacement>{
    'purple_witch_hat': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 100),
      targetWidth: 333,
      sourceAnchor: Offset(0.5, 0.90),
    ),
    'pink_flower_clip': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(244, 68),
      targetWidth: 137,
    ),
    'gold_halo': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 30),
      targetWidth: 211,
      sourceAnchor: Offset(0.5, 0.82),
    ),
    'silver_viking_helmet': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 98),
      targetWidth: 312,
      sourceAnchor: Offset(0.5, 0.82),
    ),
    'blue_backwards_cap': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 104),
      targetWidth: 296,
      sourceAnchor: Offset(0.5, 0.80),
    ),
    'gold_monocle': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(104, 151),
      targetWidth: 127,
    ),
    'green_bow_tie': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 244),
      targetWidth: 180,
    ),
    'black_top_hat': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 102),
      targetWidth: 269,
      sourceAnchor: Offset(0.5, 0.88),
    ),
    'purple_eye_mask': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 154),
      targetWidth: 259,
    ),
    'pineapple_hat': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 102),
      targetWidth: 240,
      sourceAnchor: Offset(0.5, 0.92),
    ),
    'black_sunglasses': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 154),
      targetWidth: 253,
    ),
    'yellow_sun_hat': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 108),
      targetWidth: 351,
      sourceAnchor: Offset(0.5, 0.82),
    ),
    'brown_aviator_cap': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 172),
      targetWidth: 288,
      sourceAnchor: Offset(0.5, 0.94),
    ),
    'pink_bow': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(236, 70),
      targetWidth: 174,
    ),
    'detective_cap': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 108),
      targetWidth: 275,
      sourceAnchor: Offset(0.5, 0.86),
    ),
    'red_cat_eye_glasses': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 154),
      targetWidth: 248,
    ),
    'gold_tiara': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 100),
      targetWidth: 251,
      sourceAnchor: Offset(0.5, 0.86),
    ),
    'blue_party_hat': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 100),
      targetWidth: 169,
      sourceAnchor: Offset(0.5, 0.95),
    ),
    'green_shutter_glasses': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 154),
      targetWidth: 256,
    ),
    'cowboy_hat': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 104),
      targetWidth: 330,
      sourceAnchor: Offset(0.5, 0.86),
    ),
    'graduation_cap': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 96),
      targetWidth: 304,
      sourceAnchor: Offset(0.5, 0.82),
    ),
    'gold_monocle_chain': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(105, 151),
      targetWidth: 129,
    ),
    'black_mustache': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 178),
      targetWidth: 203,
      sourceAnchor: Offset(0.5, 0.45),
    ),
    'brown_mustache': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 178),
      targetWidth: 203,
      sourceAnchor: Offset(0.5, 0.45),
    ),
    'gray_mustache': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 178),
      targetWidth: 201,
      sourceAnchor: Offset(0.5, 0.45),
    ),
    'white_beard': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 198),
      targetWidth: 240,
      sourceAnchor: Offset(0.5, 0.18),
    ),
    'black_beard': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 200),
      targetWidth: 240,
      sourceAnchor: Offset(0.5, 0.18),
    ),
    'red_clown_nose': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 164),
      targetWidth: 74,
    ),
    'groucho_glasses': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 164),
      targetWidth: 253,
    ),
    'pixel_sunglasses': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 154),
      targetWidth: 259,
    ),
    'red_shutter_glasses': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 154),
      targetWidth: 259,
    ),
    'heart_sunglasses': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 154),
      targetWidth: 264,
    ),
    'yellow_star_sunglasses': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 154),
      targetWidth: 282,
    ),
    'pink_round_glasses': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 154),
      targetWidth: 238,
    ),
    'rainbow_ski_goggles': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 154),
      targetWidth: 275,
    ),
    'pink_tiara': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 100),
      targetWidth: 251,
      sourceAnchor: Offset(0.5, 0.86),
    ),
    'fur_viking_helmet': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 98),
      targetWidth: 312,
      sourceAnchor: Offset(0.5, 0.82),
    ),
    'classic_top_hat': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 102),
      targetWidth: 269,
      sourceAnchor: Offset(0.5, 0.88),
    ),
    'flower_crown': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 78),
      targetWidth: 327,
    ),
    'hibiscus_flower': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(242, 70),
      targetWidth: 137,
    ),
    'leaf_clips': CatudyPetAccessoryPlacement.canvas(),
    'thin_gold_halo': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 30),
      targetWidth: 211,
      sourceAnchor: Offset(0.5, 0.82),
    ),
    'rainbow_party_hat': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 100),
      targetWidth: 169,
      sourceAnchor: Offset(0.5, 0.95),
    ),
  };
}
