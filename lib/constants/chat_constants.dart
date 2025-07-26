

import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/models/other/chat_message.dart';
import 'package:ai_lang_tutor_v2/models/other/sentence_analysis.dart';

class StandardChatMessages {
  static ChatMessage initialMessage = ChatMessage(
    text: 'Welcome to the AI Tutor Chat! How can I assist you today?',
    isUserMessage: false,
    timestamp: DateTime.now(),
  );

  static ChatMessage loadingMessage = ChatMessage(
    text: 'Loading...',
    isUserMessage: false,
    timestamp: DateTime.now(),
  ); 

  static ChatMessage errorMessage = ChatMessage(
    text: 'An error occurred. Please try again later.',
    isUserMessage: false,
    timestamp: DateTime.now(),
  );

  static ChatMessage changeLanguageMessage(Language newLanguage) {
    return ChatMessage(
      text: "Language changed to ${newLanguage.displayName} ${newLanguage.flagEmoji}. Let's continue our conversation!", 
      isUserMessage: false, 
      timestamp: DateTime.now()
    );
  }

  static ChatMessage changeProficiencyLevel(ProficiencyLevel newLevel) {
    return ChatMessage(
      text: "Proficiency level updated to ${newLevel.displayName}. I'll adjust my teaching style accordingly!", 
      isUserMessage: false, 
      timestamp: DateTime.now()
    );
  }


  static ChatMessage testMessage = ChatMessage(
    text: 'This is a test message for debugging purposes.',
    isUserMessage: false,
    timestamp: DateTime.now(),
    sentenceAnalyses: [
      SentenceAnalysis(
        sentence: 'This is a test message for debugging purposes.',
        translation: 'This is the translation of the test message',
        contextualMeaning: 'This is the contextual meaning of the test message.',
      )
    ],
  );
}