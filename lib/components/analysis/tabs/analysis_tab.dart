

import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/other/sentence_analysis.dart';
import 'package:flutter/material.dart';

class AnalysisTab extends StatelessWidget {
  final SentenceAnalysis sentenceAnalysis;

  const AnalysisTab({
    super.key,
    required this.sentenceAnalysis
  });


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3A3A3A)),
            ),
            child: Text(
              sentenceAnalysis.sentence,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: 'Meaning in Context',
            icon: Icons.lightbulb_outline,
            color: Colors.orange,
            child: Text(sentenceAnalysis.contextualMeaning),
          ),

          if (sentenceAnalysis.keyTerms.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSection(
              title: 'Key terms',
              icon: Icons.book,
              color: Colors.blue,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sentenceAnalysis.keyTerms
                      .map((def) => _buildKeyTerm(def))
                      .toList(),
                ),
              ),
            ),
          ],

          if (sentenceAnalysis.alternatives.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSection(
              title: 'Alternative Expressions',
              icon: Icons.swap_horiz,
              color: Colors.green,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sentenceAnalysis.alternatives
                    .map(
                      (alt) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          alt,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildKeyTerm(KeyTerm term) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            term.termText, // term
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            term.definition, // definition
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            term.contextualMeaning, // Contextual meaning
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (term.examples != null && term.examples!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...term.examples!.map(
              (example) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '• $example',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}