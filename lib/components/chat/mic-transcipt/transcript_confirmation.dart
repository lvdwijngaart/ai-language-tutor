

import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:flutter/material.dart';

class TranscriptConfirmationDialog extends StatelessWidget {
  // TODO: Possibly add the analysis result here
  final String transcript;
  final VoidCallback onSend;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const TranscriptConfirmationDialog({
    super.key, 
    required this.transcript,
    required this.onSend, 
    required this.onRetry, 
    required this.onCancel
  });

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            Icons.mic, 
            color: AppColors.electricBlue,
            size: 24,
          ), 
          const SizedBox(width: 8,), 
          const Text(
            'Confirm Message', 
            style: TextStyle(
              color: Colors.white, 
              fontSize: 18, 
              fontWeight: FontWeight.w600
            ),
          )
        ]
      ),
      
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'I heard: ', 
            style: TextStyle(
              color: Colors.white70, 
              fontSize: 14, 
            ),
          ), 
          const SizedBox(height: 8,),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3A), 
              borderRadius: BorderRadius.circular(8), 
              border: Border.all(color: AppColors.electricBlue.withOpacity(0.3), width: 1), 
            ),
            child: Text(
              transcript, 
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 16, 
                height: 1.4
              ),
            ),
          ), 
          SizedBox(height: 16,), 
          Text(
            'Send this message?', 
            style: TextStyle(
              color: Colors.white.withOpacity(0.8), 
              fontSize: 14
            ),
          )
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel, 
          child: Text(
            'Cancel', 
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16
            ),
          )
        ), 
        TextButton(
          onPressed: onRetry, 
          child: Text(
            'Try Again', 
            style: TextStyle(
              color: AppColors.secondaryAccent, 
              fontSize: 16, 
              fontWeight: FontWeight.w500
            ),
          )
        ), 
        ElevatedButton(
          onPressed: onSend, 
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.electricBlue, 
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ), 
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), 
          ),
          child: Text(
            'Send', 
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w500
            ),
          )
        )
      ],
    );
  }

} 