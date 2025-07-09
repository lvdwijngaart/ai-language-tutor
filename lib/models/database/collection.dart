import 'package:ai_lang_tutor_v2/models/database/profile.dart';
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/utils/date_time_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Collection {
  final String id;
  final String title;
  final String? description;
  final Language language;
  final bool isPublic;
  final int nrOfSentences;
  final int saves;
  final IconData? icon;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;

  Collection({
    required this.id,
    required this.title,
    this.description,
    required this.language,
    required this.isPublic,
    required this.nrOfSentences,
    required this.saves,
    this.icon,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
  });

  factory Collection.fromMap(Map<String, dynamic> json) {
    try {
      final id = json['id'];
      if (id == null || id is! String || id.isEmpty) {
        throw ArgumentError('CollectionId must be non-null and a string. ');
      }

      return Collection(
        id: id,
        title: json['title'],
        description: json['description'],
        language: LanguageParsing.fromString(json['language']),
        isPublic: json['is_public'],
        nrOfSentences: json['nr_of_sentences'],
        saves: json['saves'],
        icon: iconFromString(json['icon']),
        createdAt: getDateTimeFromMapItem(json['created_at']),
        updatedAt: getDateTimeFromMapItem(json['updated_at']),
        createdBy: json['created_by'],
      );
    } catch (e) {
      throw FormatException(
        'Failed to parse Collection from json: $e \nJSON: $json',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'language': language,
      'is_public': isPublic,
      'nr_of_sentences'
      'saves': saves,
      'icon': iconToString(icon),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
    };
  }
}

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
  // Reverse lookup
  return iconNameMap.entries
      .firstWhere(
        (entry) => entry.value == icon,
        orElse: () => MapEntry('', Icons.help),
      )
      .key;
}
