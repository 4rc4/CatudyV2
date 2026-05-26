import 'package:flutter/material.dart';

import 'theme/catudy_colors.dart';

class CatudyPetAccessory {
  const CatudyPetAccessory({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.rarity,
    required this.accent,
    required this.icon,
  });

  const CatudyPetAccessory.hat({
    required String id,
    required String name,
    int price = 170,
    String rarity = 'common',
    Color accent = CatudyColors.violet,
  }) : this(
         id: id,
         name: name,
         description: 'A head accessory aligned for your Catudy pet.',
         price: price,
         rarity: rarity,
         accent: accent,
         icon: Icons.checkroom_rounded,
       );

  const CatudyPetAccessory.face({
    required String id,
    required String name,
    int price = 140,
    String rarity = 'common',
    Color accent = CatudyColors.coral,
  }) : this(
         id: id,
         name: name,
         description: 'A face accessory aligned for your Catudy pet.',
         price: price,
         rarity: rarity,
         accent: accent,
         icon: Icons.face_rounded,
       );

  const CatudyPetAccessory.glasses({
    required String id,
    required String name,
    int price = 160,
    String rarity = 'common',
    Color accent = CatudyColors.blue,
  }) : this(
         id: id,
         name: name,
         description: 'A glasses accessory aligned for your Catudy pet.',
         price: price,
         rarity: rarity,
         accent: accent,
         icon: Icons.visibility_rounded,
       );

  const CatudyPetAccessory.decor({
    required String id,
    required String name,
    int price = 150,
    String rarity = 'common',
    Color accent = CatudyColors.teal,
  }) : this(
         id: id,
         name: name,
         description: 'A playful accessory aligned for your Catudy pet.',
         price: price,
         rarity: rarity,
         accent: accent,
         icon: Icons.auto_awesome_rounded,
       );

  final String id;
  final String name;
  final String description;
  final int price;
  final String rarity;
  final Color accent;
  final IconData icon;

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
      name: 'Purple Witch Hat',
      price: 220,
      rarity: 'rare',
      accent: CatudyColors.violet,
    ),
    CatudyPetAccessory.decor(
      id: 'pink_flower_clip',
      name: 'Pink Flower Clip',
      price: 130,
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.decor(
      id: 'gold_halo',
      name: 'Gold Halo',
      price: 220,
      rarity: 'rare',
      accent: CatudyColors.yellow,
    ),
    CatudyPetAccessory.hat(
      id: 'silver_viking_helmet',
      name: 'Silver Viking Helmet',
      price: 260,
      rarity: 'rare',
      accent: CatudyColors.yellow,
    ),
    CatudyPetAccessory.hat(
      id: 'blue_backwards_cap',
      name: 'Blue Backwards Cap',
      price: 160,
      accent: CatudyColors.blue,
    ),
    CatudyPetAccessory.glasses(
      id: 'gold_monocle',
      name: 'Gold Monocle',
      price: 170,
      accent: CatudyColors.yellow,
    ),
    CatudyPetAccessory.decor(
      id: 'green_bow_tie',
      name: 'Green Bow Tie',
      price: 140,
      accent: CatudyColors.teal,
    ),
    CatudyPetAccessory.hat(
      id: 'black_top_hat',
      name: 'Black Top Hat',
      price: 210,
      rarity: 'rare',
      accent: CatudyColors.violetDark,
    ),
    CatudyPetAccessory.glasses(
      id: 'purple_eye_mask',
      name: 'Purple Eye Mask',
      price: 150,
      accent: CatudyColors.violet,
    ),
    CatudyPetAccessory.hat(
      id: 'pineapple_hat',
      name: 'Pineapple Hat',
      price: 180,
      accent: CatudyColors.yellow,
    ),
    CatudyPetAccessory.glasses(
      id: 'black_sunglasses',
      name: 'Black Sunglasses',
      price: 150,
      accent: CatudyColors.violetDark,
    ),
    CatudyPetAccessory.hat(
      id: 'yellow_sun_hat',
      name: 'Yellow Sun Hat',
      price: 200,
      rarity: 'rare',
      accent: CatudyColors.yellow,
    ),
    CatudyPetAccessory.hat(
      id: 'red_white_headband',
      name: 'Red White Headband',
      price: 140,
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.hat(
      id: 'brown_aviator_cap',
      name: 'Brown Aviator Cap',
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
      name: 'Detective Cap',
      price: 170,
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.glasses(
      id: 'red_cat_eye_glasses',
      name: 'Red Cat Eye Glasses',
      price: 160,
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.hat(
      id: 'sailor_hat',
      name: 'Sailor Hat',
      price: 210,
      rarity: 'rare',
      accent: CatudyColors.blue,
    ),
    CatudyPetAccessory.decor(
      id: 'gold_tiara',
      name: 'Gold Tiara',
      price: 230,
      rarity: 'rare',
      accent: CatudyColors.yellow,
    ),
    CatudyPetAccessory.hat(
      id: 'blue_party_hat',
      name: 'Blue Party Hat',
      price: 150,
      accent: CatudyColors.blue,
    ),
    CatudyPetAccessory.hat(
      id: 'black_ninja_headband',
      name: 'Black Ninja Headband',
      price: 150,
      accent: CatudyColors.violetDark,
    ),
    CatudyPetAccessory.glasses(
      id: 'green_shutter_glasses',
      name: 'Green Shutter Glasses',
      price: 160,
      accent: CatudyColors.teal,
    ),
    CatudyPetAccessory.hat(
      id: 'cowboy_hat',
      name: 'Cowboy Hat',
      price: 180,
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.hat(
      id: 'graduation_cap',
      name: 'Graduation Cap',
      price: 220,
      rarity: 'rare',
      accent: CatudyColors.violetDark,
    ),
    CatudyPetAccessory.glasses(
      id: 'gold_monocle_chain',
      name: 'Gold Monocle Chain',
      price: 180,
      accent: CatudyColors.yellow,
    ),
    CatudyPetAccessory.face(
      id: 'black_mustache',
      name: 'Black Mustache',
      price: 120,
      accent: CatudyColors.violetDark,
    ),
    CatudyPetAccessory.face(
      id: 'brown_mustache',
      name: 'Brown Mustache',
      price: 120,
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.face(
      id: 'gray_mustache',
      name: 'Gray Mustache',
      price: 120,
      accent: CatudyColors.muted,
    ),
    CatudyPetAccessory.face(
      id: 'white_beard',
      name: 'White Beard',
      price: 150,
      accent: CatudyColors.lavender,
    ),
    CatudyPetAccessory.face(
      id: 'black_beard',
      name: 'Black Beard',
      price: 150,
      accent: CatudyColors.violetDark,
    ),
    CatudyPetAccessory.face(
      id: 'red_clown_nose',
      name: 'Red Nose',
      price: 100,
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.glasses(
      id: 'groucho_glasses',
      name: 'Groucho Glasses',
      price: 170,
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.glasses(
      id: 'pixel_sunglasses',
      name: 'Pixel Sunglasses',
      price: 150,
      accent: CatudyColors.blue,
    ),
    CatudyPetAccessory.glasses(
      id: 'red_shutter_glasses',
      name: 'Red Shutter Glasses',
      price: 160,
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.glasses(
      id: 'heart_sunglasses',
      name: 'Heart Sunglasses',
      price: 170,
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.glasses(
      id: 'yellow_star_sunglasses',
      name: 'Star Sunglasses',
      price: 190,
      rarity: 'rare',
      accent: CatudyColors.yellow,
    ),
    CatudyPetAccessory.glasses(
      id: 'pink_round_glasses',
      name: 'Pink Round Glasses',
      price: 160,
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.glasses(
      id: 'rainbow_ski_goggles',
      name: 'Rainbow Ski Goggles',
      price: 220,
      rarity: 'rare',
      accent: CatudyColors.teal,
    ),
    CatudyPetAccessory.decor(
      id: 'pink_tiara',
      name: 'Pink Tiara',
      price: 230,
      rarity: 'rare',
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.hat(
      id: 'knight_helmet',
      name: 'Knight Helmet',
      price: 260,
      rarity: 'rare',
      accent: CatudyColors.muted,
    ),
    CatudyPetAccessory.hat(
      id: 'fur_viking_helmet',
      name: 'Fur Viking Helmet',
      price: 240,
      rarity: 'rare',
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.hat(
      id: 'classic_top_hat',
      name: 'Classic Top Hat',
      price: 210,
      rarity: 'rare',
      accent: CatudyColors.violetDark,
    ),
    CatudyPetAccessory.decor(
      id: 'flower_crown',
      name: 'Flower Crown',
      price: 190,
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.decor(
      id: 'hibiscus_flower',
      name: 'Hibiscus Flower',
      price: 130,
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.decor(
      id: 'left_leaf_clip',
      name: 'Left Leaf Clip',
      price: 120,
      accent: CatudyColors.teal,
    ),
    CatudyPetAccessory.decor(
      id: 'right_leaf_clip',
      name: 'Right Leaf Clip',
      price: 120,
      accent: CatudyColors.teal,
    ),
    CatudyPetAccessory.decor(
      id: 'thin_gold_halo',
      name: 'Thin Gold Halo',
      price: 220,
      rarity: 'rare',
      accent: CatudyColors.yellow,
    ),
    CatudyPetAccessory.hat(
      id: 'rainbow_party_hat',
      name: 'Rainbow Party Hat',
      price: 170,
      accent: CatudyColors.coral,
    ),
  ];

  static CatudyPetAccessory? byId(String id) {
    for (final accessory in all) {
      if (accessory.id == id) {
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
    'red_white_headband': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 76),
      targetWidth: 256,
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
    'sailor_hat': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 194),
      targetWidth: 282,
      sourceAnchor: Offset(0.5, 0.58),
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
    'black_ninja_headband': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 152),
      targetWidth: 280,
      sourceAnchor: Offset(0.5, 0.50),
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
    'knight_helmet': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(155, 192),
      targetWidth: 296,
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
    'left_leaf_clip': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(108, 84),
      targetWidth: 114,
    ),
    'right_leaf_clip': CatudyPetAccessoryPlacement(
      targetAnchor: Offset(218, 84),
      targetWidth: 114,
    ),
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
