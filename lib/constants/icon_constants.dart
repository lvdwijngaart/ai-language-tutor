import 'package:flutter/material.dart';

const Map<String, IconData> iconNameMap = {
  'book': Icons.book,
  'star': Icons.star,
  'collections_bookmark': Icons.collections_bookmark,
  // Add more as needed
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