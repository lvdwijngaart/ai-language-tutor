import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:flutter/material.dart';

const Map<String, IconData> iconNameMap = {
  'school': Icons.school, 
  'travel': Icons.flight_takeoff,   // Alternative: Icons.travel_explore
  'food': Icons.restaurant,
  'shopping': Icons.shopping_cart, 
  'business': Icons.work,
  'health': Icons.local_hospital, 
  'music': Icons.music_note, 
  'gaming': Icons.sports_esports, 
  'family': Icons.family_restroom, 
  'animals': Icons.pets, 
  'science': Icons.science, 
  'art': Icons.color_lens
};

IconData? iconFromString(String? name) {
  if (name == null) return null;
  return iconNameMap[name];
}

String? iconToString(IconData? icon) {
  if (icon == null) return null;
  return iconNameMap.entries
      .firstWhere(
        (entry) => entry.value == icon,
        orElse: () => MapEntry('', Icons.help),
      )
      .key;
}


class IconStyles {
  static Widget smallIconWithPadding({
    required IconData icon, 
    required Color backgroundColor, 
    required Color iconColor, 
    double size = 22, 
    double padding = 8,
  }) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: iconColor, size: size),
    );
  }
}