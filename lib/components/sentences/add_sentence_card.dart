

import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/database/sentence.dart';
import 'package:ai_lang_tutor_v2/utils/print_cloze_sentence.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SentenceCard extends StatelessWidget {
  final Sentence sentence;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showCheckbox;

  const SentenceCard({
    Key? key, 
    required this.sentence, 
    required this.isSelected, 
    required this.onTap, 
    this.showCheckbox = true
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Card(
        color: isSelected 
            ? AppColors.electricBlue.withValues(alpha: 0.1)
            : AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected 
                ? AppColors.electricBlue 
                : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: printClozeSentence(
                        sentence: sentence, 
                        showAsBlank: false
                      ),
                    ),
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => onTap,
                      activeColor: AppColors.electricBlue,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  sentence.translation,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        // 'Cloze: ${sentence.clozeWord}',
                        'Cloze: Cloze',
                        style: TextStyle(
                          color: AppColors.secondaryAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}