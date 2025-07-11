import 'package:ai_lang_tutor_v2/utils/date_time_helper.dart';

class CollectionSave {
  final String userId;
  final String collectionId;
  final DateTime createdAt;

  CollectionSave({
    required this.userId,
    required this.collectionId,
    required this.createdAt,
  });

  factory CollectionSave.fromMap(Map<String, dynamic> json) {
    final userId = json['user_id'];
    if (userId == null || userId is! String || userId.isEmpty) {
      throw ArgumentError(
        'User ID is a necessary field for creating a CollectionSaves object. ',
      );
    }

    final collectionId = json['collection_id'];
    if (collectionId == null ||
        collectionId is! String ||
        collectionId.isEmpty) {
      throw ArgumentError(
        'Collection ID is a necessary field for creating a CollectionSaves object. ',
      );
    }

    return CollectionSave(
      userId: userId,
      collectionId: collectionId,
      createdAt: getDateTimeFromMapItem(json['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'collection_id': collectionId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
