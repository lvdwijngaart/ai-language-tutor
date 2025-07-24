import 'package:ai_lang_tutor_v2/constants/icon_constants.dart';
import 'package:ai_lang_tutor_v2/models/database/profile.dart';
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/utils/date_time_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Collection {
  final String? id;
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

  // Optional field for profile, so creator user's info can be stored
  final Map<String, dynamic>? profile;

  Collection({
    this.id,
    required this.title,
    this.description,
    required this.language,
    required this.isPublic,
    this.nrOfSentences = 0,
    this.saves = 0,
    this.icon,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
    this.profile
  });

  factory Collection.fromMap(Map<String, dynamic> json) {
    try {
      final id = json['id'];
      if (id == null || id is! String || id.isEmpty) {
        throw ArgumentError('CollectionId must be non-null and a string. ');
      }

      DateTime? updatedAt;
      if (json['updated_at'] != null) {
        updatedAt = getDateTimeFromMapItem(json['updated_at']);
      }

      final profile = json['profiles'] is Map<String, dynamic> ? json['profiles'] : null;

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
        updatedAt: updatedAt,
        createdBy: json['created_by'],
        profile: profile,
      );
    } catch (e) {
      throw FormatException(
        'Failed to parse Collection from json: $e \nJSON: $json',
      );
    }
  }

  Map<String, dynamic> toMap() {
    final map = {
      'title': title,
      'description': description,
      'language': language.name,
      'is_public': isPublic,
      'nr_of_sentences': nrOfSentences,
      'saves': saves,
      'icon': iconToString(icon),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
    };
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }
}
