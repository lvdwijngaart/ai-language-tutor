

import 'package:ai_lang_tutor_v2/models/app_enums.dart';
import 'package:ai_lang_tutor_v2/models/sentence_analysis.dart';

class ChatMessage {
  final String text;
  final bool isUserMessage;
  final DateTime timestamp;
  List<SentenceAnalysis>? sentenceAnalyses;
  final Language? targetLanguage;
  final ProficiencyLevel? proficiencyLevel;

  ChatMessage({
    required this.text, 
    required this.isUserMessage, 
    DateTime? timestamp, 
    this.sentenceAnalyses,
    this.targetLanguage, 
    this.proficiencyLevel
  }) : timestamp = timestamp ?? DateTime.now();

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'text': text, 
      'isUserMessage': isUserMessage, 
      'timestamp': timestamp.toIso8601String(), 
      'sentenceAnalyses': sentenceAnalyses.toString()
    };
  }

  // Create from JSON
  // This function can be called to create a ChatMessage instance from a JSON object
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String,
      isUserMessage: json['is_user_message'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      targetLanguage: json['target_language'], 
      proficiencyLevel: json['proficiency_level']
    );
  }

  // Copy message with new values
  ChatMessage copyWith({
    String? text, 
    bool? isUserMessage, 
    DateTime? timestamp, 
    Language? targetLanguage,
    ProficiencyLevel? proficiencyLevel
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUserMessage: isUserMessage ?? this.isUserMessage,
      timestamp: timestamp ?? this.timestamp,
      targetLanguage: targetLanguage ?? this.targetLanguage, 
      proficiencyLevel: proficiencyLevel ?? this.proficiencyLevel
    );
  }

  @override
  String toString() {
    return 'ChatMessage(text: $text, isUserMessage: $isUserMessage, timestamp: $timestamp, targetLanguage: $targetLanguage, proficiency level: $proficiencyLevel)';
  }

  // Override equality '==' operator for comparing ChatMessage instances
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.text == text &&
        other.isUserMessage == isUserMessage &&
        other.timestamp == timestamp;
  }

  // hashCode is used to compare objects in collections
  // It should be overridden whenever '==' is overridden
  @override
  int get hashCode {
    return text.hashCode ^ isUserMessage.hashCode ^ timestamp.hashCode;
  }
}