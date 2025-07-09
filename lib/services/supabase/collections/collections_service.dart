import 'package:ai_lang_tutor_v2/models/database/collection.dart';
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/services/supabase_client.dart';

class CollectionsService {
  static Future<List<Collection>> getHighlightCollections({
    required int nrOfResults,
    required Language language, 
    // Add more?
  }) async {
    final result = await supabase
        .from('collections')
        .select()
        .eq('is_public', true)
        .order('saves', ascending: false)
        .limit(nrOfResults);
        
    List<Collection> collections = result
        .map((collection) => Collection.fromMap(collection))
        .toList();

    return collections;
  }
}
