

import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/models/other/chat_message.dart';
import 'package:ai_lang_tutor_v2/models/other/sentence_analysis.dart';

class AIResponse {
  final ChatMessage aiMessage;
  // final SentenceAnalysis? userSentenceAnalysis;
  final DateTime timestamp;
  final int? inputTokens;
  final int? outputTokens;
  final int? totalTokens;


  AIResponse({
    required this.aiMessage,
    // this.userSentenceAnalysis,
    DateTime? timestamp,
    this.inputTokens, 
    this.outputTokens, 
    this.totalTokens
  }) : timestamp = timestamp ?? DateTime.now();

  factory AIResponse.fromJSON(Map<String, dynamic> json) {
    return AIResponse(
      aiMessage: json['ai_message'], 
      timestamp: json['timestamp'] ? DateTime.parse(json['timestamp']) : DateTime.now()
    );
  }

  // TODO: toJSON


}