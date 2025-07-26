

import 'package:ai_lang_tutor_v2/components/chat/live_transcript_indicator.dart';
import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:flutter/material.dart';

class ChatInputArea extends StatelessWidget {
  final TextEditingController messageController;
  final bool speechEnabled;
  final bool isListening;
  final String currentTranscript;
  
  final VoidCallback onSendMessage;
  final VoidCallback onToggleSpeech;
  final VoidCallback? onForceReinitializeSpeech;

  const ChatInputArea({
    super.key,
    required this.messageController,
    required this.speechEnabled,
    required this.isListening,
    required this.currentTranscript,
    required this.onSendMessage,
    required this.onToggleSpeech,
    this.onForceReinitializeSpeech,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Microphone/transcription indicator
        LiveTranscriptIndicator(
          isListening: isListening,
          currentTranscript: currentTranscript,
        ), 

        // Input Area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground, 
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, -2)
              )
            ]
          ),
          child: Row(
            children: [
              // Speech toggle button
              _buildMicrophoneButton(context), 

              Expanded(
                child: TextField(
                  controller: messageController,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none, 
                    ), 
                    fillColor: AppColors.inputBackground, 
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), 
                  ),
                  onSubmitted: (_) => onSendMessage(),
                ), 
              ),

              // Send button
              Container(
                margin: const EdgeInsets.only(left: 12), 
                child: IconButton(
                  onPressed: onSendMessage,
                  icon: const Icon(Icons.send, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.electricBlue, 
                    padding: const EdgeInsets.all(12), 
                  ), 
                ),
              )
            ],
          ),
        ), 
      ],
    );
  }

  Widget _buildMicrophoneButton(BuildContext context) {
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
                    ? Colors.red.withValues(alpha: 0.2)
                    : AppColors.electricBlue.withValues(alpha: 0.2)
                  )
                : Colors.grey.withValues(alpha: 0.2),
              padding: const EdgeInsets.all(12), 
            ),
          ), 

          // Debug setup button (only show when speech is disabled)
          // if (!speechEnabled && onForceReinitializeSpeech != null) ...[
          //   Container(
          //     margin: const EdgeInsets.only(left: 4), 
          //     child: IconButton(
          //       onPressed: onForceReinitializeSpeech,
          //       icon: const Icon(Icons.settings),
          //       tooltip: 'Setup Speech Recognition',
          //       style: IconButton.styleFrom(
          //         backgroundColor: Colors.grey.withValues(alpha: 0.2),
          //         padding: const EdgeInsets.all(12),
          //       ),
          //     ),
          //   ),
          // ]
        ],
      ),
    );
  }
}