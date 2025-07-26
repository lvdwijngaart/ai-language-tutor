

import 'package:ai_lang_tutor_v2/models/other/sentence_analysis.dart';
import 'package:flutter/material.dart';

class MistakesTab extends StatelessWidget {
  final SentenceAnalysis sentenceAnalysis;

  const MistakesTab({
    super.key, 
    required this.sentenceAnalysis
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sentenceAnalysis.mistakes != null &&
              sentenceAnalysis.mistakes!.isEmpty) ...[
            Center(
              child: Column(
                children: [
                  Icon(Icons.thumb_up, color: Colors.green, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Great job!',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'No improvements needed for this sentence.',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else ...[
            const Text(
              'Suggestions for improvement: ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...sentenceAnalysis.mistakes!
                .map((mistake) => _buildImprovementSuggestion(mistake)),
          ],
        ],
      ),
    );
  }

  // Build container showcasing the mistake made
  Widget _buildImprovementSuggestion(Mistake mistake) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error → Correction section with overflow detection
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate approximate text widths
              final errorText = '"${mistake.error}"';
              final correctionText = '"${mistake.correction}"';
              final arrowText = ' → ';

              // Rough estimate: each character is about 8 pixels
              final estimatedWidth =
                  (errorText.length +
                      correctionText.length +
                      arrowText.length) *
                  10.0;

              // If estimated width exceeds available space, use Column
              if (estimatedWidth > constraints.maxWidth) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      errorText,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('↓', style: TextStyle(color: Colors.white70)),
                    Text(
                      correctionText,
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              } else {
                // Use Row with Flexible widgets
                return Row(
                  children: [
                    Flexible(
                      child: Text(
                        errorText,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(arrowText, style: TextStyle(color: Colors.white70)),
                    Flexible(
                      child: Text(
                        correctionText,
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 4),
          Text(
            mistake.explanation,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}