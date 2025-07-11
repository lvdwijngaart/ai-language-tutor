import 'package:ai_lang_tutor_v2/models/database/collection.dart';
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

      return true;
    } catch (e) {
      throw Exception(
        'Something went wrong during inserting the CollectionSave: $e',
      );
    }
  }
}
