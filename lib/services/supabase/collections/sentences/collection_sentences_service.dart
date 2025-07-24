import 'package:ai_lang_tutor_v2/services/supabase_client.dart';
import 'package:ai_lang_tutor_v2/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CollectionSentencesService {

  static const String _table = 'collection_sentences';

  /// Add multiple sentences to a collection. Sentences by id [sentenceIds] are added to collection [collectionId]
  static Future<bool> addMultSentencesToCollection({
    required List<String> sentenceIds,
    required String collectionId,
  }) async {
    if (sentenceIds.isEmpty) {
      logger.w('Attempted to add empty sentence list to collection $collectionId');
      return true;    // Not an error, just nothing to do
    }
      
    try {
      final List<Map<String, dynamic>> insertList = sentenceIds.map((sentenceId) => {
          'collection_id': collectionId,
          'sentence_id': sentenceId,
        }).toList();

      final addResult = await supabase
          .from(_table)
          .insert(insertList)
          .select();

      if (addResult.length != sentenceIds.length) {
        throw Exception('Not all sentences were added successfully. Expected : ${sentenceIds.length}, added: ${addResult.length}');
      }

      await _incrementCollectionSentenceCount(collectionId, sentenceIds.length);
  
      logger.i('Successfully added ${sentenceIds.length} sentences to collection $collectionId');
      return true;
    } catch (e) {
      logger.e('Error adding ${sentenceIds.length} sentences to collection $collectionId: $e');
      throw Exception('Failed to add sentences to collection: $e');
    }
  }

  /// Add a single sentence to a collection
  static Future<bool> addSentenceToCollection({
    required String sentenceId,
    required String collectionId,
  }) async {
    try {
      // Check if relationship already exists
      final exists = await _relationshipExists(sentenceId, collectionId);
      if (exists) {
        logger.w('Sentence $sentenceId already exists in collection $collectionId');
        return true; // Not an error, already exists
      }
      
      final result = await supabase
          .from(_table)
          .insert({
            'collection_id': collectionId,
            'sentence_id': sentenceId,
          })
          .select()
          .single();


      // Add 1 to Collection.nrOfSentences
      await _incrementCollectionSentenceCount(collectionId, 1);

      logger.i('Successfully added sentence $sentenceId to collection $collectionId');
      return true;
    } catch (e) {
      logger.e('Error adding sentence $sentenceId to collection $collectionId: $e');
      throw Exception('Failed to add sentence to collection: $e');
    }
  }

  /// Remove a sentence from a collection
  static Future<bool> removeSentenceFromCollection({
    required String sentenceId, 
    required String collectionId
  }) async {
    try {
      final result = await supabase
          .from(_table)
          .delete()
          .eq('sentence_id', sentenceId)
          .eq('collection_id', collectionId)
          .select();

      // Check if any rows were actually deleted
      if ((result as List).isEmpty) {
        logger.w('No relationship found between sentence $sentenceId and collection $collectionId');
        return false; // Return false if nothing was deleted
      }

      await _decrementCollectionSentenceCount(collectionId, 1);

      logger.i('Successfully removed sentence $sentenceId from collection $collectionId');
      return true;
    } catch (e) {
      logger.e('Error removing sentence $sentenceId from collection $collectionId: $e');
      throw Exception('Failed to remove sentence from collection: $e');
    }
  }

  /// Remove multiple sentences from a collection
  // TODO

  /// Check if a sentence is already in a collection
  static Future<bool> isSentenceInCollection({
    required String sentenceId, 
    required String collectionId
  }) async {
    try {
      return await _relationshipExists(sentenceId, collectionId);
    } catch (e) {
      logger.e('Error checking if sentence $sentenceId is in collection $collectionId');
      return false;     // Assume is not in collection on error
    }
  }

  /// Get collection IDs that contain a specific sentence
  /// TODO
  
  /// Get number of sentences saved in collection [collectionId]
  static Future<int> getSentenceCountForCollection(String collectionId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('collection_id', collectionId);

      return response.length;
    } catch (e) {
      logger.e('Error getting sentence count for collection $collectionId: $e');
      throw Exception('Failed to get sentence count for collection: $e');
    }
  }
  
  /// Remove all sentences saved to collection [collectionId]
  static Future<bool> clearCollection(String collectionId) async {
    try {
      final currentCount = await getSentenceCountForCollection(collectionId);

      if (currentCount == 0) {
        logger.i('Collection $collectionId is already empty');
        return true;
      }

      // Delete all relationships
      await supabase
          .from(_table)
          .delete()
          .eq('collection_id', collectionId);

      // Reset collection sentence count to 0
      await _setCollectionSentenceCount(collectionId, 0);

      logger.i('Successfully cleared $currentCount sentences from collection $collectionId');
      return true;
    } catch (e) {
      logger.e('Error clearing collection $collectionId: $e');
      throw Exception('Failed to clear collection: $e');
    }
  }

  // PRIVATE HELPER METHODS: 

  static Future<bool> _relationshipExists(String sentenceId, String collectionId) async {
    final result = await supabase
        .from(_table)
        .select()
        .eq('sentence_id', sentenceId)
        .eq('collection_id', collectionId)
        .maybeSingle();

    return result != null;
  }

  static Future<void> _incrementCollectionSentenceCount(String collectionId, int count) async {
    try {
      await supabase.rpc(
        'increment_collection_sentence_count',
        params: {
          'collection_id': collectionId, 
          'count': count
        },
      );
    } catch (e) {
      logger.e('Error incrementing sentence count for collection $collectionId: $e');
    }
  }

  static Future<void> _decrementCollectionSentenceCount(String collectionId, int count) async {
    try {
      await supabase.rpc(
        'decrement_collection_sentence_count',
        params: {
          'collection_id': collectionId, 
          'count': count
        },
      );
    } catch (e) {
      logger.e('Error incrementing sentence count for collection $collectionId: $e');
    }
  }
  
  static Future<void> _setCollectionSentenceCount(String collectionId, int count) async {
    try {
      await supabase.rpc(
        'set_collection_sentence_count',
        params: {
          'collection_id': collectionId,
          'new_count': count,
        },
      );
    } catch (e) {
      logger.e('Error setting sentence count for collection $collectionId: $e');
      // Don't throw - this is a secondary operation
    }
  }


}