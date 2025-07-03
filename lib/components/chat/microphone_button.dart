

import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:flutter/material.dart';

class MicrophoneButton extends StatelessWidget{

  final bool speechEnabled;
  final bool isListening;
  final VoidCallback onToggleSpeech;
  final VoidCallback? onForceReinitializeSpeech;

  const MicrophoneButton({
    super.key,
    required this.speechEnabled,
    required this.isListening,
    required this.onToggleSpeech,
    this.onForceReinitializeSpeech,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,        
        children: [
          IconButton(
            onPressed: speechEnabled 
              ? onToggleSpeech
              : onForceReinitializeSpeech ?? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Speech recognition is not available.'),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }, 
            icon: Icon(
              speechEnabled
                ? (isListening ? Icons.mic : Icons.mic_none)
                : Icons.mic_off, 
              color: speechEnabled
                ? (isListening ? Colors.red : AppColors.electricBlue)
                : Colors.grey,
            ),
            style: IconButton.styleFrom(
              backgroundColor: speechEnabled
                ? (isListening 
                    ? Colors.red.withOpacity(0.2)
                    : AppColors.electricBlue.withOpacity(0.2)
                  )
                : Colors.grey.withOpacity(0.2),
              padding: const EdgeInsets.all(12), 
            ),
          ), 

          // Debug setup button (only show when speech is disabled)
          if (!speechEnabled && onForceReinitializeSpeech != null) ...[
            Container(
              margin: const EdgeInsets.only(left: 4), 
              child: IconButton(
                onPressed: onForceReinitializeSpeech,
                icon: const Icon(Icons.settings),
                tooltip: 'Setup Speech Recognition',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}