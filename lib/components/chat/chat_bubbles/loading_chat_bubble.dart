

import 'package:ai_lang_tutor_v2/components/chat/chat_bubbles/chat_bubble.dart';
import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/other/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';


class LoadingChatBubble extends ChatBubble {

  LoadingChatBubble({
    super.key, 
    super.showTimestamp = false
  }) : super( 
        message: ChatMessage(
          text: 'AI is thinking...', 
          isUserMessage: false, 
          timestamp: DateTime.now()
        ),
      );

  @override
  bool get shouldExpandWidth => false;


  @override
  Widget buildMessageContent() {
    return Row(
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
          message.text, 
          style: TextStyle(
            color: Colors.white70, 
            fontSize: 14, 
            fontStyle: FontStyle.italic
          ),
        ),  
      ],
    );
  }

}