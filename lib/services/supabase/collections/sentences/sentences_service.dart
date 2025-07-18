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
    required String id
  }) async {
    try {
      final result = await supabase
          .from('sentences')
          .select()
          .eq('id', id);

      return (result as List).map((row) => Sentence.fromMap(row)).toList();
    } catch (e) {
      throw Exception('Error getting sentences by ID: $e');
    }
  }

  // ✅ Get sentences by collection ID using the linking table
  static Future<List<Sentence>> getSentencesByCollectionId({
    required String collectionId
  }) async {
    try {
      // Query the linking table to get sentence IDs for this collection
      final linkingResult = await supabase
          .from('collection_sentences')
          .select('sentence_id')
          .eq('collection_id', collectionId);

      if (linkingResult.isEmpty) {
        return []; // No sentences found for this collection
      }

      // Extract sentence IDs
      final sentenceIds = (linkingResult as List)
          .map((row) => row['sentence_id'] as String)
          .toList();

      // Query sentences table with the IDs
      final result = await supabase
          .from('sentences')
          .select()
          .inFilter('id', sentenceIds)
          .order('created_at', ascending: true);

      return (result as List).map((row) => Sentence.fromMap(row)).toList();
    } catch (e) {
      throw Exception('Error getting sentences for collection: $e');
    }
  }

  // ✅ Alternative: Get sentences by collection ID using JOIN (more efficient)
  static Future<List<Sentence>> getSentencesByCollectionIdWithJoin({
    required String collectionId
  }) async {
    try {
      final result = await supabase
          .from('collection_sentences')
          .select('''
            sentences!inner(*)
          ''')
          .eq('collection_id', collectionId)
          .order('sentences.created_at', ascending: true);

      return (result as List)
          .map((row) => Sentence.fromMap(row['sentences']))
          .toList();
    } catch (e) {
      throw Exception('Error getting sentences for collection with JOIN: $e');
    }
  }

  // ✅ Insert a single sentence and return its ID
  static Future<String> insertSentence({
    required Sentence sentence
  }) async {
    try {
      final sentenceResult = await supabase
          .from('sentences')
          .insert(sentence.toMap())
          .select()
          .single();

      return sentenceResult['id'] as String;
    } catch (e) {
      throw Exception('Error inserting sentence: $e');
    }
  }
}