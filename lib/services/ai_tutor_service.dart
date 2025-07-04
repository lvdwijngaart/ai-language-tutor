

import 'dart:convert';

import 'package:ai_lang_tutor_v2/models/ai_response.dart';
import 'package:ai_lang_tutor_v2/models/app_enums.dart';
import 'package:ai_lang_tutor_v2/models/chat_message.dart';
import 'package:ai_lang_tutor_v2/models/sentence_analysis.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AILanguageTutorService {
  static const String _openaiApiUrl = 'https://api.openai.com/v1/chat/completions';
  static final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  // Cache for on-demand sentence analysis to avoid redundant API calls
  // static final Map<String, Data> _analysisCache = {};
  // static final Map<String, Data> _userAnalysisCache = {};

  // TODO: Before production releases: 
  // 1. Disable OpenAI data usage sharing in platform settings
  // 2. Implement server-side API proxy to hide keys from client
  // 3. Add rate limiting and usage monitoring

  // System prompt for conversational responses (fast, simple)
  static String _buildInstructionPrompt(Language targetLanguage, ProficiencyLevel proficiencyLevel) {
    return '''
      You are an AI language tutor for $targetLanguage. 

      Respond naturally in $targetLanguage appropriate for a $proficiencyLevel level learner. 

      - Keep responses to 1-3 sentences maximum. 
      - Be conversational and engaging. 
      - Ask follow-up questions to maintain the dialogue. 
      - Provide gentle corrections when needed. 
      - Use simple vocabulary for beginners, more complex for intermediate learners and include idiomatic language for advanced learners. 
      - Be encouraging and supportive. 
    ''';
  }

  // System prompt for user message analysis
  static String _buildUserAnalysisPrompt(Language targetLanguage, ProficiencyLevel proficiencyLevel) {
    return '''
      
    ''';
  }

  // Main method 
  static Future<AIResponse> sendMessage({
    required ChatMessage message, 
    required List<ChatMessage> conversationHistory,
    required Language targetLanguage, 
    required ProficiencyLevel proficiencyLevel, 
    bool analyzeUserMessage = false,
  }) async {
    try {
      if (_apiKey.isEmpty) {
        throw Exception('OpenAI API key not found. Please add OPENAI_API_KEY to your .env file');
      }

      final messages = <Map<String, String>>[];
      String role = message.isUserMessage ? 'user' : 'system';

      final ChatMessage conversationalResponse = await _getConversationalResponse(
        userMessage: message, 
        conversationHistory: conversationHistory, 
        targetLanguage: targetLanguage, 
        proficiencyLevel: proficiencyLevel, 
      );

      // Optionally get the userMessageAnalysis for the user's last message
      SentenceAnalysis? userSentenceAnalysis;
      // if (analyzeUserMessage && message.text.trim().isNotEmpty) {
      //   userSentenceAnalysis = await _getUserMessageAnalysis(
      //     userMessage: message, 
      //     targetLanguage: targetLanguage, 
      //     proficiencyLevel: proficiencyLevel
      //   );
      // }

      
      return AIResponse(
        aiMessage: conversationalResponse,
        userSentenceAnalysis: userSentenceAnalysis, 
        language: targetLanguage, 
        proficiencyLevel: proficiencyLevel
      );
      
    } catch (error) {
      // return _createFallbackResponse();
      return AIResponse(
        aiMessage: ChatMessage(text: error.toString(), isUserMessage: false), 
        language: targetLanguage, 
        proficiencyLevel: proficiencyLevel
      );
    }
  }

  static Future<ChatMessage> _getConversationalResponse({
    required ChatMessage userMessage, 
    required List<ChatMessage> conversationHistory, 
    required Language targetLanguage, 
    required ProficiencyLevel proficiencyLevel
  }) async {
    // Build conversational system prompt
    final messages = <Map<String, String>>[];

    messages.add({
      'role': 'system',
      'content': _buildInstructionPrompt(targetLanguage, proficiencyLevel)
    });

    // TODO: Include chat history


    // Add current User Message   
    messages.add({
        'role': 'user',
        'content': userMessage.text.trim()
      });

    // Make API call for conversation
    final response = await http.post(
      Uri.parse(_openaiApiUrl), 
      headers: {
        'Content-Type': 'application/json', 
        'Authorization': 'Bearer $_apiKey'
      }, 
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': messages,
        'max_tokens': 1000,
        'temperature': 0.7,
        'presence_penalty': 0.1,
        'frequency_penalty': 0.1,
        'tools': [
          {
            "type": "function",
            "function": {
              "name": "analyze_language_response",
              "description": "Analyzes a message in the target language in detail and provides feedback per sentence.",
              "parameters": {
                "type": "object",
                "properties": {
                  "originalText": {"type": "string"},
                  "sentences": {
                    "type": "array",
                    "items": {
                      "type": "object",
                      "properties": {
                        "text": {"type": "string"},
                        "startIndex": {"type": "integer"},
                        "endIndex": {"type": "integer"},
                        "contextualMeaning": {"type": "string"},
                        "mistakes": {
                          "type": "array",
                          "items": {
                            "type": "object",
                            "properties": {
                              "error": {"type": "string"},
                              "correction": {"type": "string"},
                              "explanation": {"type": "string"}
                            },
                            "required": ["error", "correction", "explanation"]
                          }
                        },
                        "improvements": {
                          "type": "array",
                          "items": {"type": "string"}
                        },
                        "keyPhrases": {
                          "type": "array",
                          "items": {
                            "type": "object",
                            "properties": {
                              "phrase": {"type": "string"},
                              "definition": {"type": "string"},
                              "alternatives": {
                                "type": "array",
                                "items": {"type": "string"}
                              },
                              "partOfSpeech": {"type": "string"},
                              "frequency": {"type": "string"}
                            },
                            "required": ["phrase", "definition"]
                          }
                        },
                        "alternatives": {
                          "type": "array",
                          "items": {"type": "string"}
                        },
                        "grammarPattern": {"type": "string"},
                        "difficulty": {"type": "string"}
                      },
                      "required": ["text", "startIndex", "endIndex", "contextualMeaning"]
                    }
                  }
                },
                "required": ["originalText", "sentences"]
              }
            }
          }
        ]
      })
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final aiResponse = data['choices'][0]['message']['content'] as String;
      return ChatMessage(
        text: aiResponse.trim(), 
        isUserMessage: false, 

      );
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception('OpenAI API Error: ${errorData['error']['message']}');
    }
  }
}