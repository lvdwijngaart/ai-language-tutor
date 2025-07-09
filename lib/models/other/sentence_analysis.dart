import 'package:flutter/material.dart';
import 'dart:convert';

class SentenceAnalysis {
  final String sentence;
  final String translation;
  final List<KeyTerm> keyTerms;
  final List<String> alternatives;
  final String contextualMeaning;
  final List<Mistake>? mistakes;

  // final VoidCallback? onSentenceTap;

  SentenceAnalysis({
    required this.sentence, 
    required this.translation,
    this.keyTerms = const [], 
    this.alternatives = const [],
    required this.contextualMeaning,
    this.mistakes,
    // this.onSentenceTap
  });

  // factory
  factory SentenceAnalysis.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing SentenceAnalysis: ${json.keys}');
    
    try {
      // Parse keyTerms
      List<KeyTerm> keyTerms = [];
      if (json['keyTerms'] is List) {
        final keyTermsList = json['keyTerms'] as List;
        print('🔍 Found ${keyTermsList.length} keyTerms');
        
        for (var item in keyTermsList) {
          if (item is Map<String, dynamic>) {
            keyTerms.add(KeyTerm.fromJson(item));
          } else if (item is String) {
            print('⚠️ Converting string keyTerm: $item');
            keyTerms.add(KeyTerm(
              termText: item,
              definition: 'Definition needed',
              contextualMeaning: 'Context needed'
            ));
          } else {
            print('❌ Invalid keyTerm type: ${item.runtimeType}');
          }
        }
      }

      // Parse alternatives
      List<String> alternatives = [];
      if (json['alternatives'] is List) {
        alternatives = (json['alternatives'] as List)
            .map((e) => e.toString())
            .toList();
      }

      // Parse mistakes
      List<Mistake>? mistakes;
      if (json['mistakes'] is List) {
        mistakes = (json['mistakes'] as List)
            .where((m) => m is Map<String, dynamic>)
            .map((m) => Mistake.fromJson(m))
            .toList();
      }

      final result = SentenceAnalysis(
        sentence: json['sentence']?.toString() ?? '',
        translation: json['translation']?.toString() ?? '',
        keyTerms: keyTerms,
        alternatives: alternatives,
        contextualMeaning: json['contextualMeaning']?.toString() ?? '',
        mistakes: mistakes,
      );

      print('✅ Created SentenceAnalysis with ${keyTerms.length} keyTerms');
      return result;
      
    } catch (e) {
      print('❌ SentenceAnalysis parsing failed: $e');
      print('📄 Input: ${jsonEncode(json)}');
      rethrow;
    }
  }

}

class Mistake {
  final String error;
  final String correction;
  final String explanation;

  Mistake({
    required this.error, 
    required this.correction, 
    required this.explanation
  });

  factory Mistake.fromJson(Map<String, dynamic> json) => 
    Mistake(
      error: json['error']?.toString() ?? '',
      correction: json['correction']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
    );
}

class KeyTerm {
  final String termText;
  final String definition;
  final String contextualMeaning;
  final List<String>? examples;

  KeyTerm({
    required this.termText, 
    required this.definition, 
    required this.contextualMeaning,
    this.examples
  });

  factory KeyTerm.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing KeyTerm: ${json['termText']}');
    
    List<String>? examples;
    if (json['examples'] is List) {
      examples = (json['examples'] as List).map((e) => e.toString()).toList();
    }

    return KeyTerm(
      termText: json['termText']?.toString() ?? '', 
      definition: json['definition']?.toString() ?? '', 
      contextualMeaning: json['contextualMeaning']?.toString() ?? '', 
      examples: examples
    );
  }
}