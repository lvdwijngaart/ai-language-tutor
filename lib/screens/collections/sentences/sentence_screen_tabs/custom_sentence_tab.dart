

import 'package:ai_lang_tutor_v2/components/sentences/cloze_preview_widget.dart';
import 'package:ai_lang_tutor_v2/components/sentences/cloze_selection_widget.dart';
import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/database/collection.dart';
import 'package:ai_lang_tutor_v2/models/database/sentence.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/sentences/collection_sentences_service.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/sentences/sentences_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// TODO: Use this for edit screen?
class CustomSentenceTab extends StatefulWidget {
  final Collection collection;

  const CustomSentenceTab({
    super.key, 
    required this.collection
  });

  @override
  State<CustomSentenceTab> createState() => _CustomSentenceTabState();
}

class _CustomSentenceTabState extends State<CustomSentenceTab> {
  final TextEditingController _customSentenceController = TextEditingController();
  final TextEditingController _customTranslationController = TextEditingController();
  Sentence? _customSentence;

  bool _isAddingCustom = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _customSentenceController.dispose();
    _customTranslationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            hintText: 'Enter the sentence in ${widget.collection.language.displayName}...',
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
                      language: widget.collection.language, 
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

  // HELPER METHODS
  bool _canAddCustomSentence() {
    return _customSentence != null && 
          _customSentenceController.text.isNotEmpty &&
          _customTranslationController.text.isNotEmpty; 
  }

  // API METHODS (TODO: Implement these)
  Future<void> _addCustomSentence() async {

    // Validate we have all required data
    if (_customSentence == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in all required fields and select cloze words'
          ), 
          backgroundColor: AppColors.errorColor
        ),
      );
      return;
    }

    setState(() => _isAddingCustom = true);
    
    try {
      final newSentence = Sentence(
        text: _customSentenceController.text, 
        translation: _customTranslationController.text, 
        language: widget.collection.language, 
        clozeStartChar: _customSentence!.clozeStartChar, 
        clozeEndChar: _customSentence!.clozeEndChar, 
        createdAt: DateTime.now()
      );

      final Sentence insertedSentence = await SentencesService.insertSentence(
        sentence: newSentence
      );

      final success = await CollectionSentencesService.addSentenceToCollection(
        sentenceId: insertedSentence.id!, 
        collectionId: widget.collection.id!
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
            backgroundColor: AppColors.successColor,
          ),
        );
        
        // Clear form
        _customSentenceController.clear();
        _customTranslationController.clear();
        
        // Navigate back to collection
        context.pop('added');
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

}