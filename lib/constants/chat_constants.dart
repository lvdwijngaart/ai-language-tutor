

import 'package:ai_lang_tutor_v2/models/chat_message.dart';
import 'package:ai_lang_tutor_v2/models/sentence_analysis.dart';

class StandardChatMessages {
  static ChatMessage initialMessage = ChatMessage(
    text: 'Welcome to the AI Tutor Chat! How can I assist you today?',
    isUserMessage: false,
    timestamp: DateTime.now(),
    sentenceAnalyses: [
      SentenceAnalysis(
        sentence: 'Welcome to the AI Tutor Chat!',
        contextualMeaning: 'This is a greeting message to start the chat.',
      ), 
      SentenceAnalysis(
        sentence: 'How can I assist you today?',
        contextualMeaning: 'This is an invitation for the user to ask questions or seek help.',
      ),
    ],
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



  static ChatMessage testMessage = ChatMessage(
    text: 'This is a test message for debugging purposes.',
    isUserMessage: false,
    timestamp: DateTime.now(),
    sentenceAnalyses: [
      SentenceAnalysis(
        sentence: 'This is a test message for debugging purposes.',
        contextualMeaning: 'This message is used to test the chat functionality.',
      )
    ],
  );
}