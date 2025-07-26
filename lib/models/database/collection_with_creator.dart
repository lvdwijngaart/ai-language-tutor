

import 'package:ai_lang_tutor_v2/models/database/collection.dart';
import 'package:ai_lang_tutor_v2/models/database/profile.dart';

class CollectionWithCreator {
  final Collection collection;
  final Profile? creator;

  const CollectionWithCreator({
    required this.collection,
    this.creator,
  });

  factory CollectionWithCreator.fromMap(Map<String, dynamic> map) {
    final collection = Collection.fromMap(map);
    
    // Extract creator profile data
    Profile? creator;
    final profileData = map['profiles'] as Map<String, dynamic>?;
    if (profileData != null) {
      creator = Profile(
        id: profileData['id'] as String,
        displayName: profileData['display_name'] as String,
        avatarUrl: profileData['avatar_url'] as String?,
        // Add other profile fields as needed
      );
    }
    
    return CollectionWithCreator(
      collection: collection,
      creator: creator,
    );
  }
}