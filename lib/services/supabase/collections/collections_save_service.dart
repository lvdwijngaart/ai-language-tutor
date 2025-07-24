import 'package:ai_lang_tutor_v2/models/database/collection_save.dart';
import 'package:ai_lang_tutor_v2/services/supabase_client.dart';

class CollectionsSaveService {
  static Future<List<String>> getCollectionIdsByUser({
    required String userId,
  }) async {
    final savesResult = await supabase
        .from('collection_saves')
        .select('collection_id')
        .eq('user_id', userId);

    final List<String> collectionIds = (savesResult as List)
        .map((row) => row['collection_id'] as String)
        .toList();

    return collectionIds;
  }

  // TODO: add 1 to collection.saves
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

      await supabase.rpc(
        'increment_collection_saves',
        params: {'collection_id': collectionId},
      );

      return true;
    } catch (e) {
      throw Exception(
        'Something went wrong during inserting the CollectionSave: $e',
      );
    }
  }

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

      await supabase.rpc(
        'decrement_collection_saves',
        params: {'collection_id': collectionId},
      );

      return true;
    } catch (e) {
      throw Exception(
        'Something went wrong during deleting the CollectionSave: $e',
      );
    }
  }
}
