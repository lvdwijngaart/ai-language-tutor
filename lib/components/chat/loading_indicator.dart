

import 'package:ai_lang_tutor_v2/components/chat/ai_avatar.dart';
import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI avatar
          AIAvatar(), 

          // Loading bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), 
              decoration: BoxDecoration(
                color: AppColors.cardBackground, 
                borderRadius: BorderRadius.circular(20), 
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4, 
                    offset: const Offset(0,2), 
                  ), 
                ],
              ), 
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16, 
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.electricBlue
                      ),
                    ),
                  ),
                  const SizedBox(width: 8), 
                  Text(
                    'AI is thinking', 
                    style: TextStyle(
                      color: Colors.white70, 
                      fontSize: 14
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}