

import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/database/sentence.dart';
import 'package:ai_lang_tutor_v2/utils/print_cloze_sentence.dart';
import 'package:flutter/material.dart';

class ClozePreviewWidget extends StatelessWidget {
  final Sentence sentence;
  final Color backGroundColor;

  ClozePreviewWidget({
    required this.sentence,
    this.backGroundColor = AppColors.darkBackground
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white30),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                // Cloze sentence
                child: printClozeSentence(sentence: sentence!, showAsBlank: true),
                // child: _buildClozePreview(),
              ),

              // Translation sentence
              Container(
                child: Center(
                  child: Text(
                    sentence!.translation,
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ]
    );
  } 


}