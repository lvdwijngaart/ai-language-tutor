

import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:flutter/material.dart';

Widget printClozeSentence(List<String> words, Set<int> selectedWordIndices) {

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
              color: AppColors.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          );
        }

        return TextSpan(
          text: '$word ',
          style: const TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.normal,
            fontSize: 16,
          ),
        );
      }).toList(),
    ),
  );
}
