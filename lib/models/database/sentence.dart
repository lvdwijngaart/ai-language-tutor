

import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/utils/date_time_helper.dart';

class Sentence {

  final String? id;
  final String text;
  final String translation;
  final Language language;
  final int clozeStartChar;
  final int clozeEndChar;
  final DateTime createdAt;

  Sentence({
    this.id, 
    required this.text, 
    required this.translation, 
    required this.language, 
    required this.clozeStartChar, 
    required this.clozeEndChar, 
    required this.createdAt
  });

  factory Sentence.fromMap(Map<String, dynamic> json) {
    try {
      final sentenceId = json['id'];
      if (sentenceId == null || sentenceId is! String || sentenceId.isEmpty) {
        throw ArgumentError('Sentence ID must be non-null and a string. ');
      }

      return Sentence(
        id: sentenceId,
        text: json['text'],
        translation: json['translation'],
        language: LanguageParsing.fromString(json['language']),
        clozeStartChar: json['cloze_start_char'],
        clozeEndChar: json['cloze_end_char'],
        createdAt: getDateTimeFromMapItem(json['created_at'])
      );
    } catch (e) {
      throw FormatException('Failed to parse Sentence from JSON: $e \nJSON: $json');
    }
  }

  Map<String, dynamic> toMap() {
    final map = {
      'text': text, 
      'translation': translation, 
      'language': language.name, 
      'cloze_start_char': clozeStartChar, 
      'cloze_end_char': clozeEndChar, 
      'created_at': createdAt.toIso8601String()
    };
    if (id != null) {
      map['id'] = id!;
    }

    return map;
  }

}