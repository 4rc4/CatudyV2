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
      id: 'green_army_helmet',
      name: 'Green Army Helmet',
      price: 190,
      accent: CatudyColors.tealDark,
    ),
    CatudyPetAccessory.hat(
      id: 'aviator_helmet',
      name: 'Aviator Helmet',
      price: 220,
      rarity: 'rare',
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.hat(
      id: 'astronaut_helmet',
      name: 'Astronaut Helmet',
      price: 280,
      rarity: 'rare',
      accent: CatudyColors.blue,
    ),
    CatudyPetAccessory.hat(
      id: 'pink_earmuffs',
      name: 'Pink Earmuffs',
      price: 170,
      accent: CatudyColors.coral,
    ),
    CatudyPetAccessory.hat(
      id: 'blue_headphones',
      name: 'Blue Headphones',
      price: 190,
      accent: CatudyColors.blue,
    ),
    CatudyPetAccessory.hat(
      id: 'chef_hat',
      name: 'Chef Hat',
      price: 180,
      accent: CatudyColors.lavender,
    ),
    CatudyPetAccessory.hat(
      id: 'star_wizard_hat',
      name: 'Star Wizard Hat',
      price: 240,
      rarity: 'rare',
      accent: CatudyColors.violet,
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
}
