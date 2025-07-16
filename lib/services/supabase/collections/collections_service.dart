import 'package:ai_lang_tutor_v2/models/database/collection.dart';
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/collections_save_service.dart';
import 'package:ai_lang_tutor_v2/services/supabase_client.dart';

class CollectionsService {
  static Future<List<Collection>> getHighlightCollections({
    required int nrOfResults,
    required String userId,
    required Language language,
    // Add more?
  }) async {
    final collectionsAlreadySaved =
        await CollectionsSaveService.getCollectionIdsByUser(userId: userId);

    final result = await supabase
        .from('collections')
        .select()
        .eq('is_public', true)
        .not('id', 'in', collectionsAlreadySaved)
        .eq('language', language.name)
        .order('saves', ascending: false)
        .limit(nrOfResults);

    List<Collection> collections = result
        .map((collection) => Collection.fromMap(collection))
        .toList();

    return collections;
  }

  static Future<List<Collection>> getPersonalCollections({
    required String userId,
    required Language language
  }) async {
    // Get collectionIds for this user
    final List<String> collectionIds =
        await CollectionsSaveService.getCollectionIdsByUser(userId: userId);
    if (collectionIds.isEmpty) return [];

    // Get collections by IDs
    final collections = await supabase
        .from('collections')
        .select()
        .eq('language', language.name)
        .inFilter('id', collectionIds);

    return (collections as List).map((row) => Collection.fromMap(row)).toList();
  }

  static Future<Collection> createNewCollection({
    required Collection collection,
    required String userIdForSave
  }) async {
    try {
      final collectionResult = await supabase
          .from('collections')
          .insert(collection.toMap())
          .select();

      if (collectionResult.isEmpty) {
        throw Exception('The insertion was not successful. Result is empty. ');
      }

      final Collection collectionAdded = Collection.fromMap(collectionResult.first);

      bool addSuccess = false;
      if (userIdForSave.isNotEmpty && collectionAdded.id != null) {
        addSuccess = await CollectionsSaveService.createCollectionSave(
          userId: userIdForSave,
          collectionId: collectionAdded.id!,
        );
      }

      if (!addSuccess) {
        throw Exception('Saving the collection to user $userIdForSave was not successful');
      }

      return Collection.fromMap(collectionResult.first);

    } catch (e) {
      throw Exception(
        'An Exception occurred during the insertion of a new Collection: $e',
      );
    }
  }
}
