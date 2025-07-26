

import 'package:flutter/material.dart';

class LiveTranscriptIndicator extends StatelessWidget {
  final bool isListening;
  final String currentTranscript;

  const LiveTranscriptIndicator({
    super.key,
    required this.isListening,
    required this.currentTranscript,
  });

  @override
  Widget build(BuildContext context) {
    // If not listening, return an empty container
    if (!isListening) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withValues(alpha: 0.1),
            Colors.red.withValues(alpha: 0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.red.withValues(alpha: 0.3), 
            width: 2,
          ),
        ),
      ), 
      child: Row(
        children: [
          // Animated recording indicator
          Container(
            width: 12, 
            height: 12,
            decoration: BoxDecoration(
              color: Colors.red, 
              borderRadius: BorderRadius.circular(6),
            ),
          ), 
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Listening...', 
                      style: TextStyle(
                        color: Colors.red, 
                        fontWeight: FontWeight.w600, 
                        fontSize: 14,
                      ),
                    ), 
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 12, 
                      height: 12, 
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade700),
                      ),
                    )
                  ],
                ),

                // Display current transcript if available
                if (currentTranscript.isNotEmpty) ...[
                  const SizedBox(height: 4), 
                  Text(
                    '"$currentTranscript"',
                    style: TextStyle(
                      color: Colors.red.shade600, 
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                ],
              ],
            )
          )
        ],
      ),
    );
  }
}