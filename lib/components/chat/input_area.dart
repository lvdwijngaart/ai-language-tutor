

import 'package:ai_lang_tutor_v2/components/chat/live_transcript_indicator.dart';
import 'package:ai_lang_tutor_v2/components/chat/microphone_button.dart';
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
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, -2)
              )
            ]
          ),
          child: Row(
            children: [
              // Speech toggle button
              MicrophoneButton(
                speechEnabled: speechEnabled,
                isListening: isListening,
                onToggleSpeech: onToggleSpeech,
                onForceReinitializeSpeech: onForceReinitializeSpeech,
              ), 

              Expanded(
                child: TextField(
                  controller: messageController,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.5),
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
}