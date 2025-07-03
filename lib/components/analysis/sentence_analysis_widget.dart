

import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/chat_message.dart';
import 'package:ai_lang_tutor_v2/models/sentence_analysis.dart';
import 'package:ai_lang_tutor_v2/utils/print_cloze_sentence.dart';
import 'package:flutter/material.dart';

class SentenceAnalysisWidget extends StatefulWidget {
  final SentenceAnalysis sentenceAnalysis;
  final bool isUserMessage;
  final VoidCallback onClose;
  final Function(String)? onSaveToCloze; // TODO: String = special class?

  const SentenceAnalysisWidget({
    super.key,
    required this.sentenceAnalysis,
    required this.isUserMessage,
    required this.onClose,
    this.onSaveToCloze,
  });

  @override
  State<SentenceAnalysisWidget> createState() => _SentenceAnalysisWidgetState();
}

class _SentenceAnalysisWidgetState extends State<SentenceAnalysisWidget> 
    with SingleTickerProviderStateMixin{

  late TabController _tabController;
  // Set to keep track of selected words for Cloze functionality
  Set<int> _selectedWordIndices = {};
  List<String> _words = [];


  @override
  void initState() {
    super.initState();
    // Initialize any necessary data or state here
    _tabController = TabController(
      length: widget.isUserMessage ? 3 : 2, 
      vsync: this
    );
    // TODO: Make sure punctuation is not kept in the words
    _words = widget.sentenceAnalysis.sentence.split(' ');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  color: widget.isUserMessage ? AppColors.electricBlue : Colors.green,
                ), 
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isUserMessage ? 'Your Message Analysis' : 'AI Message Analysis', 
                        style: AppTextStyles.heading3,
                      ), 
                      Text(
                        'Level: ${'Not yet implemented'}',
                        style: const TextStyle(
                          color: Colors.white60, 
                          fontSize: 12,
                        ),
                      )
                    ],
                  )
                ),

                IconButton(
                  onPressed: widget.onClose, 
                  icon: const Icon(Icons.close, color: Colors.white70)
                ),
              ],
            )
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
                if (widget.isUserMessage) const Tab(text: 'Improvements',)
              ]
            ),
          ), 

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TODO: Build tab widgets
                _buildAnalysisTab(), 
                _buildClozeTab()
              ]
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16), 
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
              border: Border.all(color: const Color(0xFF3A3A3A))
            ),
            child: Text(
              widget.sentenceAnalysis.sentence, 
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 16
              ),
            ),
          ),

          const SizedBox(height: 20,),

          // TODO: Build sections
        ],
      ),
    );
  }

  Widget _buildClozeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select words to create a cloze exercise: ',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 16),

          // Word Selection section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkBackground, 
              borderRadius: BorderRadius.circular(12)
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _words.asMap().entries.map((entry) {
                int index = entry.key;
                String word = entry.value;
                bool isSelected = _selectedWordIndices.contains(index);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedWordIndices.remove(index);
                      } else {
                        _selectedWordIndices.add(index);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? AppColors.electricBlue
                        : AppColors.cardBackground, 
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected 
                          ? AppColors.electricBlue
                          : const Color(0xFF3A3A3A)
                      )
                    ),
                    child: Text(
                      word, 
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70, 
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                      ),
                    ),
                  ),
                );
              }).toList(), 
            ),
          ),

          const SizedBox(height: 20),

          // Preview section
          if (_selectedWordIndices.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10) ,
              child: Text(
                'Preview:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Cloze sentence
                  printClozeSentence(_words, _selectedWordIndices),
                  
                  // Add more widgets here as needed
                  // Translation sentence   
                  Container(
                    child: Center(
                      child: Text(
                        // TODO: Replace this with translation
                        widget.sentenceAnalysis.contextualMeaning,
                      ),
                    ),
                  )
                ],
              ),    
            ), 

            
          ],

          const SizedBox(height: 24,),

          // 'Save' button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedWordIndices.isEmpty ? null : _saveClozeExercise, 
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successColor, 
                padding: const EdgeInsets.symmetric(vertical: 16), 
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                )
              ),
              child: Text(
                _selectedWordIndices.isEmpty 
                  ? 'Select words to save'
                  : 'Save to Collection',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.9), 
                  fontWeight: FontWeight.bold
                ),
              )
            ),
          )
        ],
      ),
    );
  }

  Widget _buildImprovementsTab() {
    

    return Container(
      
    );
  }

  void _saveClozeExercise() {
    // TODO: Implement
  }
}