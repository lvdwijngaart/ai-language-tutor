

import 'dart:convert';

import 'package:ai_lang_tutor_v2/models/database/collection.dart';
import 'package:ai_lang_tutor_v2/models/database/sentence.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/sentences/sentences_service.dart';
import 'package:ai_lang_tutor_v2/utils/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiSentenceGenerationService {

  static const String _openaiApiUrl = 'https://api.openai.com/v1/chat/completions';
  static final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  static Future<List<Sentence>> getAIGeneratedSentences({
    required Collection collection,
    required List<Sentence> sentencesToPass,
    int nrOfSentences = 10
  }) async {

    // Get sentences in Collection to give AI guidelines
    final sentences = await SentencesService.getSentencesByCollectionId(collectionId: collection.id!, limit: 10);
    
    String prompt = _generatePrompt(collection, sentences, nrOfSentences);
    logger.i(prompt);

    final response = await sendAPIRequest(prompt);

    logger.w(jsonDecode(response.body)); 
    List<Sentence> parsedResponse = _parseAPIResponse(response, collection);

    return parsedResponse;
  }

  // TODO: Still sometimes does not include the cloze word
  static String _generatePrompt( Collection collection, List<Sentence> sentences, int nrOfSentences) {
    final bool isEmptyArray = sentences.isEmpty;

    String prompt;
    if (isEmptyArray) {
      prompt = """
        You are to propose sentences to add to a collection meant for learning learning ${collection.language.displayName}. 
        Collections name: ${collection.title}. ${collection.description != null ? 'Description: ${collection.description}' : ''}
        Each sentence should include an important word, which can be used as cloze word. 
        Please generate $nrOfSentences new sentences with important words which can be used as cloze words to help the user practice vocab that fits this collection.

        Important: The cloze word should not be left out of the sentence text, but should be provided seperate at the key 'cloze_word'. 
      """;
    } else {
      prompt = """
        You are to propose sentences to add to a collection meant for learning ${collection.language.displayName}. 
        Collections name: ${collection.title}. ${collection.description != null ? 'Description: ${collection.description}' : ''}
        Here are some example sentences from a user's vocabulary collection, where each sentence includes an important word, which can be used as cloze word. 
        Based on the style and difficulty of these sentences, please generate $nrOfSentences new sentences with important words which can be used as cloze words to help the user practice similar vocabulary.

        IMPORTANT: the disclosure of the cloze word in the example sentence is only so you know what the important word is in the sentence. You should not include this in your sentences. 

        Sentences: \n
      """; 

      // Add each sentence to the prompt as a guide for the AI
      for (var sentence in sentences) {
        final String clozeText = sentence.text.substring(sentence.clozeStartChar, sentence.clozeEndChar);

        prompt += '- ${sentence.text} (cloze word: $clozeText)';
      }
    }

    return prompt;
  }

  static sendAPIRequest(String prompt) async {
    final messages = <Map<String, String>>[];
    messages.add({
      'role': 'system', 
      'content': prompt
    });

    try {
      final response = await http.post(
        Uri.parse(_openaiApiUrl), 
        headers: {
          'Content-type': 'application/json', 
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
              'type': "function", 
              "function": {
                "name": "cloze_sentences",
                "description": "Generate cloze-deletion sentences from given texts with specified word character positions and translations. The interval between start and end characters should be referring to the cloze word. ",
                "strict": true,
                "parameters": {
                  "type": "object",
                  "properties": {
                    "sentences": {
                      "type": "array",
                      "description": "Array of sentences to create cloze deletions for.",
                      "items": {
                        "type": "object",
                        "properties": {
                          "sentence": {
                            "type": "string",
                            "description": "Full sentence which includes an important word. Only include the full sentence here, and include every word"
                          },
                          "translation": {
                            "type": "string",
                            "description": "Translation of the sentence."
                          },
                          "cloze_word": {
                            "type": "string",
                            "description": "The most important, or 'cloze', word or part of the sentence."
                          },
                          // TODO: Include what type of word the cloze word is
                        },
                        "required": [
                          "sentence",
                          "translation",
                          "cloze_word"
                        ],
                        "additionalProperties": false
                      }
                    }
                  },
                  "required": [
                    "sentences"
                  ],
                  "additionalProperties": false
                }
              }
            }
            // {
            //   'type': "function",
            //   'function': {
            //     'name': "cloze_sentences",
            //     'description': '',
            //     'parameters': {
            //       'type': "object",
            //       'properties': {
            //         'sentences': {
            //           'type': "array",
            //           'items': {
            //             'type': "object",
            //             'properties': {
            //               'sentence': { 'type': "string", 'description': 'Full sentence which includes an important word. Do not leave any words blank' },
            //               'translation': { 'type': "string" },
            //               'startClozeChar': { 'type': "integer", 'description': 'The start character of the cloze word' },
            //               'endClozeChar': { 'type': "integer", 'description': 'The start character of the cloze word' }
            //             },
            //             'required': ["sentence", "translation", "startClozeChar", "endClozeChar"],
            //           }
            //         }
            //       },
            //       'required': ["sentences"],
            //     },
            //   }
            // }
          ], 
          'tool_choice': {
            'type': 'function', 
            'function': {
              'name': 'cloze_sentences'
            }
          }
        })
      );

      return response;
    } catch (e) {
      throw Exception('Something went wrong: $e');
    }
  }

  static List<Sentence> _parseAPIResponse(http.Response response, Collection collection) {

    try {
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choice = data['choices'][0];
        final message = choice['message'];

        final toolCalls = message['tool_calls'];
        if (toolCalls == null || toolCalls.isEmpty) {
          throw Exception('No tool calls found in response');
        }

        final functionCall = toolCalls[0]['function'];
        final arguments = functionCall['arguments'];

        final functionData = jsonDecode(arguments);
        final List<dynamic> sentencesJson = functionData['sentences'];
        return sentencesJson.map<Sentence>(
          (json) {
            // Find the start and end indices of the cloze word in the sentence
            final clozeWord = json['cloze_word'];
            final sentenceText = json['sentence'];
            final startClozeChar = sentenceText.indexOf(clozeWord);
            final endClozeChar = startClozeChar + clozeWord.length;

            return Sentence.fromMap({
              'text': json['sentence'],
              'translation': json['translation'],
              'cloze_start_char': startClozeChar,
              'cloze_end_char': endClozeChar,
              'language': collection.language.name,
              'created_at': DateTime.now().toIso8601String()
            });
          }).toList();
      } else {
        final error = jsonDecode(response.body)['error']['message'];
        throw Exception('The response was not successful: $error');
        // TODO: Show error details
      }
    } catch (e) {
      throw Exception('Something went wrong: $e');
    }

  }

}