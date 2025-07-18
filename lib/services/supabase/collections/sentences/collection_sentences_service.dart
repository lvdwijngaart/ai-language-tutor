import 'package:ai_lang_tutor_v2/services/supabase_client.dart';

class CollectionSentencesService {

  static Future<bool> addMultSentencesToCollection({
    required List<String> sentenceIds, 
    required String collectionId,
  }) async {

    try {
      final List<Map<String, dynamic>> insertList = [];
      sentenceIds.map((sentenceId) {
        insertList.add({
          'collection_id': collectionId,
          'sentence_id': sentenceId, 
        });
      }).toList();

      final addResult = await supabase
          .from('collection_sentences')
          .insert(insertList)
          .select();

      if (addResult.isEmpty) {
        throw Exception('Failed to add sentence to collection - no results returned');
      }

      return true;

    } catch (e) {
      // TODO: catch
    }

    return false;
  }

  // ✅ Add a single sentence to a collection
  static Future<bool> addSentenceToCollection({
    required String sentenceId, 
    required String collectionId,
  }) async {
    try {
      final addResult = await supabase
          .from('collection_sentences')
          .insert({
            'collection_id': collectionId,
            'sentence_id': sentenceId, 
          })
          .select();

      if (addResult.isEmpty) {
        throw Exception('Failed to add sentence to collection - no results returned');
      }

      return true;
    } catch (e) {
      throw Exception('Error adding sentence to collection: $e');
    }
  }

}