import 'package:ai_lang_tutor_v2/components/confirmation_dialogue.dart';
import 'package:ai_lang_tutor_v2/components/sentences/cloze_preview_widget.dart';
import 'package:ai_lang_tutor_v2/components/sentences/cloze_selection_widget.dart';
import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/services/ai_sentence_generation_service.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/sentences/collection_sentences_service.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/sentences/sentences_service.dart';
import 'package:ai_lang_tutor_v2/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_lang_tutor_v2/models/database/collection.dart';
import 'package:ai_lang_tutor_v2/models/database/sentence.dart';
import 'package:ai_lang_tutor_v2/providers/collections_provider.dart';
import 'package:ai_lang_tutor_v2/providers/language_provider.dart';
import 'package:ai_lang_tutor_v2/services/supabase_client.dart';
import 'package:ai_lang_tutor_v2/utils/print_cloze_sentence.dart';

enum AddSentenceMode { suggestions, wordSearch, custom }

class AddSentencesScreen extends StatefulWidget {
  final String collectionId;
  final Collection collection;

  const AddSentencesScreen({Key? key, required this.collectionId, required this.collection}) : super(key: key);

  @override
  State<AddSentencesScreen> createState() => _AddSentencesScreenState();
}

class _AddSentencesScreenState extends State<AddSentencesScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Collection _collection;
  
  // Controller for Search mode
  final TextEditingController _wordSearchController = TextEditingController();

  // Controllers for Custom mode
  final TextEditingController _customSentenceController = TextEditingController();
  final TextEditingController _customTranslationController = TextEditingController();
  Sentence? _customSentence;
  
  // State management
  bool _isLoadingSuggestions = false;
  bool _isSearching = false;
  bool _isAddingCustom = false;
  List<Sentence> _suggestedSentences = [];
  List<Sentence> _searchResults = [];
  List<Sentence> _selectedSentences = [];
  String _searchWord = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCollectionData();
  }

  Future<void> _loadCollectionData() async {
    final provider = Provider.of<CollectionsProvider>(context, listen: false);
    if (provider.selectedCollection?.id == widget.collectionId) {
      _collection = provider.selectedCollection!;
    } else {
      // Load collection if not already loaded
      await provider.loadSingleCollection(widget.collectionId);
      _collection = provider.selectedCollection!;
    }
    
    // Auto-load suggestions when screen opens
    _loadSuggestions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _wordSearchController.dispose();
    _customSentenceController.dispose();
    _customTranslationController.dispose();
    // _customClozeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSuggestionsTab(),
                _buildWordSearchTab(),
                _buildCustomTab(),
              ],
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.darkBackground,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Sentences'),
          Text(
            _collection.title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        if (_selectedSentences.isNotEmpty)
          Container(
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.electricBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_selectedSentences.length} selected',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.darkBackground,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.electricBlue,
        unselectedLabelColor: Colors.white70,
        indicatorColor: AppColors.electricBlue,
        tabs: [
          Tab(
            icon: Icon(Icons.auto_awesome),
            text: 'Suggestions',
          ),
          Tab(
            icon: Icon(Icons.search),
            text: 'Word Search',
          ),
          Tab(
            icon: Icon(Icons.create),
            text: 'Custom',
          ),
        ],
      ),
    );
  }

  // SUGGESTIONS TAB
  Widget _buildSuggestionsTab() {
    return RefreshIndicator(
      onRefresh: _loadSuggestions,
      color: AppColors.electricBlue,
      child: Column(
        children: [
          _buildSuggestionsHeader(),
          Expanded(
            child: _isLoadingSuggestions
                ? _buildLoadingState('Loading suggested sentences...')
                : _suggestedSentences.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.auto_awesome_outlined,
                        title: 'No suggestions available',
                        subtitle: 'Pull to refresh or try another method',
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _suggestedSentences.length,
                        itemBuilder: (context, index) {
                          return _buildSentenceCard(_suggestedSentences[index]);
                        },
                      ),
          ),
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

  // WORD SEARCH TAB
  Widget _buildWordSearchTab() {
    return Column(
      children: [
        _buildWordSearchHeader(),
        Expanded(
          child: _isSearching
              ? _buildLoadingState('Searching for sentences...')
              : _searchResults.isEmpty && _searchWord.isNotEmpty
                  ? _buildEmptyState(
                      icon: Icons.search_off,
                      title: 'No sentences found',
                      subtitle: 'Try searching for a different word',
                    )
                  : _searchResults.isEmpty
                      ? _buildEmptyState(
                          icon: Icons.search,
                          title: 'Search for a word',
                          subtitle: 'Enter a word above to find sentences containing it',
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            return _buildSentenceCard(_searchResults[index]);
                          },
                        ),
        ),
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

  // CUSTOM TAB
  Widget _buildCustomTab() {
    return GestureDetector(
      onTap: () {
        // Unfocus any active text fields when tapping outside
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.create, color: AppColors.electricBlue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Create your own sentence for this collection',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            
            _buildCustomSentenceForm(),
          ],
        ),
      )
    );
  }

  Widget _buildCustomSentenceForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Original Sentence
        Text(
          'Sentence *',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _customSentenceController,
          style: TextStyle(color: Colors.white),
          maxLines: null,
          minLines: 2,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'Enter the sentence in ${_collection.language.displayName}...',
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
          ),
          onChanged: (value) => setState(() {
            // Reset sentence when text changes
            _customSentence = null;
          }),
        ),
        SizedBox(height: 20),

        // Translation
        Text(
          'Translation *',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _customTranslationController,
          style: TextStyle(color: Colors.white),
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Enter the English translation...',
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
          ),
          onChanged: (value) => setState(() {
            // Reset sentence when text changes
            if (_canAddCustomSentence()) {
              _customSentence = Sentence(
                text: _customSentence!.text, 
                translation: value, 
                language: _customSentence!.language, 
                clozeStartChar: _customSentence!.clozeStartChar, 
                clozeEndChar: _customSentence!.clozeEndChar, 
                createdAt: _customSentence!.createdAt
              );
            }
          }),
        ),
        SizedBox(height: 20),

        // Cloze Word
        Text(
          'Word to Hide (Cloze) *',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _customSentenceController, 
          builder: (context, value, child) {
            return ClozeSelectionWidget(
              key: ValueKey(value.text),
              text: _customSentenceController.text, 
              onSelectionChanged: (selection, words, startChar, endChar) {  
                setState(() {
                  if (selection.isNotEmpty && startChar != null && endChar != null) {
                    _customSentence = Sentence(
                      text: _customSentenceController.text, 
                      translation: _customTranslationController.text, 
                      language: _collection.language, 
                      clozeStartChar: startChar, 
                      clozeEndChar: endChar, 
                      createdAt: DateTime.now()
                    );
                  } else {
                    _customSentence = null;
                  }
                });
              }, 
              boxColor: AppColors.cardBackground
            );
          }
        ),
        SizedBox(height: 24),

        // Preview
        if (_canAddCustomSentence()) ...[
          Text(
            'Preview',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),

          // Preview Container
          ClozePreviewWidget(sentence: _customSentence!),
          SizedBox(height: 24),
        ],

        // Add Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _canAddCustomSentence() && !_isAddingCustom
                ? _addCustomSentence
                : null,
            icon: _isAddingCustom
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.add),
            label: Text(_isAddingCustom ? 'Adding...' : 'Add Sentence'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _canAddCustomSentence()
                  ? AppColors.secondaryAccent
                  : Colors.grey,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // SHARED COMPONENTS
  Widget _buildSentenceCard(Sentence sentence) {
    final isSelected = _selectedSentences.any((s) => compareSentenceObjectWithoutId(sentence, s));
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Card(
        color: isSelected 
            ? AppColors.electricBlue.withOpacity(0.1)
            : AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected 
                ? AppColors.electricBlue 
                : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: () => _toggleSentenceSelection(sentence),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: printClozeSentence(
                        sentence: sentence, 
                        showAsBlank: false
                      ),
                    ),
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleSentenceSelection(sentence),
                      activeColor: AppColors.electricBlue,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  sentence.translation,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        // 'Cloze: ${sentence.clozeWord}',
                        'Cloze: Cloze',
                        style: TextStyle(
                          color: AppColors.secondaryAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.electricBlue),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white38),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
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
            onPressed: _addSelectedSentences,
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
         compareSentenceObjectWithoutId(sentence, s)
      );
      if (existingIndex >= 0) {
        _selectedSentences.removeAt(existingIndex);
      } else {
        _selectedSentences.add(sentence);
      }
    });
  }

  bool _canAddCustomSentence() {
    return _customSentence != null && 
          _customSentenceController.text.isNotEmpty &&
          _customTranslationController.text.isNotEmpty; 
  }

  bool compareSentenceObjectWithoutId(Sentence s1, Sentence s2) {
    return s1.text == s2.text && 
        s1.translation == s2.translation && 
        s1.clozeStartChar == s2.clozeStartChar && 
        s1.clozeEndChar == s2.clozeEndChar;
  }

  // API METHODS (TODO: Implement these)
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
      }
    }

    setState(() => _isLoadingSuggestions = true);
    
    try {
      List<Sentence> suggestedSentences = await AiSentenceGenerationService.getAIGeneratedSentences(
        collection: widget.collection,
        sentencesToPass: [
          Sentence(text: 'Se atrevió a contradecir al profesor durante la clase.', translation: 'translation', language: Language.spanish, clozeStartChar: 0, clozeEndChar: 10, createdAt: DateTime.now()), 
        ]
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

  Future<void> _addCustomSentence() async {

    // Validate we have all required data
    if (_customSentence == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields and select cloze words'), backgroundColor: AppColors.errorColor),
      );
      return;
    }

    setState(() => _isAddingCustom = true);
    
    try {
      final newSentence = Sentence(
        text: _customSentenceController.text, 
        translation: _customTranslationController.text, 
        language: _collection.language, 
        clozeStartChar: _customSentence!.clozeStartChar, 
        clozeEndChar: _customSentence!.clozeEndChar, 
        createdAt: DateTime.now()
      );

      final Sentence insertedSentence = await SentencesService.insertSentence(
        sentence: newSentence
      );

      final success = await CollectionSentencesService.addSentenceToCollection(
        sentenceId: insertedSentence.id!, 
        collectionId: _collection.id!
      );

      if (!success) {
        throw Exception('Failed to add sentence to collection');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Sentence added successfully!'),
              ],
            ),
            backgroundColor: AppColors.secondaryAccent,
          ),
        );
        
        // Clear form
        _customSentenceController.clear();
        _customTranslationController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add sentence: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isAddingCustom = false);
    }
  }

  
  Future<void> _addSelectedSentences() async {
    if (_selectedSentences.isEmpty) return;
    
    try {
      final insertedList = await SentencesService.insertSentenceList(sentences: _selectedSentences);

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
                Text('${_selectedSentences.length} sentences added!'),
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

  // MOCK DATA GENERATORS (Remove when implementing real services)
  List<Sentence> _generateMockSuggestions() {
    return List.generate(5, (index) => Sentence(
      id: 'suggestion_$index',
      text: 'Esta es una oración sugerida número ${index + 1}',
      translation: 'This is a suggested sentence number ${index + 1}',
      // clozeWord: 'oración',
      language: _collection.language,
      // collectionId: widget.collectionId,
      clozeStartChar: 10,
      clozeEndChar: 15,
      createdAt: DateTime.now(),
    ));
  }

  List<Sentence> _generateMockSearchResults(String word) {
    return List.generate(3, (index) => Sentence(
      id: 'search_${word}_$index',
      text: 'Esta es una oración que contiene la palabra $word',
      translation: 'This is a sentence that contains the word $word',
      // clozeWord: word,
      language: _collection.language,
      // collectionId: widget.collectionId,
      clozeStartChar: 10,
      clozeEndChar: 15,
      createdAt: DateTime.now(),
    ));
  }

}