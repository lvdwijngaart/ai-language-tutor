

import 'package:ai_lang_tutor_v2/components/confirmation_dialogue.dart';
import 'package:ai_lang_tutor_v2/components/sentences/add_sentence_card.dart';
import 'package:ai_lang_tutor_v2/components/sentences/empty_state.dart';
import 'package:ai_lang_tutor_v2/components/sentences/loading_state.dart';
import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/database/collection.dart';
import 'package:ai_lang_tutor_v2/models/database/sentence.dart';
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/providers/collections_provider.dart';
import 'package:ai_lang_tutor_v2/services/ai_sentence_generation_service.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/sentences/collection_sentences_service.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/sentences/sentences_service.dart';
import 'package:ai_lang_tutor_v2/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AiSuggestionTab extends StatefulWidget {
  Collection collection;

  AiSuggestionTab({
    super.key, 
    required this.collection, 
  });

  @override
  State<AiSuggestionTab> createState() => _AiSuggestionTabState();
}

class _AiSuggestionTabState extends State<AiSuggestionTab> {
  List<Sentence> _suggestedSentences = [];
  List<Sentence> _selectedSentences = [];
  bool _isLoadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadSuggestions,
      color: AppColors.electricBlue,
      child: Column(
        children: [
          _buildSuggestionsHeader(),
          Expanded(
            child: _isLoadingSuggestions
              ? LoadingState(message: 'Loading suggested sentences...')
              : _suggestedSentences.isEmpty
                ? EmptyState(
                  icon: Icons.auto_awesome_outlined,
                  title: 'No suggestions available',
                  subtitle: 'Pull to refresh or try another method',
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _suggestedSentences.length,
                  itemBuilder: (context, index) {
                    Sentence sentence = _suggestedSentences[index];
                    bool isSelected = _selectedSentences.any((s) => 
                      _compareSentenceObjectWithoutId(sentence, s)
                    );

                    return SentenceCard(
                      sentence: _suggestedSentences[index], 
                      onTap: () => _toggleSentenceSelection(sentence),
                      isSelected: isSelected
                    );
                  },
                ),
          ),
          _buildBottomActions(_selectedSentences)
        ],
      ),
    );
  }

  
  Widget _buildSuggestionsHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.electricBlue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI-suggested sentences based on your collection topic and difficulty level',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoadingSuggestions ? null : _loadSuggestions,
                  icon: _isLoadingSuggestions 
                      ? SizedBox(
                          width: 16, 
                          height: 16, 
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.refresh),
                  label: Text(_isLoadingSuggestions ? 'Loading...' : 'Get New Suggestions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  
  Widget _buildBottomActions(List<Sentence> selectedSentences) {
    if (selectedSentences.isEmpty) return SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () {
              setState(() {
                selectedSentences.clear();
              });
            },
            child: Text('Clear Selection'),
          ),
          Spacer(),
          ElevatedButton.icon(
            onPressed: () => _addSelectedSentences(selectedSentences),
            icon: Icon(Icons.add),
            label: Text('Add ${selectedSentences.length} Sentences'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // HELPER METHODS

  void _toggleSentenceSelection(Sentence sentence) {
    setState(() {
      final existingIndex = _selectedSentences.indexWhere((s) => 
        _compareSentenceObjectWithoutId(sentence, s)
      );
      if (existingIndex >= 0) {
        _selectedSentences.removeAt(existingIndex);
      } else {
        _selectedSentences.add(sentence);
      }
    });
  }

  bool _compareSentenceObjectWithoutId(Sentence s1, Sentence s2) {
    return s1.text == s2.text && 
        s1.translation == s2.translation && 
        s1.clozeStartChar == s2.clozeStartChar && 
        s1.clozeEndChar == s2.clozeEndChar;
  }

  // API METHODS

  Future<void> _addSelectedSentences(List<Sentence> selectedSentences) async {
    if (selectedSentences.isEmpty) return;
    
    try {
      final insertedList = await SentencesService.insertSentenceList(sentences: selectedSentences);

      if (insertedList.isEmpty) {
        throw Exception('0 sentences were inserted. Something went wrong. ');
      }
      final insertedIds = insertedList.map((sentence) => sentence.id!).toList();

      final collectionProvider = Provider.of<CollectionsProvider>(context, listen: false);
      final collection = collectionProvider.selectedCollection!;

      final sentenceSaves = await CollectionSentencesService.addMultSentencesToCollection(sentenceIds: insertedIds, collectionId: collection.id!);

      if (!sentenceSaves) {
        throw Exception('Something went wrong during saving sentences to collection ${collection.id}');
      }

      // TODO: Add sentences to collections provider?

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('${selectedSentences.length} sentences added!'),
              ],
            ),
            backgroundColor: AppColors.successColor,
          ),
        );
        
        // Navigate back to collection
        context.pop('added');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add sentences: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
      logger.e('Error occurred during saving sentences to collection: $e');
    }
  }

  Future<void> _loadSuggestions() async {
    if (_selectedSentences.isNotEmpty) {
      final choice = await ConfirmationDialog.show(
        context: context,
        title: '${_selectedSentences.length} sentences selected', 
        message: 'Refreshing the page will de-select these sentences and they will not be added to the collection. Are you sure?',
        icon: Icons.question_mark_outlined,
        confirmText: 'Refresh',
        confirmColor: AppColors.electricBlue
      );
      if (choice == false) {      // User cancelled refresh
        return;
      } else {
        setState(() {
          _selectedSentences = [];
        });
      }
    }

    setState(() => _isLoadingSuggestions = true);
    
    try {
      List<Sentence> suggestedSentences = await AiSentenceGenerationService.getAIGeneratedSentences(
        collection: widget.collection,
        sentencesToPass: [
          Sentence(text: 'Se atrevió a contradecir al profesor durante la clase.', translation: 'translation', language: Language.spanish, clozeStartChar: 0, clozeEndChar: 10, createdAt: DateTime.now()), 
        ]   // TODO: Change to actual sentences
      );
      
      setState(() {
        _suggestedSentences = suggestedSentences;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load suggestions: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
      logger.e('Failed to load suggestions: ${e.toString()}');
      // TODO: If something went wrong, load standard sentences per language? 
    } finally {
      setState(() => _isLoadingSuggestions = false);
    }
  }

  List<Sentence> _generateMockSuggestions() {
    return List.generate(5, (index) => Sentence(
      id: 'suggestion_$index',
      text: 'Esta es una oración sugerida número ${index + 1}',
      translation: 'This is a suggested sentence number ${index + 1}',
      // clozeWord: 'oración',
      language: widget.collection.language,
      // collectionId: widget.collectionId,
      clozeStartChar: 10,
      clozeEndChar: 15,
      createdAt: DateTime.now(),
    ));
  }
}