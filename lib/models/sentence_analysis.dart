

import 'package:flutter/material.dart';

class SentenceAnalysis {
  final String sentence;
  final List<String> keyTerms;
  final List<String> alternatives;
  final String contextualMeaning;

  // final VoidCallback? onSentenceTap;

  SentenceAnalysis({
    required this.sentence, 
    this.keyTerms = const [], 
    this.alternatives = const [],
    required this.contextualMeaning,
    // this.onSentenceTap
  });

  

}