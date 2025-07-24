import 'package:ai_lang_tutor_v2/models/database/profile.dart';
import 'package:ai_lang_tutor_v2/services/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilesService {
  static Future<void> createProfile({required String displayName}) async {
    try {
      Profile profile = Profile(
        id: supabase.auth.currentUser!.id,
        displayName: displayName,
        createdAt: DateTime.now(),
        onboardingComplete: false,
      );

      print('🔍 Attempting to insert profile: ${profile.toMap()}');

      final result = await supabase
          .from('profiles')
          .insert(profile.toMap())
          .select(); // Add .select() to get the inserted data back

      print('✅ Profile created successfully: $result');
    } catch (error) {
      print('❌ Error creating profile: $error');
      rethrow; // Re-throw so the calling code can handle it
    }
  }

  static Future<Profile> getProfileById({required String userId}) async {
    // TODO: Finish
    throw Exception('TODO, profilebyId');
  }
}
