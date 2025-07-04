

import 'package:ai_lang_tutor_v2/components/chat/user_avatar.dart';
import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:flutter/material.dart';

class LiveTranscriptPreview extends StatelessWidget{
  final String currentTranscript;

  const LiveTranscriptPreview({
    super.key, 
    required this.currentTranscript, 
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live transcript bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.electricBlue.withOpacity(0.7), 
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.red.withOpacity(0.5),
                  width: 2,
                ), 
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.2), 
                    blurRadius: 8, 
                    offset: const Offset(0, 2)
                  )
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, 
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ), 
                      const SizedBox(width: 6),
                      Text(
                        ' Listening...', 
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12, 
                          fontWeight: FontWeight.w500,
                        )
                      ),
                    ],
                  ), 

                  if (currentTranscript.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      currentTranscript,
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 16, 
                        height: 1.4
                      ),
                    )
                  ], 

                  if (currentTranscript.isEmpty) ...[
                    const SizedBox(height: 8,), 
                    Text(
                      'Start speaking...', 
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8), 
                        fontSize: 16, 
                        fontStyle: FontStyle.italic, 
                      ),
                    )
                  ],
                ]
              ),
            )
          ), 

          // User avatar placed on the right of message bubble
          UserAvatar(),
        ],
      ),
    );
  }
}