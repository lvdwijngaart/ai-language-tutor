

import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/database/sentence.dart';
import 'package:flutter/material.dart';

Widget printClozeSentenceOmittingCloze(List<String> words, Set<int> selectedWordIndices) {

  return RichText(
    text: TextSpan(
      children: words.asMap().entries.map((entry) {
        int index = entry.key;
        String word = entry.value;
        bool isSelected = selectedWordIndices.contains(index);
        bool isFollowedBySelected = selectedWordIndices.contains(index + 1);

        if (isSelected) {
          return TextSpan(
            text: '_' * word.length + (isFollowedBySelected ? '_' : ' '),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          );
        }

        return TextSpan(
          text: '$word ',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.normal,
            fontSize: 16,
          ),
        );
      }).toList(),
    ),
  );
}

Widget printClozeSentence({required Sentence sentence, required bool showAsBlank}) {
  // Handle edge cases
  if (sentence.clozeStartChar < 0 || 
      sentence.clozeEndChar < 0 || 
      sentence.clozeStartChar >= sentence.clozeEndChar ||
      sentence.clozeEndChar > sentence.text.length) {
    // If invalid cloze range, just return the original text
    return RichText(
      text: TextSpan(
        text: sentence.text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.normal,
          fontSize: 16,
        ),
      ),
    );
  }

  // Split text into parts
  final String beforeCloze = sentence.text.substring(0, sentence.clozeStartChar);
  final String clozeText = sentence.text.substring(sentence.clozeStartChar, sentence.clozeEndChar);
  final String afterCloze = sentence.text.substring(sentence.clozeEndChar);

  return RichText(
    text: TextSpan(
      children: [
        // Text before the cloze
        if (beforeCloze.isNotEmpty)
          TextSpan(
            text: beforeCloze,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
          ),
        
        // The cloze (underlined text instead of underscores)
        
        TextSpan(
          text: showAsBlank 
              ? '_'*clozeText.length
              : clozeText,
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold,
            fontSize: 16,
            decoration: TextDecoration.underline,
            decorationColor: Colors.white,
            decorationThickness: 2.0, 
          ),
        ),
        
        // Text after the cloze
        if (afterCloze.isNotEmpty)
          TextSpan(
            text: afterCloze,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
          ),
      ],
    ),
  );
}