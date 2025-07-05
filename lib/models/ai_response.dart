

import 'package:ai_lang_tutor_v2/models/app_enums.dart';
import 'package:ai_lang_tutor_v2/models/chat_message.dart';
import 'package:ai_lang_tutor_v2/models/sentence_analysis.dart';

class AIResponse {
  final ChatMessage aiMessage;
  // final SentenceAnalysis? userSentenceAnalysis;
  final Language language;  // TODO: Remove this since it is already in ChatMessage
  final ProficiencyLevel proficiencyLevel;
  final DateTime timestamp;
  final int? inputTokens;
  final int? outputTokens;
  final int? totalTokens;


  AIResponse({
    required this.aiMessage,
    // this.userSentenceAnalysis,
    required this.language,
    required this.proficiencyLevel,
    DateTime? timestamp,
    this.inputTokens, 
    this.outputTokens, 
    this.totalTokens
  }) : timestamp = timestamp ?? DateTime.now();

  factory AIResponse.fromJSON(Map<String, dynamic> json) {
    return AIResponse(
      aiMessage: json['ai_message'], 
      language: json['language'], 
      proficiencyLevel: json['proficiency_level'], 
      timestamp: json['timestamp'] ? DateTime.parse(json['timestamp']) : DateTime.now()
    );
  }

  // TODO: toJSON


}