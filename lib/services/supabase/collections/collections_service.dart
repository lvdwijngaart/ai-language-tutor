import 'package:ai_lang_tutor_v2/models/database/collection.dart';
import 'package:ai_lang_tutor_v2/models/database/collection_with_creator.dart';
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/collections_save_service.dart';
import 'package:ai_lang_tutor_v2/services/supabase_client.dart';
import 'package:ai_lang_tutor_v2/utils/logger.dart';

class CollectionsService {

  static final String _table = 'collections';
  static final String _linkingTable = 'collection_saves';

  /// Get personal collections for language [language] that are saved to user [userId]
  static Future<List<Collection>> getPersonalCollections({
    required String userId,
    required Language language,
  }) async {
    try {
      final collections = await supabase
          .from(_table)
          .select('''
            *,
            $_linkingTable!inner(
              user_id,
              created_at
            )
          ''')
          .eq('language', language.name)
          .eq('created_by', userId)
          .eq('$_linkingTable.user_id', userId)
          // TODO: order by linkingTables' last_played, so that the collection that user last played is first?
          .order('created_at', ascending: false);   
      
      return (collections as List).map((row) => Collection.fromMap(row)).toList();
    } catch (e) {
      logger.e('Error getting personal collections for ${language.displayName} for user $userId: $e');
      return [];
    }
  }

  /// Get public collections for [language] saved to [userId]
  static Future<List<Collection>> getPublicCollections({
    required String userId,
    required Language language,
  }) async {
    try {
      final collections = await supabase
          .from(_table)
          .select('''
            *,
            $_linkingTable!inner(
              user_id,
              created_at
            )
          ''')
          .eq('language', language.name)
          .neq('created_by', userId)
          .eq('$_linkingTable.user_id', userId)
          // TODO: order by linkingTables' last_played, so that the collection that user last played is first?
          .order('created_at', ascending: false);   
      
      return (collections as List).map((row) => Collection.fromMap(row)).toList();
    } catch (e) {
      logger.e('Error while getting public collections for ${language.displayName} to user $userId: $e');
      return [];
    }
  }

  static Future<Collection> createNewCollection({
    required Collection collection,
    required String userIdForSave,
  }) async {
    try {
      final collectionResult = await supabase
          .from('collections')
          .insert(collection.toMap())
          .select();

      if (collectionResult.isEmpty) {
        throw Exception('The insertion was not successful. Result is empty. ');
      }

      final Collection collectionAdded = Collection.fromMap(
        collectionResult.first,
      );

      bool addSuccess = false;
      if (userIdForSave.isNotEmpty && collectionAdded.id != null) {
        addSuccess = await CollectionsSaveService.createCollectionSave(
          userId: userIdForSave,
          collectionId: collectionAdded.id!,
        );
      }

      if (!addSuccess) {
        throw Exception(
          'Saving the collection to user $userIdForSave was not successful',
        );
      }

      return Collection.fromMap(collectionResult.first);
    } catch (e) {
      throw Exception(
        'An Exception occurred during the insertion of a new Collection: $e',
      );
    }
  }

  /// Searches for public collections based on the provided criteria.
  ///
  /// Returns a [Future] that resolves to a list of [Collection] objects.
  /// 
  /// The search can be customized by passing relevant parameters.
  /// Only collections marked as public will be included in the results.
  static Future<List<Collection>> searchPublicCollections({
    required String searchTerm,
    required String categoryFilter,
    required Language language,
    required String userId,
    required List<String> savedCollectionIds,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      dynamic queryBuilder = supabase
          .from('collections')
          .select()
          .eq('language', language.name)
          .eq('is_public', true)
          // TODO: in future there will be a field 'deprecated' or smth like that, 
          // TODO:  for collections that have been deleted by their creator. People who have this field saved are able 
          // TODO: to still practice it, but it will not show up in the search anymore
          // .not('id', 'in', savedCollectionIds)
          .neq('created_by', userId);

      // Apply search filter on server
      if (searchTerm.isNotEmpty) {
        queryBuilder = queryBuilder.or(
          'title.ilike.%$searchTerm%,description.ilike.%$searchTerm%',
        );
      }

      // Apply category sorting and pagination
      final offset = page * pageSize;

      
      switch (categoryFilter) {
        case 'popular':
          queryBuilder = queryBuilder
              .order('saves', ascending: false)
              .range(offset, offset + pageSize - 1);
          break;
        case 'recent':
          queryBuilder = queryBuilder
              .order('created_at', ascending: false)
              .range(offset, offset + pageSize - 1);
          break;
        case 'featured':      // TODO: is_featured not implemented
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

      return (result as List)
          .map((row) => Collection.fromMap(row))
          .toList();
    } catch (e) {
      throw Exception('Error searching public collections: $e');
    }
  }

  /// Get single collection by [id]
  static Future<CollectionWithCreator> getCollectionById(String id) async {
    try {
      final result = await supabase
          .from('collections')
          .select('*, profiles!collections_created_by_fkey(id, display_name, avatar_url)')
          .eq('id', id)
          .single(); // Get single record

      return CollectionWithCreator.fromMap(result);
    } catch (e) {
      throw Exception('Error getting collection: $e');
    }
  }

  /// Update collection by [collectionId], updating key-value pairs [updates]
  static Future<Collection> updateCollection(String collectionId, Map<String, dynamic> updates) async {
    try {
      final result = await supabase
        .from('collections')
        .update(updates)
        .eq('id', collectionId)
        .select()
        .single();

      return Collection.fromMap(result);
      
    } catch (e) {
      throw Exception('Error while editing collection by id $collectionId: $e');
    }
  }
}
