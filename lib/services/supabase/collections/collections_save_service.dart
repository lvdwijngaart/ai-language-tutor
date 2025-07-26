import 'package:ai_lang_tutor_v2/models/database/collection_save.dart';
import 'package:ai_lang_tutor_v2/services/supabase_client.dart';
import 'package:ai_lang_tutor_v2/utils/logger.dart';

class CollectionsSaveService {

  /// Get Collections for user [userId]
  static Future<List<String>> getCollectionIdsByUser({
    required String userId,
  }) async {
    try {
      final savesResult = await supabase
          .from('collection_saves')
          .select('collection_id')
          .eq('user_id', userId);

      final List<String> collectionIds = (savesResult as List)
          .map((row) => row['collection_id'] as String)
          .toList();

      return collectionIds;
    } catch (e) {
      logger.e('Error while getting collectionIds for user $userId: $e');
      throw Exception('Failed to get the collections saved by user: $e');
    }
  }

  /// Save collection [collectionId] to user [userId]
  static Future<bool> createCollectionSave({
    required String userId,
    required String collectionId,
  }) async {
    try {
      final CollectionSave collectionSave = CollectionSave(
        userId: userId,
        collectionId: collectionId,
        createdAt: DateTime.now(),
      );
      final saveResult = await supabase
          .from('collection_saves')
          .insert(collectionSave.toMap())
          .select();

      if (saveResult.isEmpty) {
        throw Exception(
          'Something went wrong during adding the CollectionSave. Result is empty',
        );
      }
      
      _incrementCollectionSaves(collectionId);

      return true;
    } catch (e) {
      logger.e('Error while saving collection $collectionId to user $userId: $e');
      throw Exception(
        'Something went wrong while inserting the CollectionSave: $e',
      );
    }
  }

  /// Delete collection save relation between [userId] and [collectionId]
  static Future<bool> deleteCollectionSave({
    required String userId,
    required String collectionId,
  }) async {
    try {
      final deleteResult = await supabase
          .from('collection_saves')
          .delete()
          .eq('user_id', userId)
          .eq('collection_id', collectionId)
          .select();

      // Check if any rows were deleted
      if (deleteResult.isEmpty) {
        throw Exception(
          'No collection save found to delete or delete operation failed',
        );
      }
      
      _decrementCollectionSaves(collectionId);

      return true;
    } catch (e) {
      logger.e('Error while deleting collectionSave between $collectionId and $userId: $e');
      throw Exception(
        'Something went wrong during deleting the CollectionSave: $e',
      );
    }
  }


  // HELPER METHODS: 

  static Future<void> _incrementCollectionSaves(String collectionId) async {
    try {
      await supabase.rpc(
        'increment_collection_saves',
        params: {'collection_id': collectionId},
      );
    } catch (e) {
      logger.e('Error while incrementing collection.saves for $collectionId: $e');
    }
  }

  static Future<void> _decrementCollectionSaves(String collectionId) async {
    try {
      await supabase.rpc(
        'decrement_collection_saves',
        params: {'collection_id': collectionId},
      );
    } catch (e) {
      logger.e('Error while incrementing collection.saves for $collectionId: $e');
    }
  }
}
