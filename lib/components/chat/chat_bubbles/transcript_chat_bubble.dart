

import 'package:ai_lang_tutor_v2/components/chat/chat_bubbles/chat_bubble.dart';
import 'package:ai_lang_tutor_v2/models/other/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class TranscriptChatBubble extends ChatBubble {
  final String currentTranscript;

  TranscriptChatBubble({
    super.key, 
    required this.currentTranscript,
    super.showTimestamp = false
  }) : super(
        message: ChatMessage(
          text: 'text', 
          isUserMessage: true
        )
      );

  @override
  bool get shouldExpandWidth => false;

  @override
  Widget buildMessageContent() {
    return Column(
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
                color: Colors.white.withValues(alpha: 0.8),
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
              color: Colors.white.withValues(alpha: 0.8), 
              fontSize: 16, 
              fontStyle: FontStyle.italic, 
            ),
          )
        ],
      ]
    );
  }

}