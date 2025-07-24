import 'package:ai_lang_tutor_v2/components/sentences/cloze_preview_widget.dart';
import 'package:ai_lang_tutor_v2/components/sentences/cloze_selection_widget.dart';
import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/database/collection.dart';
import 'package:ai_lang_tutor_v2/models/database/sentence.dart';
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/models/other/sentence_analysis.dart';
import 'package:ai_lang_tutor_v2/providers/collections_provider.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/sentences/collection_sentences_service.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/sentences/sentences_service.dart';
import 'package:ai_lang_tutor_v2/utils/print_cloze_sentence.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Enum for word states
enum WordState {
  unselected, // Grey - not selectable
  selectable, // Lighter - can be selected to extend range
  selected, // Blue - currently selected
}

class SentenceAnalysisWidget extends StatefulWidget {
  final SentenceAnalysis sentenceAnalysis;
  final bool isUserMessage;
  final VoidCallback onClose;
  final Function(String)? onSaveToCloze; // TODO: String = special class?
  final Language language;

  const SentenceAnalysisWidget({
    super.key,
    required this.sentenceAnalysis,
    required this.isUserMessage,
    required this.onClose,
    required this.language,
    this.onSaveToCloze,
  });

  @override
  State<SentenceAnalysisWidget> createState() => _SentenceAnalysisWidgetState();
}

class _SentenceAnalysisWidgetState extends State<SentenceAnalysisWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Set to keep track of selected words for Cloze functionality
  Set<int> _selectedWordIndices = {};
  List<String> _words = [];
  Sentence? sentence;

  @override
  void initState() {
    super.initState();
    // Initialize any necessary data or state here
    _tabController = TabController(
      length: widget.isUserMessage ? 3 : 2,
      vsync: this,
    );

    // Clean up words (remove punctuation and empty strings)
    _words = widget.sentenceAnalysis.sentence
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .map(
          (word) => word.replaceAll(RegExp(r'[^\w\s]'), ''),
        ) // Remove punctuation
        .where((word) => word.isNotEmpty)
        .toList();
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
                _buildAnalysisTab(),
                _buildClozeTab(),
                if (widget.isUserMessage) _buildImprovementsTab(),
              ],
            ),
          ),
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
              border: Border.all(color: const Color(0xFF3A3A3A)),
            ),
            child: Text(
              widget.sentenceAnalysis.sentence,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),

          const SizedBox(height: 20),

          // TODO: Build sections
          _buildSection(
            title: 'Meaning in Context',
            icon: Icons.lightbulb_outline,
            color: Colors.orange,
            child: Text(widget.sentenceAnalysis.contextualMeaning),
          ),

          if (widget.sentenceAnalysis.keyTerms.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSection(
              title: 'Key terms',
              icon: Icons.book,
              color: Colors.blue,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.sentenceAnalysis.keyTerms
                      .map((def) => _buildKeyTerm(def))
                      .toList(),
                ),
              ),
            ),
          ],

          if (widget.sentenceAnalysis.alternatives.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSection(
              title: 'Alternative Expressions',
              icon: Icons.swap_horiz,
              color: Colors.green,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.sentenceAnalysis.alternatives
                    .map(
                      (alt) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
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
          ClozeSelectionWidget(
            text: widget.sentenceAnalysis.sentence, 
            onSelectionChanged: (selection, words, startChar, endChar) {
              setState(() {
                _selectedWordIndices = selection;
                _words = words;
                _updateSentenceObject(startChar, endChar);
              });
            }
          ),

          const SizedBox(height: 20),

          // Preview section
          if (sentence != null) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Text(
                'Preview:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Preview Container
            ClozePreviewWidget(sentence: sentence!),
            const SizedBox(height: 24),
          ],

          // 'Save' button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedWordIndices.isEmpty
                  ? null
                  : _saveClozeExercise,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _selectedWordIndices.isEmpty
                    ? 'Select words to save'
                    : 'Save to Collection',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
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
          if (widget.sentenceAnalysis.mistakes != null &&
              widget.sentenceAnalysis.mistakes!.isEmpty) ...[
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
            ...widget.sentenceAnalysis.mistakes!
                .map((mistake) => _buildImprovementSuggestion(mistake))
                .toList(),
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

  Widget _buildImprovementSuggestion(Mistake mistake) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
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

  void _saveClozeExercise() async {
    if (sentence == null) return;

    try {
      // Show collection picker dialog
      final selectedCollection = await _showCollectionPickerDialog();

      if (selectedCollection != null) {
        // Show loading indicator
        _showLoadingDialog();

        // Insert the sentence into the database
        final Sentence createdSentence = await SentencesService.insertSentence(
          sentence: sentence!,
        );

        // Link the sentence to the selected collection
        final success =
            await CollectionSentencesService.addSentenceToCollection(
              sentenceId: createdSentence.id!,
              collectionId: selectedCollection.id!,
            );

        // Hide loading indicator
        Navigator.of(context).pop();

        if (success) {
          // Show success message
          _showSuccessDialog(selectedCollection.title);

          // Clear the selection
          setState(() {
            _selectedWordIndices.clear();
            sentence = null;
          });
        } else {
          _showErrorDialog('Failed to save sentence to collection');
        }
      }
    } catch (e) {
      // Hide loading indicator if it's showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      _showErrorDialog('Error saving sentence: $e');
    }
  }

  // Update sentence object with current selection
  void _updateSentenceObject(int? startChar, int? endChar) {
    if (_selectedWordIndices.isEmpty || startChar == null || endChar == null) {
      sentence = null;
      return;
    }

    sentence = Sentence(
      text: widget.sentenceAnalysis.sentence, 
      translation: widget.sentenceAnalysis.translation, 
      language: widget.language, 
      clozeStartChar: startChar, 
      clozeEndChar: endChar, 
      createdAt: DateTime.now()
    );
  }

  // Build cloze preview
  Widget _buildClozePreview() {
    if (sentence == null) return SizedBox.shrink();

    return printClozeSentence(sentence: sentence!, showAsBlank: true);
  }

  // Show collection picker dialog
  Future<Collection?> _showCollectionPickerDialog() async {
    return showDialog<Collection>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(color: AppColors.cardBackground),
                    child: Row(
                      children: [
                        Icon(
                          Icons.collections_bookmark,
                          color: AppColors.electricBlue,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Choose Collection',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Collections list
                  Expanded(
                    child: Consumer<CollectionsProvider>(
                      builder: (context, provider, child) {
                        if (provider.isLoadingPersonal) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: AppColors.electricBlue,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Loading collections...',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          );
                        }

                        if (provider.personalError != null) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Error loading collections',
                                  style: TextStyle(color: Colors.red),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  provider.personalError!,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (provider.personalCollections.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.collections_bookmark_outlined,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No collections found',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Create a collection first to save sentences',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: provider.personalCollections.length,
                          itemBuilder: (context, index) {
                            final collection =
                                provider.personalCollections[index];
                            return _buildCollectionTile(collection);
                          },
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 16),

                  // Create new collection button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement create new collection
                        Navigator.of(context).pop();
                        _showCreateCollectionDialog();
                      },
                      icon: Icon(Icons.add, color: AppColors.electricBlue),
                      label: Text(
                        'Create New Collection',
                        style: TextStyle(color: AppColors.electricBlue),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.electricBlue),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Build collection tile for selection
  Widget _buildCollectionTile(Collection collection) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        tileColor: AppColors.darkBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.white12),
        ),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.electricBlue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            collection.icon ?? Icons.star,
            color: AppColors.electricBlue,
            size: 20,
          ),
        ),
        title: Text(
          collection.title,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (collection.description?.isNotEmpty == true) ...[
              SizedBox(height: 4),
              Text(
                collection.description!,
                style: TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: 4),
            Text(
              '${collection.nrOfSentences} sentences',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.white38,
          size: 16,
        ),
        onTap: () {
          Navigator.of(context).pop(collection);
        },
      ),
    );
  }

  // Show loading dialog
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.cardBackground,
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.electricBlue),
                SizedBox(height: 16),
                Text(
                  'Saving sentence...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show success dialog
  void _showSuccessDialog(String collectionTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.cardBackground,
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 16),
                Text(
                  'Success!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Sentence saved to "$collectionTitle"',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text('OK', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.cardBackground,
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  'Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text('OK', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show create collection dialog (placeholder)
  void _showCreateCollectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.cardBackground,
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info, color: AppColors.electricBlue, size: 48),
                SizedBox(height: 16),
                Text(
                  'Coming Soon',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Creating new collections from here will be available in a future update.',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricBlue,
                    ),
                    child: Text('OK', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
