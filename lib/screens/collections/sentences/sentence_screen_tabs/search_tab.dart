

import 'package:ai_lang_tutor_v2/components/sentences/add_sentence_card.dart';
import 'package:ai_lang_tutor_v2/components/sentences/empty_state.dart';
import 'package:ai_lang_tutor_v2/components/sentences/loading_state.dart';
import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/database/collection.dart';
import 'package:ai_lang_tutor_v2/models/database/sentence.dart';
import 'package:ai_lang_tutor_v2/providers/collections_provider.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/sentences/collection_sentences_service.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/sentences/sentences_service.dart';
import 'package:ai_lang_tutor_v2/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SearchTab extends StatefulWidget {
  Collection collection;

  SearchTab({
    super.key, 
    required this.collection, 
  });

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  List<Sentence> _searchResults = [];
  List<Sentence> _selectedSentences = [];
  
  // Controller for Search mode
  final TextEditingController _wordSearchController = TextEditingController();
  String _searchWord = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    _wordSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildWordSearchHeader(),
        Expanded(
          child: _isSearching
            ? LoadingState(message: 'Searching for sentences...')
            : _searchResults.isEmpty && _searchWord.isNotEmpty
              ? EmptyState(
                  icon: Icons.search_off,
                  title: 'No sentences found',
                  subtitle: 'Try searching for a different word',
                )
              : _searchResults.isEmpty
                ? EmptyState(
                    icon: Icons.search,
                    title: 'Search for a word',
                    subtitle: 'Enter a word above to find sentences containing it',
                  )
                : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final sentence = _searchResults[index];
                    final isSelected = _selectedSentences.any((s) => 
                      _compareSentenceObjectWithoutId(sentence, s)
                    );

                    return SentenceCard(
                      sentence: _searchResults[index], 
                      onTap: () => _toggleSentenceSelection(sentence),
                      isSelected: isSelected,
                    );
                  },
                ),
        ),
        _buildBottomActions(),
      ],
    );
  }

  Widget _buildWordSearchHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.search, color: AppColors.electricBlue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Search for sentences containing a specific word',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _wordSearchController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter a word to search for...',
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.electricBlue),
                    ),
                    suffixIcon: _wordSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.white70),
                            onPressed: () {
                              _wordSearchController.clear();
                              setState(() {
                                _searchResults.clear();
                                _searchWord = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() {}),
                  onSubmitted: (_) => _searchForWord(),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: _wordSearchController.text.isNotEmpty && !_isSearching
                    ? _searchForWord
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.all(16),
                ),
                child: _isSearching
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.search),
              ),
            ],
          ),
        ],
      ),
    );
  }

  
  Widget _buildBottomActions() {
    if (_selectedSentences.isEmpty) return SizedBox.shrink();
    
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
                _selectedSentences.clear();
              });
            },
            child: Text('Clear Selection'),
          ),
          Spacer(),
          ElevatedButton.icon(
            onPressed: () => _addSelectedSentences(_selectedSentences),
            icon: Icon(Icons.add),
            label: Text('Add ${_selectedSentences.length} Sentences'),
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
  Future<void> _searchForWord() async {
    final word = _wordSearchController.text.trim();
    if (word.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchWord = word;
    });
    
    try {
      // TODO: Call your search service
      // final results = await SentenceSearchService.searchByWord(
      //   word: word,
      //   language: _collection.language,
      //   limit: 20,
      // );
      
      // Mock data for now
      await Future.delayed(Duration(seconds: 1));
      setState(() {
        _searchResults = _generateMockSearchResults(word);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isSearching = false);
    }    
  }

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

  List<Sentence> _generateMockSearchResults(String word) {
    return List.generate(3, (index) => Sentence(
      text: 'Esta es una oración que contiene la palabra $word',
      translation: 'This is a sentence that contains the word $word',
      // clozeWord: word,
      language: widget.collection.language,
      // collectionId: widget.collectionId,
      clozeStartChar: 10,
      clozeEndChar: 15,
      createdAt: DateTime.now(),
    ));
  }

}