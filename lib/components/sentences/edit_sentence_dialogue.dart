

import 'package:ai_lang_tutor_v2/components/sentences/cloze_preview_widget.dart';
import 'package:ai_lang_tutor_v2/components/sentences/cloze_selection_widget.dart';
import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/database/sentence.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/sentences/sentences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class EditSentenceDialogue extends StatefulWidget {
  final Sentence sentence;
  final Function(Sentence updatedSentence)? onSentenceUpdated;

  const EditSentenceDialogue({
    Key? key, 
    required this.sentence, 
    this.onSentenceUpdated
  }) : super(key: key);

  static Future<Sentence?> show({
    required BuildContext context, 
    required Sentence sentence, 
    Function(Sentence)? onSentenceUpdated
  }) async {
    return await showDialog(
      context: context, 
      builder: (context) => EditSentenceDialogue(
        sentence: sentence, 
        onSentenceUpdated: onSentenceUpdated,
      )
    );
  }

  @override
  State<EditSentenceDialogue> createState() => _EditSentenceDialogState();
}

class _EditSentenceDialogState extends State<EditSentenceDialogue> {
  late TextEditingController _sentenceController;
  late TextEditingController _translationController;
  Sentence? _editedSentence;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _sentenceController = TextEditingController(text: widget.sentence.text);
    _translationController = TextEditingController(text: widget.sentence.translation);
    _editedSentence = widget.sentence;

    // Listen for changes
    _sentenceController.addListener(_onTextChanged);
    _translationController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _sentenceController.dispose();
    _translationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85, 
          maxWidth: 600
        ),
        decoration: BoxDecoration(
          color: AppColors.darkBackground, 
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(color: Colors.white12)
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20), 
              decoration: BoxDecoration(
                color: AppColors.cardBackground, 
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), 
                  topRight: Radius.circular(20)
                ), 
                border: Border(bottom: BorderSide(color: Colors.white12)), 
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, color: AppColors.electricBlue, size: 24), 
                  SizedBox(width: 12), 
                  Expanded(
                    child: Text(
                      'Edit Sentence', 
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 20, 
                        fontWeight: FontWeight.bold
                      ),
                    )
                  ), 
                  if (_hasChanges) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryAccent.withValues(alpha: 0.2), 
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: Text(
                        'Modified', 
                        style: TextStyle(
                          color: AppColors.secondaryAccent, 
                          fontSize: 12, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    )
                  ]
                ],
              ),
            ), 

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Original Sentence field
                    _buildSectionHeader('Sentence', Icons.text_fields), 
                    SizedBox(height: 8), 
                    _buildTextField(
                      controller: _sentenceController, 
                      hintText: 'Enter the sentence in ${widget.sentence.language.displayName}...', 
                      maxLines: 3
                    ), 
                    SizedBox(height: 20), 

                    // Translation Field
                    _buildSectionHeader('Translation', Icons.translate), 
                    SizedBox(height: 8), 
                    _buildTextField(
                      controller: _translationController, 
                      hintText: 'Enter the the English translation...', 
                      maxLines: 2
                    ), 
                    SizedBox(height: 20), 

                    // Cloze selection
                    _buildSectionHeader('Cloze Word Selection', Icons.lightbulb_outline), 
                    SizedBox(height: 8), 
                    Text(
                      'Tap on words to select which word(s) to hide during practice', 
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ), 
                    SizedBox(height: 12), 

                    // Container(
                    //   padding: EdgeInsets.all(16),
                    //   decoration: BoxDecoration(
                    //     color: AppColors.cardBackground, 
                    //     borderRadius: BorderRadius.circular(12), 
                    //     border: Border.all(color: Colors.white12)
                    //   ),
                    //   child: 
                      ClozeSelectionWidget(
                        key: ValueKey(_sentenceController.text),
                        text: _sentenceController.text, 
                        initialStartChar: _sentenceController.text == widget.sentence.text
                            ? widget.sentence.clozeStartChar
                            : null,
                        initialEndChar: _sentenceController.text == widget.sentence.text
                            ? widget.sentence.clozeEndChar
                            : null,
                        onSelectionChanged: _onClozeSelectionChanged, 
                        boxColor: AppColors.cardBackground,
                      ),
                    // ), 
                    SizedBox(height: 20), 

                    // Preview
                    if (_editedSentence?.clozeStartChar != _editedSentence?.clozeEndChar && 
                        _editedSentence != null && 
                        _sentenceController.text.isNotEmpty) ...[
                      _buildSectionHeader('Preview', Icons.visibility), 
                      SizedBox(height: 8), 
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.electricBlue.withValues(alpha: 0.1), 
                          borderRadius: BorderRadius.circular(12), 
                          border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.3))
                        ),
                        child: ClozePreviewWidget(
                          sentence: _editedSentence!
                        ),
                      )
                    ] else if (_sentenceController.text.isNotEmpty) ...[
                      _buildSectionHeader('Preview', Icons.visibility), 
                      SizedBox(height: 8), 
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1), 
                          borderRadius: BorderRadius.circular(12), 
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3))
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange, size: 20), 
                            SizedBox(width: 8), 
                            Expanded(
                              child: Text(
                                'Please select words above for cloze practice', 
                                style: TextStyle(color: Colors.orange, fontSize: 14),
                              ),
                            ), 
                          ],
                        ),
                      ),
                      SizedBox(height: 20), 
                    ] else ...[
                      SizedBox.shrink()
                    ]
                  ],
                ),
              )
            ), 

            // Footer with action buttons
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20), 
                  bottomRight: Radius.circular(20)
                ), 
                border: Border(top: BorderSide(color: Colors.white12))
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : _discardChanges, 
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70, 
                        padding: EdgeInsets.symmetric(vertical: 16), 
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), 
                          side: BorderSide(color: Colors.white24)
                        )
                      ),
                      child: Text('cancel')
                    )
                  ), 
                  SizedBox(width: 12), 
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading || !_canSave() ? null : _saveSentence,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasChanges
                            ? AppColors.electricBlue
                            : Colors.grey,
                        foregroundColor: Colors.white, 
                        padding: EdgeInsets.symmetric(vertical: 16), 
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), 
                        )
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
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ), 
                              SizedBox(width: 8), 
                              Text('Saving...')
                            ],
                          )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center, 
                          children: [
                            Icon(Icons.save, size: 18), 
                            SizedBox(width: 8), 
                            Text('Save Changes')
                          ],
                        )
                    )
                  ), 
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.electricBlue, size: 20), 
        SizedBox(width: 8), 
        Text(
          title, 
          style: TextStyle(
            color: Colors.white, 
            fontSize: 16,
            fontWeight: FontWeight.bold, 
          ),
        )
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller, 
    required String hintText, 
    int maxLines = 1
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Colors.white, fontSize: 16),
      maxLines: maxLines,
      minLines: maxLines > 1 ? 2 : 1,
      decoration: InputDecoration(
        hintText: hintText, 
        hintStyle: TextStyle(color: Colors.white54), 
        filled: true,
        fillColor: AppColors.cardBackground, 
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: BorderSide(color: Colors.white12)
        ), 
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.electricBlue, width: 2),
        ),
        contentPadding: EdgeInsets.all(16),
      ),
    );
  }

  bool _canSave() {
    return _hasChanges && 
    _editedSentence != null &&
    _editedSentence!.clozeStartChar != _editedSentence!.clozeEndChar && 
    _sentenceController.text.trim().isNotEmpty &&
    _translationController.text.trim().isNotEmpty;
  }

  void _onTextChanged() {
    setState(() {
      final sentenceTextChanged = _sentenceController.text != _editedSentence?.text;


      if (sentenceTextChanged) {
        _editedSentence = null;
      }
      _hasChanges = _sentenceController.text != widget.sentence.text ||
                    _translationController.text != widget.sentence.translation ||
                    _editedSentence?.clozeStartChar != widget.sentence.clozeStartChar ||
                    _editedSentence?.clozeEndChar != widget.sentence.clozeEndChar;
    });
  }

  void _onClozeSelectionChanged(Set<int> selection, List<String> words, int? startChar, int? endChar) {
    if (startChar != null && endChar != null) {
      setState(() {
        _editedSentence = Sentence(
          id: widget.sentence.id,
          text: _sentenceController.text, 
          translation: _translationController.text, 
          language: widget.sentence.language, 
          clozeStartChar: startChar, 
          clozeEndChar: endChar, 
          createdAt: widget.sentence.createdAt
        );
        _hasChanges = true;
      });
    } else {
      setState(() {
        _editedSentence = null;
      });
    }
  }

  Future<void> _saveSentence() async {
    if (!_canSave() || _editedSentence == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please complete all fields and select cloze words'),
          backgroundColor: AppColors.errorColor,
        )
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updates = {
        'text': _sentenceController.text, 
        'translation': _translationController.text, 
        'cloze_start_char': _editedSentence!.clozeStartChar, 
        'cloze_end_char': _editedSentence!.clozeEndChar
      };

      // Update sentence in database
      final result = await SentencesService.updateSentence(widget.sentence.id!, updates);

      if (mounted) {
        widget.onSentenceUpdated?.call(result);
        Navigator.of(context).pop(result);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20), 
                SizedBox(width: 8), 
                Text('Sentence updated successfully!')
              ],
            ), 
            backgroundColor: AppColors.successColor,
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20), 
                SizedBox(width: 8), 
                Text('Failed to update sentence: ${e.toString()}')
              ],
            ),
            backgroundColor: AppColors.errorColor
          )
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _discardChanges() {
    if (_hasChanges) {
      showDialog(
        context: context, 
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Discard Changes?', 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'You have unsaved changes. Are you sure want to discard them?', 
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), 
              child: Text('Cancel', style: TextStyle(color: Colors.white70))
            ), 
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();  // Close confirmation dialogue
                Navigator.of(context).pop();  // Close edit dialogue
              }, 
              child: Text('Discard', style: TextStyle(color: Colors.red),)
            )
          ],
        )
      );
    } else {
      Navigator.of(context).pop();
    }
  }
}