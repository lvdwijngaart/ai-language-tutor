


import 'package:ai_lang_tutor_v2/models/database/sentence.dart';
import 'package:ai_lang_tutor_v2/services/supabase_client.dart';

class SentencesService {

  static Future<List<Sentence>> insertSentenceList({
    required List<Sentence> sentences
  }) async {
    if (sentences.isEmpty) {
      return [];
    }

    try {
      final sentenceMaps = sentences.map((sentence) => sentence.toMap()).toList();

      final sentenceResult = await supabase
          .from('sentences')
          .insert(sentenceMaps)
          .select();
      
      if (sentenceResult.isEmpty) {
        throw Exception('Failed to insert sentences - no results returned');
      }

      return sentenceResult.map((sentence) => Sentence.fromMap(sentence)).toList();
    } catch (e) {
      throw Exception('Error inserting sentences: $e');
    }
  }

  static Future<List<Sentence>> getSentencesById({
    required id
  }) async {
    final result = supabase
        .from('sentences')
        .select()
        .eq('id', id);

    return (result as List).map((row) => Sentence.fromMap(row)).toList();
  }

}