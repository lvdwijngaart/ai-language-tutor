

import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:flutter/material.dart';

class AIAvatar extends StatelessWidget {
  const AIAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32, 
      height: 32, 
      margin: const EdgeInsets.only(right: 12, top: 4), 
      decoration: BoxDecoration(
        color: AppColors.electricBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.psychology, 
        color: Colors.white,
        size: 18,
      )
    );
  }
}