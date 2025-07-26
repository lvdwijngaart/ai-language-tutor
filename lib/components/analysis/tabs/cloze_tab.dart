

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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ClozeTab extends StatefulWidget {
  final SentenceAnalysis sentenceAnalysis;
  final Language language;

  const ClozeTab({
    super.key,
    required this.sentenceAnalysis,
    required this.language
  });

  @override
  State<ClozeTab> createState() => _ClozeTabState();
} 

class _ClozeTabState extends State<ClozeTab> {
  Sentence? _sentence;
  bool _isLoading = false;
  String? _error;
  String? _successMessage;
  
  @override
  void initState() {
    super.initState();
  }

  // TODO: Show success/error messages
  @override
  Widget build(BuildContext context) {
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
                _updateSentenceObject(selection, startChar, endChar);
              });
            }
          ),

          const SizedBox(height: 20),

          // Preview section
          if (_sentence != null) ...[
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
            ClozePreviewWidget(sentence: _sentence!),
            const SizedBox(height: 24),
          ],

          // 'Save' button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sentence == null
                  ? null
                  : _saveClozeExercise,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Saving...',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
                : Text(
                _sentence == null
                    ? 'Select words to save'
                    : 'Save to Collection',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.9),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Update sentence object with current selection
  void _updateSentenceObject(Set<int> selection, int? startChar, int? endChar) {
    if (selection.isEmpty || startChar == null || endChar == null) {
      _sentence = null;
      return;
    }

    _sentence = Sentence(
      text: widget.sentenceAnalysis.sentence, 
      translation: widget.sentenceAnalysis.translation, 
      language: widget.language, 
      clozeStartChar: startChar, 
      clozeEndChar: endChar, 
      createdAt: DateTime.now()
    );
  }
  
  void _saveClozeExercise() async {
    if (_sentence == null || _isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      // Show collection picker dialog
      final selectedCollection = await _showCollectionPickerDialog();

      if (selectedCollection != null) {
        // Insert the sentence into the database
        final Sentence createdSentence = await SentencesService.insertSentence(
          sentence: _sentence!,
        );

        // Link the sentence to the selected collection
        final success =
            await CollectionSentencesService.addSentenceToCollection(
              sentenceId: createdSentence.id!,
              collectionId: selectedCollection.id!,
            );

        setState(() {
          _isLoading = false;
          if (success) {
            _successMessage = 'Sentence saved to "${selectedCollection.title}" successfully!';
            _sentence = null;
          } else {
            _error = 'Failed to save sentence to collection. Please try again. ';
          }
        });

        if (success) {
          // Show success message
          _showSuccessDialog(selectedCollection.title);

          // Clear the selection
          setState(() {
            _sentence = null;
          });
        } else {
          _showErrorDialog('Failed to save sentence to collection');
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error saving sentence: ${e.toString()}';
      });
      _showErrorDialog('Error saving sentence: $e');
    }
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
            color: AppColors.electricBlue.withValues(alpha: 0.2),
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

  // TODO: Replace these for standardised: 

  
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