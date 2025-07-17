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

  // ✅ Search public collections with pagination
  static Future<List<Collection>> searchPublicCollections({
    required String searchTerm,
    required String categoryFilter,
    required Language language,
    required String userId,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      dynamic queryBuilder = supabase
          .from('collections')
          .select()
          .eq('language', language.name)
          .eq('is_public', true)
          .neq('created_by', userId);

      // ✅ Apply search filter on server
      if (searchTerm.isNotEmpty) {
        queryBuilder = queryBuilder.or('title.ilike.%$searchTerm%,description.ilike.%$searchTerm%');
      }

      // Apply category sorting and pagination
      final offset = page * pageSize;
      
      // TODO: Fix this: popular = amount of saves, etc
      switch (categoryFilter) {
        case 'popular':
          queryBuilder = queryBuilder
              .order('nr_of_sentences', ascending: false)
              .range(offset, offset + pageSize - 1);
          break;
        case 'recent':
          queryBuilder = queryBuilder
              .order('created_at', ascending: false)
              .range(offset, offset + pageSize - 1);
          break;
        case 'featured':
          queryBuilder = queryBuilder
              .eq('is_featured', true)
              .order('created_at', ascending: false)
              .range(offset, offset + pageSize - 1);
          break;
        case 'all':
        default:
          queryBuilder = queryBuilder
              .order('created_at', ascending: false)
              .range(offset, offset + pageSize - 1);
          break;
      }

      final result = await queryBuilder;

      return (result as List).map((row) => Collection.fromMap(row)).toList();
    } catch (e) {
      throw Exception('Error searching public collections: $e');
    }
  }

  // ✅ Get single collection by ID
  static Future<Collection> getCollectionById(String id) async {
    try {
      final result = await supabase
          .from('collections')
          .select()
          .eq('id', id)
          .single(); // Get single record

      return Collection.fromMap(result);
    } catch (e) {
      throw Exception('Error getting collection: $e');
    }
  }
}
