
  import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/other/chat_message.dart';
import 'package:ai_lang_tutor_v2/models/other/sentence_analysis.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

Widget buildTappableContent(ChatMessage message, Function(SentenceAnalysis, ChatMessage) onSentenceTap) {
 
  // If there are sentence analyses, build tappable sentences
  // Create a list to hold TextSpans for each sentence
  List<TextSpan> sentenceSpans = [];

  for (int i = 0; i < message.sentenceAnalyses!.length; i++) {
    final analysis = message.sentenceAnalyses![i];
    final sentence = analysis.sentence.trim();
    if (sentence.isEmpty) continue; // Skip empty sentences

    sentenceSpans.add(
      TextSpan(
        text: sentence, 
        style: TextStyle(
          color: message.isUserMessage 
              ? Colors.white
              : AppColors.primaryText,
          fontSize: 16, 
          height: 1.4, 
          backgroundColor: Colors.white.withValues(alpha: 0.1), 
          decoration: TextDecoration.underline, 
          decorationColor: Colors.white.withValues(alpha: 0.15), 
          decorationStyle: TextDecorationStyle.dotted
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => onSentenceTap(message.sentenceAnalyses![i], message)
      ), 
    );

    // Add a space after each sentence except the last one
    if (i < message.sentenceAnalyses!.length - 1) {
      sentenceSpans.add(
        TextSpan(
          text: '  ', // Add space between sentences
          style: TextStyle(
            color: message.isUserMessage 
                ? Colors.white 
                : AppColors.primaryText, 
            fontSize: 16, 
            height: 1.4,
          ),
        ),
      );
    }
  }

  return RichText(
    text: TextSpan(children: sentenceSpans),
  );
}