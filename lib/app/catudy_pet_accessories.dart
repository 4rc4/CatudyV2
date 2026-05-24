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
    CatudyPetAccessory(
      id: 'propeller_cap',
      name: 'Propeller Cap',
      description: 'A playful cap with a tiny spinning propeller.',
      price: 140,
      rarity: 'common',
      accent: CatudyColors.teal,
      icon: Icons.toys_rounded,
    ),
    CatudyPetAccessory(
      id: 'gold_crown',
      name: 'Gold Crown',
      description: 'A shiny crown for a focused little monarch.',
      price: 240,
      rarity: 'rare',
      accent: CatudyColors.yellow,
      icon: Icons.workspace_premium_rounded,
    ),
    CatudyPetAccessory(
      id: 'cowboy_hat',
      name: 'Cowboy Hat',
      description: 'A rounded western hat for study adventures.',
      price: 180,
      rarity: 'common',
      accent: CatudyColors.coral,
      icon: Icons.explore_rounded,
    ),
    CatudyPetAccessory(
      id: 'dinosaur_hood',
      name: 'Dinosaur Hood',
      description: 'A soft dinosaur hood with little spikes.',
      price: 260,
      rarity: 'rare',
      accent: CatudyColors.teal,
      icon: Icons.egg_rounded,
    ),
    CatudyPetAccessory(
      id: 'backwards_blue_cap',
      name: 'Backwards Blue Cap',
      description: 'A relaxed blue cap worn backwards.',
      price: 160,
      rarity: 'common',
      accent: CatudyColors.blue,
      icon: Icons.sports_baseball_rounded,
    ),
    CatudyPetAccessory(
      id: 'pixel_sunglasses',
      name: 'Pixel Sunglasses',
      description: 'Blocky sunglasses for maximum focus energy.',
      price: 150,
      rarity: 'common',
      accent: CatudyColors.blue,
      icon: Icons.grid_view_rounded,
    ),
    CatudyPetAccessory(
      id: 'heart_sunglasses',
      name: 'Heart Sunglasses',
      description: 'Heart-shaped shades for soft study days.',
      price: 170,
      rarity: 'common',
      accent: CatudyColors.coral,
      icon: Icons.favorite_rounded,
    ),
    CatudyPetAccessory(
      id: 'round_glasses',
      name: 'Round Glasses',
      description: 'Round glasses with mismatched lens sparkle.',
      price: 190,
      rarity: 'rare',
      accent: CatudyColors.teal,
      icon: Icons.visibility_rounded,
    ),
    CatudyPetAccessory(
      id: 'black_aviator_sunglasses',
      name: 'Black Aviators',
      description: 'A sleek dark aviator pair.',
      price: 180,
      rarity: 'common',
      accent: CatudyColors.blue,
      icon: Icons.dark_mode_rounded,
    ),
    CatudyPetAccessory(
      id: 'yellow_star_sunglasses',
      name: 'Star Sunglasses',
      description: 'Bright star frames for celebration mode.',
      price: 230,
      rarity: 'rare',
      accent: CatudyColors.yellow,
      icon: Icons.star_rounded,
    ),
    CatudyPetAccessory(
      id: 'red_headband_side_tie',
      name: 'Side-Tie Headband',
      description: 'A red headband tied to the side.',
      price: 150,
      rarity: 'common',
      accent: CatudyColors.coral,
      icon: Icons.sports_martial_arts_rounded,
    ),
    CatudyPetAccessory(
      id: 'black_eye_mask',
      name: 'Black Eye Mask',
      description: 'A simple dark mask across the eyes.',
      price: 170,
      rarity: 'common',
      accent: CatudyColors.violet,
      icon: Icons.visibility_off_rounded,
    ),
    CatudyPetAccessory(
      id: 'red_headband_x',
      name: 'Red X Headband',
      description: 'A red headband with a tiny stitched X.',
      price: 160,
      rarity: 'common',
      accent: CatudyColors.coral,
      icon: Icons.close_rounded,
    ),
    CatudyPetAccessory(
      id: 'black_mustache',
      name: 'Black Mustache',
      description: 'A curled dark mustache for dramatic breaks.',
      price: 130,
      rarity: 'common',
      accent: CatudyColors.violet,
      icon: Icons.face_rounded,
    ),
    CatudyPetAccessory(
      id: 'green_sleep_mask',
      name: 'Green Sleep Mask',
      description: 'A cozy green sleep mask for rest mode.',
      price: 170,
      rarity: 'common',
      accent: CatudyColors.teal,
      icon: Icons.bedtime_rounded,
    ),
    CatudyPetAccessory(
      id: 'garlic_hat',
      name: 'Garlic Hat',
      description: 'A soft garlic hat with pale purple shading.',
      price: 160,
      rarity: 'common',
      accent: CatudyColors.lavender,
      icon: Icons.spa_rounded,
    ),
    CatudyPetAccessory(
      id: 'banana_hat',
      name: 'Banana Hat',
      description: 'A peeled banana hat for silly focus sessions.',
      price: 160,
      rarity: 'common',
      accent: CatudyColors.yellow,
      icon: Icons.eco_rounded,
    ),
    CatudyPetAccessory(
      id: 'apple_hat',
      name: 'Apple Hat',
      description: 'A red apple hat with a tiny leaf.',
      price: 170,
      rarity: 'common',
      accent: CatudyColors.coral,
      icon: Icons.local_florist_rounded,
    ),
    CatudyPetAccessory(
      id: 'brown_mustache',
      name: 'Brown Mustache',
      description: 'A warm brown curled mustache.',
      price: 130,
      rarity: 'common',
      accent: CatudyColors.coral,
      icon: Icons.face_rounded,
    ),
    CatudyPetAccessory(
      id: 'chick_hat',
      name: 'Chick Hat',
      description: 'A small yellow chick perched on the head.',
      price: 210,
      rarity: 'rare',
      accent: CatudyColors.yellow,
      icon: Icons.flutter_dash_rounded,
    ),
    CatudyPetAccessory(
      id: 'headphones',
      name: 'Headphones',
      description: 'Big headphones for deep focus.',
      price: 220,
      rarity: 'rare',
      accent: CatudyColors.tealDark,
      icon: Icons.headphones_rounded,
    ),
    CatudyPetAccessory(
      id: 'pink_bow',
      name: 'Pink Bow',
      description: 'A bright pink bow for the ear.',
      price: 150,
      rarity: 'common',
      accent: CatudyColors.coral,
      icon: Icons.celebration_rounded,
    ),
    CatudyPetAccessory(
      id: 'party_hat',
      name: 'Party Hat',
      description: 'A striped party hat with a red pom.',
      price: 180,
      rarity: 'common',
      accent: CatudyColors.coral,
      icon: Icons.celebration_rounded,
    ),
    CatudyPetAccessory(
      id: 'top_hat',
      name: 'Top Hat',
      description: 'A tall black top hat with a red band.',
      price: 240,
      rarity: 'rare',
      accent: CatudyColors.violet,
      icon: Icons.theater_comedy_rounded,
    ),
    CatudyPetAccessory(
      id: 'blue_bucket_hat',
      name: 'Blue Bucket Hat',
      description: 'A soft blue bucket hat.',
      price: 170,
      rarity: 'common',
      accent: CatudyColors.blue,
      icon: Icons.beach_access_rounded,
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
