

import 'package:ai_lang_tutor_v2/models/app_enums.dart';
import 'package:ai_lang_tutor_v2/models/chat_message.dart';
import 'package:ai_lang_tutor_v2/models/sentence_analysis.dart';

class AIResponse {
  final ChatMessage aiMessage;
  final SentenceAnalysis? userSentenceAnalysis;
  final Language language;
  final ProficiencyLevel proficiencyLevel;
  final DateTime timestamp;


  AIResponse({
    required this.aiMessage,
    this.userSentenceAnalysis,
    required this.language,
    required this.proficiencyLevel,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AIResponse.fromJSON(Map<String, dynamic> json) {
    return AIResponse(
      aiMessage: json['message'], 
      language: json['language'], 
      proficiencyLevel: json['proficiency_level'], 
      timestamp: json['timestamp'] ? DateTime.parse(json['timestamp']) : DateTime.now()
    );
  }

  // TODO: toJSON


}