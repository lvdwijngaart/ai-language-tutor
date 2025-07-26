

import 'package:ai_lang_tutor_v2/components/chat/chat_bubbles/chat_bubble.dart';
import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/other/chat_message.dart';
import 'package:ai_lang_tutor_v2/models/other/sentence_analysis.dart';
import 'package:ai_lang_tutor_v2/utils/chat_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class AIMessageChatBubble extends ChatBubble {
  final Function(SentenceAnalysis, ChatMessage) onSentenceTap;

  const AIMessageChatBubble({
    super.key,
    required super.message,
    required this.onSentenceTap,
    super.showTimestamp = true 
  });

  @override
  bool get shouldExpandWidth => true;

  @override
  Widget buildMessageContent() {
    return Column(
      children: [
        if (hasTappableContent()) ...[
          buildTappableContent(message, onSentenceTap)
        ] else ...[
          Text(message.text, 
            style: TextStyle(
              color: Colors.white, 
              fontSize: 16, 
              height: 1.4
            ),
          ),
        ],
      ]
    );
  }
  
}