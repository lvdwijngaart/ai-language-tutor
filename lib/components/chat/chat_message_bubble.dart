

import 'package:ai_lang_tutor_v2/components/chat/ai_avatar.dart';
import 'package:ai_lang_tutor_v2/components/chat/user_avatar.dart';
import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/chat_message.dart';
import 'package:ai_lang_tutor_v2/models/sentence_analysis.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(SentenceAnalysis, ChatMessage) onSentenceTap;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.onSentenceTap,
  });

  // Format timestamp to a readable string
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hr ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }

  // Build tappable content for sentences
  Widget _buildTappableContent() {
    // If there are no sentence analyses, 
    if (message.sentenceAnalyses == null || message.sentenceAnalyses!.isEmpty) {
      return Text(
        message.text, 
        style: TextStyle(
          color: message.isUserMessage 
              ? Colors.white 
              : AppColors.primaryText, 
          fontSize: 16, 
        ),
      );
    }

    // If there are sentence analyses, build tappable sentences
    if (message.sentenceAnalyses != null && message.sentenceAnalyses!.isNotEmpty) {

    }

    // Create a list to hold TextSpans for each sentence
    List<TextSpan> sentenceSpans = [];

    for (int i = 0; i < message.sentenceAnalyses!.length; i++) {
      final analysis = message.sentenceAnalyses![i];
      final sentence = analysis.sentence.trim();
      if (sentence.isEmpty) continue; // Skip empty sentences

      sentenceSpans.add(
        TextSpan(
          text: sentence, 
          style: TextStyle(
            color: message.isUserMessage 
                ? Colors.white
                : AppColors.primaryText,
            fontSize: 16, 
            height: 1.4, 
            backgroundColor: Colors.white.withOpacity(0.1), 
            decoration: TextDecoration.underline, 
            decorationColor: Colors.white.withOpacity(0.15), 
            decorationStyle: TextDecorationStyle.dotted
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => onSentenceTap(message.sentenceAnalyses![i], message)
        ), 
      );

      // Add a space after each sentence except the last one
      if (i < message.sentenceAnalyses!.length - 1) {
        sentenceSpans.add(
          TextSpan(
            text: '  ', // Add space between sentences
            style: TextStyle(
              color: message.isUserMessage 
                  ? Colors.white 
                  : AppColors.primaryText, 
              fontSize: 16, 
              height: 1.4,
            ),
          ),
        );
      }
    }

    return RichText(
      text: TextSpan(children: sentenceSpans),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium), 
      child: Row(
        mainAxisAlignment: message.isUserMessage 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [

          // AI avatar placed on the left of message bubble
          if (!message.isUserMessage) AIAvatar(),

          // Message Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), 
              decoration: BoxDecoration(
                color: message.isUserMessage 
                    ? AppColors.electricBlue 
                    : AppColors.cardBackground, 
                borderRadius: BorderRadius.circular(20), 
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4, 
                    offset: const Offset(0,2), 
                  ), 
                ],
              ), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  // Render tappable sentences
                  _buildTappableContent(), 
                  const SizedBox(height: 4), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      Text(
                        _formatTime(message.timestamp), 
                        style: TextStyle(
                          color: message.isUserMessage 
                              ? Colors.white.withOpacity(0.7) 
                              : Colors.white.withOpacity(0.5), 
                          fontSize: 12, 
                        ),
                      ), 
                      if (message.sentenceAnalyses != null) ...[
                        Icon(
                          Icons.touch_app, 
                          size: 16, 
                          color: Colors.white.withOpacity(0.4),
                        )
                      ], 
                    ],
                  )
                ],
              ),
            ),
          ),

          // User avatar on the right side
          if (message.isUserMessage) UserAvatar(),

        ],
      ),
    );
  }
}