

import 'package:ai_lang_tutor_v2/components/chat/ai_avatar.dart';
import 'package:ai_lang_tutor_v2/components/chat/user_avatar.dart';
import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/other/chat_message.dart';
import 'package:flutter/material.dart';

abstract class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onAnalyze;
  final VoidCallback? onCopy;    // TODO
  final VoidCallback? onDelete;  // TODO: Want this?
  final bool showTimestamp;
  final bool isLastMessage;

  bool get shouldExpandWidth;
  bool hasTappableContent() => message.sentenceAnalyses?.isNotEmpty ?? false;

  const ChatBubble({
    super.key, 
    required this.message, 
    this.onAnalyze, 
    this.onCopy, 
    this.onDelete,  
    this.showTimestamp = true,
    this.isLastMessage = false, 
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: getMargin(),
      child: Row(
        mainAxisAlignment: message.isUserMessage
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          if (!message.isUserMessage) ...[
            AIAvatar()
          ],

          // Message bubble
          if (shouldExpandWidth) ...[
            Expanded(
              child: _buildBubbleContainer(context)
            )
          ] else ...[
            Flexible(child: _buildBubbleContainer(context)),
          ],

          if (message.isUserMessage) ...[
            UserAvatar()
          ]
        ],
      ),
    );
  }

  Widget _buildBubbleContainer(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      decoration: getBubbleDecoration(),
      padding: getBubblePadding(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message content
          buildMessageContent(),
          if (showTimestamp) ...[
            SizedBox(height: 4), 
            buildTimestamp(),
          ] 
        ],
      ),
    );
  }
  
  // Abstract method to be implemented by subclass
  Widget buildMessageContent();

  EdgeInsets getMargin() => EdgeInsets.all(16);
  
  EdgeInsets getBubblePadding() => EdgeInsets.symmetric(horizontal: 16, vertical: 12);

  CrossAxisAlignment getAlignment() {
    if (message.isUserMessage) {
      return CrossAxisAlignment.end;
    } else {
      return CrossAxisAlignment.start;
    }
  }

  BoxDecoration getBubbleDecoration() {
    if (message.isUserMessage) {
      return BoxDecoration(
        color: AppColors.electricBlue, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4, 
            offset: const Offset(0,2), 
          ), 
        ],
      );
    } else {
      return BoxDecoration(
        color: AppColors.cardBackground, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4, 
            offset: const Offset(0,2), 
          ), 
        ],
      );
    }
  }

  Widget buildTimestamp() {
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: Text(
        _formatTimestamp(message.timestamp), 
        style: TextStyle(
          color: Colors.white60, 
          fontSize: 12
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}