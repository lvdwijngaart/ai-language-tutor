

import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/database/sentence.dart';
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/models/other/chat_message.dart';
import 'package:ai_lang_tutor_v2/models/other/sentence_analysis.dart';
import 'package:ai_lang_tutor_v2/utils/print_cloze_sentence.dart';
import 'package:flutter/material.dart';


// Enum for word states
enum WordState {
  unselected,    // Grey - not selectable
  selectable,    // Lighter - can be selected to extend range
  selected,      // Blue - currently selected
}

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
  Sentence? sentence;
  
  // Add these properties to your state class
  int? _selectionStart;
  int? _selectionEnd;



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
                if (widget.isUserMessage)
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Improvements${mistakesExist && (nrOfMistakes != null && nrOfMistakes > 0) ? ' (${nrOfMistakes.toString()})' : ''}', 
                          style: TextStyle(
                            color: mistakesExist && (nrOfMistakes != null && nrOfMistakes > 0) ? Colors.orange : Colors.white70, 
                            fontSize: (mistakesExist && (nrOfMistakes != null && nrOfMistakes > 0)) ? 12 : null ),
                        ),
                      ],
                    ),
                  )
              ]
            ),
          ), 

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAnalysisTab(), 
                _buildClozeTab(),
                if (widget.isUserMessage) _buildImprovementsTab(),
              ]
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAnalysisTab() {
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
          _buildSection(
            title: 'Meaning in Context', 
            icon: Icons.lightbulb_outline, 
            color: Colors.orange, 
            child: Text(widget.sentenceAnalysis.contextualMeaning)
          ), 

          if (widget.sentenceAnalysis.keyTerms.isNotEmpty) ...[
            const SizedBox(height: 20,), 
            _buildSection(
              title: 'Key terms', 
              icon: Icons.book, 
              color: Colors.blue, 
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.sentenceAnalysis.keyTerms.map((def) => 
                    _buildKeyTerm(def)
                  ).toList(),
                ),
              ),
            )
          ], 

          if (widget.sentenceAnalysis.alternatives.isNotEmpty) ...[
            const SizedBox(height: 20,), 
            _buildSection(
              title: 'Alternative Expressions', 
              icon: Icons.swap_horiz, 
              color: Colors.green, 
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.sentenceAnalysis.alternatives.map((alt) => 
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(16), 
                      border: Border.all(color: Colors.green.withOpacity(0.3))
                    ),
                    child: Text(
                      alt, 
                      style: const TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),
                ).toList(),
              )
            )
          ]
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
                
                WordState wordState = _getWordState(index);

                return GestureDetector(
                  onTap: () => _handleWordTap(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getWordBackgroundColor(wordState), 
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _getWordBorderColor(wordState)
                      )
                    ),
                    child: Text(
                      word, 
                      style: TextStyle(
                        color: _getWordTextColor(wordState), 
                        fontWeight: wordState == WordState.selected
                            ? FontWeight.bold
                            : FontWeight.normal
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
                  Center(
                    // Cloze sentence
                    child: _buildClozePreview(),
                  ),
                  // printClozeSentence(sentence: sentence!, _selectedWordIndices),
                  
                  // Translation sentence   
                  Container(
                    child: Center(
                      child: Text(
                        widget.sentenceAnalysis.translation,
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.sentenceAnalysis.mistakes != null && widget.sentenceAnalysis.mistakes!.isEmpty) ...[
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.thumb_up, 
                    color: Colors.green,
                    size: 48,
                  ), 
                  const SizedBox(height: 16,), 
                  const Text(
                    'Great job!', 
                    style: TextStyle(
                      color: Colors.green, 
                      fontSize: 18, 
                      fontWeight: FontWeight.bold
                    ),
                  ), 
                  const Text(
                    'No improvements needed for this sentence.', 
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  )
                ],
              ),
            )
          ] else ...[
            const Text(
              'Suggestions for improvement: ',
              style: TextStyle(
                color: Colors.white, 
                fontSize: 16, 
                fontWeight: FontWeight.bold,
              ), 
            ), 
            const SizedBox(height: 16,), 
            ...widget.sentenceAnalysis.mistakes!.map((mistake) => 
              _buildImprovementSuggestion(mistake)
            ).toList(),
          ]
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title, 
    required IconData icon, 
    required Color color, 
    required Widget child
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8,), 
            Text(
              title, 
              style: TextStyle(
                color: color, 
                fontSize: 14, 
                fontWeight: FontWeight.bold
              ),
            )
          ],
        ), 
        const SizedBox(height: 8,), 
        child
      ],
    );
  }

  Widget _buildKeyTerm(KeyTerm term) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(8), 
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            term.termText, // term
            style: const TextStyle(
              color: Colors.blue, 
              fontWeight: FontWeight.bold, 
              fontSize: 16
            ),
          ),
          const SizedBox(height: 4,), 
          Text(
            term.definition, // definition
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 8,),
          Text(
            term.contextualMeaning,  // Contextual meaning
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ), 
          if (term.examples != null && term.examples!.isNotEmpty) ...[
            const SizedBox(height: 8,), 
            ...term.examples!.map((example) => Padding(
              padding: const EdgeInsets.only(top: 4), 
              child: Text(
                '• $example', 
                style: const TextStyle(
                  color: Colors.white60, 
                  fontSize: 12, 
                  fontStyle: FontStyle.italic
                ),
              ),
            ))
          ]
        ],
      ),
    );
  }

  Widget _buildImprovementSuggestion(Mistake mistake) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(4), 
        border: Border.all(color: Colors.orange.withOpacity(0.3))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          // Row(
          //   children: [
          //     Container(
          //       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          //       decoration: BoxDecoration(
          //         color: Colors.orange, 
          //         borderRadius: BorderRadius.circular(4)
          //       ),
          //       child: Text(
          //         mistake.type.displayName.toUpperCase(), 
          //         style: const TextStyle(
          //           color: Colors.white, 
          //           fontSize: 10, 
          //           fontWeight: FontWeight.bold
          //         ),
          //       ),
          //     )
          //   ],
          // ), 

          // const SizedBox(height: 8,), 
          
          //
          Row(
            children: [
              Text(
                '"${mistake.error}"', 
                style: const TextStyle(
                  color: Colors.orange, 
                  fontWeight: FontWeight.bold
                ), 
              ),
              Text(
                ' → ',
                style: TextStyle(color: Colors.white70),
              ), 
              Text(
                '"${mistake.correction}"', 
                style: TextStyle(
                  color: Colors.green, 
                  fontWeight: FontWeight.bold
                ),
              )
            ],
          ), 

          const SizedBox(height: 4,), 
          Text(
            mistake.explanation, 
            style: TextStyle(color: Colors.white70, fontSize: 12),
          )
        ],
      ),
    );
  }

  void _saveClozeExercise() {
    // TODO: Implement

    
  }


  // ✅ Determine the state of each word
  WordState _getWordState(int index) {
    if (_selectedWordIndices.isEmpty) {
      // No selection yet - all words are selectable
      return WordState.selectable;
    }
    
    if (_selectedWordIndices.contains(index)) {
      return WordState.selected;
    }
    
    // Determine selection bounds
    int minSelected = _selectedWordIndices.reduce((a, b) => a < b ? a : b);
    int maxSelected = _selectedWordIndices.reduce((a, b) => a > b ? a : b);
    
    // Word is selectable if it's adjacent to the current selection
    if (index == minSelected - 1 || index == maxSelected + 1) {
      return WordState.selectable;
    }
    
    return WordState.unselected;
  }

  // ✅ Handle word tap with contiguous selection logic
  void _handleWordTap(int index) {
    setState(() {
      if (_selectedWordIndices.isEmpty) {
        // First selection
        _selectedWordIndices.add(index);
        _selectionStart = index;
        _selectionEnd = index;
      } else if (_selectedWordIndices.contains(index)) {
        // Clicking on selected word - remove it and adjust selection
        _removeWordFromSelection(index);
      } else {
        // Extending selection
        _extendSelection(index);
      }
      
      // Update the sentence object
      _updateSentenceObject();
    });
  }

  // ✅ Remove a word from selection (maintaining contiguity)
  void _removeWordFromSelection(int index) {
    int minSelected = _selectedWordIndices.reduce((a, b) => a < b ? a : b);
    int maxSelected = _selectedWordIndices.reduce((a, b) => a > b ? a : b);
    
    if (index == minSelected) {
      // Removing from start
      _selectedWordIndices.remove(index);
      if (_selectedWordIndices.isNotEmpty) {
        _selectionStart = _selectedWordIndices.reduce((a, b) => a < b ? a : b);
      }
    } else if (index == maxSelected) {
      // Removing from end
      _selectedWordIndices.remove(index);
      if (_selectedWordIndices.isNotEmpty) {
        _selectionEnd = _selectedWordIndices.reduce((a, b) => a > b ? a : b);
      }
    } else {
      // Removing from middle - this would break contiguity, so don't allow it
      // Or split the selection - for simplicity, let's clear and restart
      _selectedWordIndices.clear();
      _selectionStart = null;
      _selectionEnd = null;
    }
    
    if (_selectedWordIndices.isEmpty) {
      _selectionStart = null;
      _selectionEnd = null;
    }
  }

  // ✅ Extend selection to include new word
  void _extendSelection(int index) {
    int minSelected = _selectedWordIndices.reduce((a, b) => a < b ? a : b);
    int maxSelected = _selectedWordIndices.reduce((a, b) => a > b ? a : b);
    
    if (index == minSelected - 1) {
      // Extending to the left
      _selectedWordIndices.add(index);
      _selectionStart = index;
    } else if (index == maxSelected + 1) {
      // Extending to the right
      _selectedWordIndices.add(index);
      _selectionEnd = index;
    }
    // Ignore clicks on non-adjacent words
  }

  // ✅ Color methods
  Color _getWordBackgroundColor(WordState state) {
    switch (state) {
      case WordState.selected:
        return AppColors.electricBlue;
      case WordState.selectable:
        return AppColors.cardBackground.withOpacity(0.8);
      case WordState.unselected:
        return AppColors.cardBackground.withOpacity(0.3);
    }
  }

  Color _getWordBorderColor(WordState state) {
    switch (state) {
      case WordState.selected:
        return AppColors.electricBlue;
      case WordState.selectable:
        return Colors.white38;
      case WordState.unselected:
        return Colors.white12;
    }
  }

  Color _getWordTextColor(WordState state) {
    switch (state) {
      case WordState.selected:
        return Colors.white;
      case WordState.selectable:
        return Colors.white70;
      case WordState.unselected:
        return Colors.white30;
    }
  }

  // ✅ Update sentence object with current selection
  void _updateSentenceObject() {
    if (_selectedWordIndices.isEmpty) {
      sentence = null;
      return;
    }
    
    // Calculate character positions
    int startChar = 0;
    int endChar = 0;
    
    // Find the start character position
    int minIndex = _selectedWordIndices.reduce((a, b) => a < b ? a : b);
    int maxIndex = _selectedWordIndices.reduce((a, b) => a > b ? a : b);
    
    for (int i = 0; i < minIndex; i++) {
      startChar += _words[i].length + 1; // +1 for space
    }
    
    endChar = startChar;
    for (int i = minIndex; i <= maxIndex; i++) {
      endChar += _words[i].length;
      if (i < maxIndex) endChar += 1; // +1 for space between words
    }
    
    sentence = Sentence(
      text: widget.sentenceAnalysis.sentence,
      translation: widget.sentenceAnalysis.translation,
      clozeStartChar: startChar,
      clozeEndChar: endChar,
      language: Language.spanish, // You'll need to get this from context
      createdAt: DateTime.now(),
    );
  }

  // ✅ Build cloze preview
  Widget _buildClozePreview() {
    if (sentence == null) return SizedBox.shrink();
    
    return printClozeSentence(sentence: sentence!, showAsBlank: true);
  }

}
