import 'package:ai_lang_tutor_v2/components/analysis/tabs/analysis_tab.dart';
import 'package:ai_lang_tutor_v2/components/analysis/tabs/cloze_tab.dart';
import 'package:ai_lang_tutor_v2/components/analysis/tabs/mistakes_tab.dart';
import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/models/other/sentence_analysis.dart';
import 'package:flutter/material.dart';

class SentenceAnalysisWidget extends StatefulWidget {
  final SentenceAnalysis sentenceAnalysis;
  final bool isUserMessage;
  final VoidCallback onClose;
  final Language language;

  const SentenceAnalysisWidget({
    super.key,
    required this.sentenceAnalysis,
    required this.isUserMessage,
    required this.onClose,
    required this.language,
  });

  @override
  State<SentenceAnalysisWidget> createState() => _SentenceAnalysisWidgetState();
}

class _SentenceAnalysisWidgetState extends State<SentenceAnalysisWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize any necessary data or state here
    _tabController = TabController(
      length: widget.isUserMessage ? 3 : 2,
      vsync: this,
    );

  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool mistakesExist = widget.sentenceAnalysis.mistakes != null;
    int? nrOfMistakes = widget.sentenceAnalysis.mistakes?.length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header with close button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.darkBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(
                  widget.isUserMessage ? Icons.person : Icons.smart_toy,
                  color: widget.isUserMessage
                      ? AppColors.electricBlue
                      : Colors.green,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isUserMessage
                            ? 'Your Message Analysis'
                            : 'AI Message Analysis',
                        style: AppTextStyles.heading3,
                      ),
                      Text(
                        'Level: ${'Not yet implemented'}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
          ),

          // Tab bar
          Container(
            color: AppColors.darkBackground,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.electricBlue,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: [
                const Tab(text: 'Analysis'),
                const Tab(text: 'Create Cloze'),
                if (widget.isUserMessage)
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Improvements${mistakesExist && (nrOfMistakes != null && nrOfMistakes > 0) ? ' (${nrOfMistakes.toString()})' : ''}',
                          style: TextStyle(
                            color:
                                mistakesExist &&
                                    (nrOfMistakes != null && nrOfMistakes > 0)
                                ? Colors.orange
                                : Colors.white70,
                            fontSize:
                                (mistakesExist &&
                                    (nrOfMistakes != null && nrOfMistakes > 0))
                                ? 12
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                AnalysisTab(sentenceAnalysis: widget.sentenceAnalysis),
                ClozeTab(sentenceAnalysis: widget.sentenceAnalysis, language: widget.language),
                if (widget.isUserMessage) MistakesTab(sentenceAnalysis: widget.sentenceAnalysis),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
