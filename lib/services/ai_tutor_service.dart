import 'dart:convert';
import 'dart:math';

import 'package:ai_lang_tutor_v2/models/other/ai_response.dart';
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/models/other/chat_message.dart';
import 'package:ai_lang_tutor_v2/models/other/sentence_analysis.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AILanguageTutorService {
  static const String _openaiApiUrl = 'https://api.openai.com/v1/chat/completions';
  static final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  static final Logger _logger = Logger();

  // Cache for on-demand sentence analysis to avoid redundant API calls
  // static final Map<String, Data> _analysisCache = {};
  // static final Map<String, Data> _userAnalysisCache = {};

  // TODO: Before production releases: 
  // 1. Disable OpenAI data usage sharing in platform settings
  // 2. Implement server-side API proxy to hide keys from client
  // 3. Add rate limiting and usage monitoring


  // System prompt that handles both conversation and analysis
  static String _buildInstructionPrompt(Language targetLanguage, ProficiencyLevel proficiencyLevel) {
    return '''
      You are an AI language tutor for $targetLanguage. 

      IMPORTANT: You MUST use the comprehensive_language_analysis function for ALL responses. Never respond with plain text.

      Your task is to:
      1. Respond naturally in $targetLanguage appropriate for a $proficiencyLevel level learner
      2. Analyze your own response sentence by sentence

      For responses:
      - Keep responses to 1-3 sentences maximum
      - Be conversational and engaging
      - Ask follow-up questions to maintain the dialogue
      - If a mistake was made, ignore it and assume what the user meant. This correcting will be done in a seperate api request. 
      - Use vocabulary appropriate for $proficiencyLevel level
      - Be encouraging and supportive

      For your response analysis:
      - Break down EVERY sentence into individual analyses
      - Provide literal or idiomatic translation per sentence
      - Identify key vocabulary terms with definitions and translations
      - Provide alternative expressions for each sentence
      - Explain the contextual meaning of each sentence

      REMEMBER: You must provide sentenceAnalyses for your own response. Do not leave this array empty.
    ''';
  }

  static String _buildAnalysisPrompt(Language targetLanguage, ProficiencyLevel proficiencyLevel) {
    return '''
      You are an AI language tutor for $targetLanguage. 

      IMPORTANT: You MUST use the comprehensive_language_analysis function for ALL responses. Never respond with plain text.

      Your task is to:
      1. Return the user's **exact original message** in the `"text"` field.
      2. Divide the user's message into grammatical sentences and place each **complete, non-repeated sentence** into the `"sentenceAnalyses"` array as its own object.
      3. DO NOT:
        - Repeat any sentence or part of a sentence.
        - Split one sentence across multiple objects.
        - Combine multiple sentences into one object.
      4. Each sentence should appear **exactly once** in the `"sentenceAnalyses"` array.
      If any sentence appears more than once, this is an error.
      You MUST check for duplicates in the sentenceAnalyses array before submitting the response.
      Do not include the same sentence or sentence object more than once.


      REMEMBER: You must provide sentenceAnalyses for the user's message. This means dividing the user's message into sentences, and not hallucinating or repeating sentences more than in the original messaeg. Do not leave this array empty.

      The message you need to analyze is: 
    ''';
  }

  // Main method 
  static Future<AIResponse> sendMessage({
    required ChatMessage message, 
    required List<ChatMessage> conversationHistory,
    required Language targetLanguage, 
    required ProficiencyLevel proficiencyLevel, 
    bool analyzeUserMessage = false,
    required void Function(AIResponse userAnalysis) onUserAnalysisReady
  }) async {
    try {
      if (_apiKey.isEmpty) {
        throw Exception('OpenAI API key not found. Please add OPENAI_API_KEY to your .env file');
      }

      final aiResponse = await _getResponse(
        userMessage: message, 
        conversationHistory: conversationHistory, 
        targetLanguage: targetLanguage, 
        proficiencyLevel: proficiencyLevel, 
        isAnalysisRequest: false
      );
      
      AIResponse? userMessage;
      if (analyzeUserMessage && message.text.trim().isNotEmpty) {
        _getResponse(
          userMessage: message, 
          conversationHistory: conversationHistory, 
          targetLanguage: targetLanguage, 
          proficiencyLevel: proficiencyLevel, 
          isAnalysisRequest: true
        ).then((userAnalysis) {
          onUserAnalysisReady(userAnalysis);
          // message.sentenceAnalyses = userAnalysis.aiMessage.sentenceAnalyses; 
        }).catchError((e) {
          throw Exception('Something went wrong in the userAnalysis request');
        }); 
      }
      
      return aiResponse;

    } catch (error) {
      // return _createFallbackResponse(); TODO: Better fallback
      return AIResponse(
        aiMessage: ChatMessage(
          text: error.toString(), 
          isUserMessage: false, 
          targetLanguage: targetLanguage, 
          proficiencyLevel: proficiencyLevel
        ), 
      );
    }
  }

  static Future<AIResponse> _getResponse({
    required ChatMessage userMessage, 
    required List<ChatMessage> conversationHistory, 
    required Language targetLanguage, 
    required ProficiencyLevel proficiencyLevel, 
    required bool isAnalysisRequest
  }) async {
    // Build conversational system prompt
    final messages = <Map<String, String>>[];

    // Add instruction prompt to the message queue
    if (!isAnalysisRequest) {
      messages.add({
        'role': 'system',
        'content': _buildInstructionPrompt(targetLanguage, proficiencyLevel)
      });
    }

    // Include conversation history of length $messageContext
    final int messageContext = 8;
    final recentHistory = conversationHistory.length > messageContext
      ? conversationHistory.sublist(conversationHistory.length - messageContext)
      : conversationHistory;

    for (final msg in recentHistory) {
      messages.add({
        'role': msg.isUserMessage ? 'user' : 'assistant', 
        'content': msg.text
      });
    }

    if (isAnalysisRequest) {
      messages.add({
        'role': 'system',
        'content': _buildAnalysisPrompt(targetLanguage, proficiencyLevel)
      });
    }

    // Make API call for conversation
    final toolChoice = isAnalysisRequest 
      ? {"type": "function", "function": {"name": "comprehensive_language_analysis"}} 
      : {"type": "function", "function": {"name": "comprehensive_language_response"}} ;

    try {
      final response = await http.post(
        Uri.parse(_openaiApiUrl), 
        headers: {
          'Content-Type': 'application/json', 
          'Authorization': 'Bearer $_apiKey'
        }, 
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': messages,
          'max_tokens': 2000,
          'temperature': 0.7,
          'presence_penalty': 0.1,
          'frequency_penalty': 0.1,
          'tool_choice': toolChoice,
          'tools': isAnalysisRequest ? _analysisTools : _responseTools
        })
      );

      try {
        AIResponse aiResponse = isAnalysisRequest 
          ? await _getAnalysisResponse(
              response: response,
              userMessage: userMessage, 
              targetLanguage: targetLanguage, 
              proficiencyLevel: proficiencyLevel
            )
          : await _getConversationalResponse(
              response: response, 
              userMessage: userMessage, 
              targetLanguage: targetLanguage, 
              proficiencyLevel: proficiencyLevel
            );

        return aiResponse;
      } catch (e) {
        throw Exception('Error occurred while extracting/parsing data: $e');
      }
    } catch (e) {
      throw Exception('Error occurred during API request: $e');
    }
  }

  static Future<AIResponse> _getConversationalResponse({
    required http.Response response,
    required ChatMessage userMessage, 
    required Language targetLanguage, 
    required ProficiencyLevel proficiencyLevel
  }) async {

    // If response is good, decode and parse response into models
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final choice = data['choices'][0];
      final message = choice['message'];
      
      _logger.i('🔍 Response keys: ${message.keys}');
      
      // Check if response uses tool calls
      if (message['tool_calls'] != null && message['tool_calls'].isNotEmpty) {
        _logger.i('✓ Using function call - processing normally');
        final toolCall = message['tool_calls'][0];
        final functionCall = toolCall['function'];
        
        _logger.i('🔍 Function name: ${functionCall['name']}');
        
        try {
          final arguments = jsonDecode(functionCall['arguments']);
          
          _logger.i('🔍 Arguments keys: ${arguments?.keys?.toList()}');
          
          // Parse with flat structure (no nested aiMessage)
          final text = arguments['text']?.toString() ?? 'No AI response text';
          final isUserMessage = arguments['isUserMessage'] ?? false;
          final sentenceAnalysesData = arguments['sentenceAnalyses'];
          
          _logger.i('🔍 AI text: "$text"');
          _logger.i('🔍 isUserMessage: $isUserMessage');
          _logger.i('🔍 sentenceAnalyses exists: ${sentenceAnalysesData != null}');
          
          // Parse sentence analyses
          List<SentenceAnalysis>? sentenceAnalyses;
          if (sentenceAnalysesData != null && sentenceAnalysesData is List) {
            try {
              sentenceAnalyses = (sentenceAnalysesData as List)
                .map((analysis) => SentenceAnalysis.fromJson(analysis))
                .toList();
              _logger.i('🔍 Parsed ${sentenceAnalyses.length} sentence analyses');
            } catch (e) {
              _logger.e('❌ Error parsing sentence analyses: $e');
            }
          }
        
          // Create AI response message
          final aiResponse = AIResponse(
            aiMessage: ChatMessage(
              text: text,
              isUserMessage: false, // Force to false for AI responses
              sentenceAnalyses: sentenceAnalyses, 
              targetLanguage: targetLanguage, 
              proficiencyLevel: proficiencyLevel
            ), 
            inputTokens: data['usage']?['prompt_tokens'], 
            outputTokens: data['usage']?['completion_tokens'], 
            totalTokens: data['usage']?['total_tokens'],
          );
          
          _logger.i('🔍 Created AI response: "${aiResponse.aiMessage.text}"');
          return aiResponse;

        } catch (e, stackTrace) {
          _logger.e('❌ Error parsing function call: $e');
          _logger.e('📍 Stack trace: $stackTrace');
          
          return AIResponse(
            aiMessage: ChatMessage(
              text: 'Error parsing AI response: $e',
              isUserMessage: false, 
              targetLanguage: targetLanguage, 
              proficiencyLevel: proficiencyLevel
            ),
          );
        }

      } else {
        _logger.e('❌ No tool calls found');
        _logger.i('🔍 Message content: ${message['content']}');
        
        return AIResponse(
          aiMessage: ChatMessage(
            text: message['content'] ?? 'No response content',
            isUserMessage: false, 
            targetLanguage: targetLanguage, 
            proficiencyLevel: proficiencyLevel
          ), 
        );
      }

    } else {
      _logger.e('❌ HTTP Error: ${response.statusCode}');
      _logger.i('🔍 Response body: ${response.body}');
      throw Exception('OpenAI API Error: ${response.statusCode} - ${response.body}');
    }
  }


  static Future<AIResponse> _getAnalysisResponse({
    required http.Response response,
    required ChatMessage userMessage, 
    required Language targetLanguage, 
    required ProficiencyLevel proficiencyLevel
  }) async {

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final choice = data['choices'][0];
      final message = choice['message'];
      
      _logger.i('🔍 Analysis response keys: ${message.keys}');
      
      if (message['tool_calls'] != null && message['tool_calls'].isNotEmpty) {
        _logger.i('✓ Using function call for analysis');
        final toolCall = message['tool_calls'][0];
        final functionCall = toolCall['function'];
        
        _logger.i('🔍 Analysis function name: ${functionCall['name']}');
        
        try {
          final arguments = jsonDecode(functionCall['arguments']);
          
          _logger.i('🔍 Analysis arguments keys: ${arguments?.keys?.toList()}');
          
          // Parse with flat structure (no nested userMessageAnalysis)
          final text = arguments['text']?.toString() ?? userMessage.text;
          final isUserMessage = arguments['isUserMessage'] ?? true;
          final sentenceAnalysesData = arguments['sentenceAnalyses'];
          
          _logger.i('🔍 Analysis text: "$text"');
          _logger.i('🔍 Analysis isUserMessage: $isUserMessage');
          _logger.i('🔍 Analysis sentenceAnalyses exists: ${sentenceAnalysesData != null}');
          
          // Parse sentence analyses
          List<SentenceAnalysis>? sentenceAnalyses;
          if (sentenceAnalysesData != null && sentenceAnalysesData is List) {
            try {
                sentenceAnalyses = sentenceAnalysesData
                  .map((analysis) => SentenceAnalysis.fromJson(analysis))
                  .where((analysis) => !checkDuplicateSentence(userMessage, analysis))
                  .toList();
              _logger.i('🔍 Parsed ${sentenceAnalyses.length} user sentence analyses');
            } catch (e) {
              _logger.e('❌ Error parsing user sentence analyses: $e');
            }
          }
        
          // Create user analysis message
          final aiResponse = AIResponse(
            aiMessage:ChatMessage(
              text: text,
              isUserMessage: true, // Force to true for user analysis
              sentenceAnalyses: sentenceAnalyses, 
              targetLanguage: targetLanguage, 
              proficiencyLevel: proficiencyLevel
            ), 
            inputTokens: data['usage']?['prompt_tokens'], 
            outputTokens: data['usage']?['completion_tokens'], 
            totalTokens: data['usage']?['total_tokens'],
          );
          
          
          _logger.i('🔍 Created user analysis for: "${aiResponse.aiMessage.text}"');
          return aiResponse;

        } catch (e, stackTrace) {
          _logger.e('❌ Error parsing analysis: $e');
          _logger.e('📍 Stack trace: $stackTrace');
          
          return AIResponse(
            aiMessage: ChatMessage(
              text: userMessage.text, 
              isUserMessage: true,
              targetLanguage: targetLanguage, 
              proficiencyLevel: proficiencyLevel
            ),
            inputTokens: data['usage']?['prompt_tokens'], 
            outputTokens: data['usage']?['completion_tokens'], 
            totalTokens: data['usage']?['total_tokens'],
          );
        }

      } else {
        _logger.e('❌ No tool calls found for analysis');
        
        return AIResponse(
            aiMessage: ChatMessage(
              text: userMessage.text, 
              isUserMessage: true,
              targetLanguage: targetLanguage, 
              proficiencyLevel: proficiencyLevel
            ),
            inputTokens: data['usage']?['prompt_tokens'], 
            outputTokens: data['usage']?['completion_tokens'], 
            totalTokens: data['usage']?['total_tokens'],
          );
      }

    } else {
      _logger.e('❌ HTTP Error in analysis: ${response.statusCode}');
      throw Exception('OpenAI API Error: ${response.statusCode} - ${response.body}');
    }
    
  }

  static bool checkDuplicateSentence(ChatMessage message, SentenceAnalysis newSentence) {
    return message.sentenceAnalyses?.any((analysis) => analysis.sentence == newSentence.sentence) ?? false;
  }


  static final List<Map<String, dynamic>> _responseTools = [{
    "type": "function",
    "function": {
      "name": "comprehensive_language_response",
      "description": "Respond conversationally in the target language with your own response analysis.",
      "parameters": {
        "type": "object",
        "properties": {
          "text": {
            "type": "string",
            "description": "Your conversational response to the user in the target language"
          },
          "isUserMessage": {
            "type": "boolean",
            "description": "Always false since this is the AI's response"
          },
          "sentenceAnalyses": {
            "type": "array",
            "description": "Break down your response into individual sentences and provide learning analysis for each",
            "items": {
              "type": "object",
              "properties": {
                "sentence": {
                  "type": "string",
                  "description": "Individual sentence from your response"
                },
                "translation": {
                  "type": "string", 
                  "description": "Literal or idiomatic translation of the sentence"
                },
                "keyTerms": {
                  "type": "array",
                  "items": {
                    "type": "object",
                    "properties": {
                      "termText": {
                        "type": "string", 
                        "description": "The vocabulary word or phrase"
                      },
                      "definition": {
                        "type": "string", 
                        "description": "Definition or translation of the term"
                      },
                      "contextualMeaning": {
                        "type": "string",
                        "description": "How this term is used in this specific context"
                      },
                      "examples": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "Optional usage examples"
                      }
                    },
                    "required": ["termText", "definition", "contextualMeaning"]
                  },
                  "description": "Important vocabulary words or phrases in this sentence"
                },
                "alternatives": {
                  "type": "array",
                  "items": {"type": "string"},
                  "description": "Alternative ways to express the same meaning"
                },
                "contextualMeaning": {
                  "type": "string",
                  "description": "Explain what this sentence means and why you chose this phrasing"
                },
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
                  },
                  "description": "Leave empty for AI responses - this field is for user message analysis"
                }
              },
              "required": ["sentence", "translation", "contextualMeaning", "keyTerms", "alternatives"]
            }
          }
        },
        "required": ["text", "isUserMessage", "sentenceAnalyses"]
      }
    }
  }];

  static final List<Map<String, dynamic>>_analysisTools = [{
    "type": "function",
    "function": {
      "name": "comprehensive_language_analysis",
      "description": "Analyze the user's message for language learning insights. ",
      "parameters": {
        "type": "object",
        "properties": {
          "text": {
            "type": "string",
            "description": "The user's original message"
          },
          "isUserMessage": {
            "type": "boolean",
            "description": "Always true for user message analysis"
          },
          "sentenceAnalyses": {
            "type": "array",
            "description": "Break down the user's message into sentences and analyze each for learning purposes",
            "items": {
              "type": "object",
              "properties": {
                "sentence": {
                  "type": "string",
                  "description": "Individual sentence from user's message"
                },
                "translation": {
                  "type": "string", 
                  "description": "Literal or idiomatic translation of the sentence"
                },
                "keyTerms": {
                  "type": "array",
                  "items": {
                    "type": "object",
                    "properties": {
                      "termText": {
                        "type": "string", 
                        "description": "The vocabulary word or phrase"
                      },
                      "definition": {
                        "type": "string", 
                        "description": "Definition or translation of the term"
                      },
                      "contextualMeaning": {
                        "type": "string",
                        "description": "How this term is used in this specific context"
                      },
                      "examples": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "Optional usage examples"
                      }
                    },
                    "required": ["termText", "definition", "contextualMeaning"]
                  },
                  "description": "Important vocabulary words or phrases used correctly"
                },
                "alternatives": {
                  "type": "array",
                  "items": {"type": "string"},
                  "description": "Alternative ways to express the same meaning"
                },
                "contextualMeaning": {
                  "type": "string",
                  "description": "What the user is trying to express and how well they succeeded"
                },
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
                  },
                  "description": "Grammar, vocabulary, or usage mistakes found in this sentence"
                }
              },
              "required": ["sentence", "translation", "contextualMeaning", "keyTerms", "alternatives"]
            }
          }
        },
        "required": ["text", "isUserMessage", "sentenceAnalyses"]
      }
    }
  }];
}