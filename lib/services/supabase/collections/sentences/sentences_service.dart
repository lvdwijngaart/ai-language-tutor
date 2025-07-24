import 'package:ai_lang_tutor_v2/models/database/sentence.dart';
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/services/supabase_client.dart';
import 'package:ai_lang_tutor_v2/utils/logger.dart';

class SentencesService {

  static const String _table = 'sentences';
  static const String _linkingTable = 'collection_sentences';

  /// Get single sentence object by ID [id]
  static Future<Sentence?> getSentenceById({
    required String id
  }) async {
    try {
      final result = await supabase
          .from('sentences')
          .select()
          .eq('id', id)
          .maybeSingle();

      return result != null ? Sentence.fromMap(result) : null;
    } catch (e) {
      logger.e('Error getting sentence by ID: $e');
      throw Exception('Error getting sentence by ID: $e');
    }
  }

  /// Get multiple sentnces by IDs [ids]
  static Future<List<Sentence>> getSentencesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    try {
      final result = await supabase
          .from(_table)
          .select()
          .inFilter('id', ids)
          .order('created_at', ascending: true);

      return (result as List).map((row) => Sentence.fromMap(row)).toList();
    } catch (e) {
      logger.e('Error getting sentences by IDs: $e');
      throw Exception('Failed to get sentences: $e');
    }
  }


  /// Get sentences by collection ID using the linking table. 
  /// Get [limit] sentences for collection [collectionId]. 
  /// Offset the query using [offset]. 
  /// Result is ordered on sentence.created_at in the specified [ascending]
  static Future<List<Sentence>> getSentencesByCollectionId({
    required String collectionId, 
    int? limit, 
    int? offset, 
    bool ascending = true
  }) async {
    try {
      var query = supabase
          .from(_linkingTable)
          .select('''
            sentences(*)
          ''')
          .eq('collection_id', collectionId)
          .order('created_at', referencedTable: 'sentences', ascending: ascending);
      
      if (limit != null) {
        query.limit(limit);
      }

      if (offset != null) {
        query.range(offset, offset + (limit ?? 1000) -1);
      }
      
      final result = await query;

      return (result as List).map((row) => Sentence.fromMap(row['sentences'])).toList();
    } catch (e) {
      logger.e('Error getting sentences for collection $collectionId: $e');
      throw Exception('Failed to get sentences for collection: $e');
    }
  }

  /// Insert a single sentence 
  static Future<Sentence> insertSentence({
    required Sentence sentence
  }) async {
    try {
      final result = await supabase
          .from(_table)
          .insert(sentence.toMap())
          .select()
          .single();

      return Sentence.fromMap(result);
    } catch (e) {
      logger.e('Error inserting sentence: $e');
      throw Exception('Failed inserting sentence: $e');
    }
  }

  /// Inserting a list of [Sentence] objects into the database. 
  /// Objects are passed through the [sentences] parameter. 
  static Future<List<Sentence>> insertSentenceList({
    required List<Sentence> sentences
  }) async {
    if (sentences.isEmpty) {
      return [];
    }

    try {
      final sentenceMaps = sentences.map((sentence) => sentence.toMap()).toList();

      final sentenceResult = await supabase
          .from(_table)
          .insert(sentenceMaps)
          .select();

      return sentenceResult.map((sentence) => Sentence.fromMap(sentence)).toList();
    } catch (e) {
      logger.e('Error inserting ${sentences.length} sentences: $e');
      throw Exception('Failed inserting sentences: $e');
    }
  }

  /// Update sentence by [id] and update value-keys [updates]
  static Future<Sentence> updateSentence(String id, Map<String, dynamic> updates) async {
    try {
      final result = await supabase
          .from(_table)
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return Sentence.fromMap(result);
    } catch (e) {
      logger.e('Error updating sentence $id: $e');
      throw Exception('Failed to update sentence: $e');
    }
  }

  /// Delete sentence by [id]
  static Future<void> deleteSentence(String id) async {
    try {
      await supabase
          .from(_table)
          .delete()
          .eq('id', id);
    } catch (e) {
      logger.e('Error deleting sentence $id: $e');
      throw Exception('Failed deleting sentence: $e');
    }
  }

  static Future<List<Sentence>> searchSentences({
    required String searchTerm, 
    Language? language, 
    int limit = 50, 
    int offset = 0
  }) async {
    try {
      var query = supabase
          .from(_table)
          .select()
          .or('text.ilike.%$searchTerm%,translation.ilike.%$searchTerm%');

      if (language != null) {
        query = query.eq('language', language.name);
      }

      final result = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (result as List).map((row) => Sentence.fromMap(row)).toList();
    } catch (e) {
      logger.e('Error searching sentences with term "$searchTerm": $e');
      throw Exception('Failed to search sentences: $e');
    }
  }

  /// Get sentences containing specific word
  static Future<List<Sentence>> getSentencesContainingWord({
    required String word, 
    required Language language, 
    int limit = 50
  }) async {
    try {
      var query = supabase
          .from(_table)
          .select()
          .eq('language', language.name)
          .textSearch('text', word, config: language.dbConfig ?? 'simple')    // if language is not null, 
          .order('created_at', ascending: false)
          .limit(limit);

      final result = await query;

      return (result as List).map((row) => Sentence.fromMap(row)).toList();
    } catch (e) {
      logger.e('Error getting sentences containing word "$word": $e');
      // Fallback to LIKE search if full-text search fails
      return await _fallbackWordSearch(word: word, language: language, limit: limit);
    }
  }

  /// Fallback word search using LIKE
  static Future<List<Sentence>> _fallbackWordSearch({
    required String word, 
    required Language language, 
    int limit = 50
  }) async {
    try {
      var query = supabase
          .from(_table)
          .select()
          .like('text', '%$word%')
          .eq('language', language.name)
          .order('created_at', ascending: false)
          .limit(limit);

      final result = await query;

      return (result as List).map((row) => Sentence.fromMap(row)).toList();
    } catch (e) {
      logger.e('Error in fallback word search for word "$word": $e');
      throw Exception('Failed to search for sentences containing word: $e');
    }
  }

  /// Get random sentences for a language. Returns [limit] objects
  static Future<List<Sentence>> getRandomSentences({
    required Language language, 
    int limit = 10
  }) async {
    try {
      var query = supabase
          .rpc('get_random_sentences', params: {'sentence_limit': limit})
          .eq('language', language.name);

      final result = await query;

      return (result as List).map((row) => Sentence.fromMap(row)).toList();
    } catch (e) {
      logger.e('Error getting random sentences: $e');
      return await _getFallbackSentences(language: language, limit: limit);
    }
  }

  /// Fallback for [getRandomSentences]. Returns [limit] objects
  static Future<List<Sentence>> _getFallbackSentences({
    required Language language, 
    int limit = 10
  }) async {
    try {
      var query = supabase
          .from(_table)
          .select()
          .eq('language', language.name)
          .order('created_at', ascending: false)
          .limit(limit);

      final result = await query;

      return (result as List).map((row) => Sentence.fromMap(row)).toList();
    } catch (e) {
      logger.e('Error in fallback sentence fetch: $e');
      throw Exception('Failed to get sentences: $e');
    }
  }

  /// Check if sentence [id] exists
  static Future<bool> sentenceExists(String id) async {
    try {
      final result = await supabase
          .from(_table)
          .select('id')
          .eq('id', id)
          .maybeSingle();

      return result != null;
    } catch (e) {
      logger.e('Error checking if sentence exists: $e');
      return false;   // Pretend it does not exist
    }
  }

}