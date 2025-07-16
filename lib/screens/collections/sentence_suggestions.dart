import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/database/collection.dart';
import 'package:ai_lang_tutor_v2/models/database/sentence.dart';
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/sentences/collection_sentences_service.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/sentences/sentences_service.dart';
import 'package:flutter/material.dart';

class SentenceSuggestions extends StatefulWidget {
  final Collection collection;

  const SentenceSuggestions({
    super.key, 
    required this.collection
  });

  @override
  State<StatefulWidget> createState() => _SentenceSuggestionState();
}

class _SentenceSuggestionState extends State<SentenceSuggestions> {
  List<Sentence> _sentences = [];
  final List<Sentence> _suggestedSentences = [
    Sentence(
      text: 'Me arrepiento de no haber estudiado más cuando era joven. ', 
      translation: 'I regret not having studied more when I was young. ', 
      language: Language.spanish, 
      clozeStartChar: 3, 
      clozeEndChar: 12, 
      createdAt: DateTime.now()
    ), 
    Sentence(
      text: 'Ojalá que consigamos entradas para el concierto. ', 
      translation: 'I hope that we succeed in getting tickets to the concert. ', 
      language: Language.spanish, 
      clozeStartChar: 10, 
      clozeEndChar: 19, 
      createdAt: DateTime.now()
    ),
    Sentence(
      text: 'Se atrevió a contradecir al profesor durante la clase. ', 
      translation: 'He dared to contradict the professor during class. ', 
      language: Language.spanish, 
      clozeStartChar: 0, 
      clozeEndChar: 9, 
      createdAt: DateTime.now()
    ),
    // 'Nor dirigimos hacia la estación de tren más cercana', 
    // 'Reconozco que me equivoqué en mi decisión. '
  ];
  Set<Sentence> _selectedSentences = {};
  bool _isLoadingSuggestions = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestedSentences();
  }

  Future<void> _loadSuggestedSentences() async {
    setState(() => _isLoadingSuggestions = true);

    // Get suggestions
    try {
      // final suggestions = ['Sentence 1', 'Sentence 2', 'Sentence 3'];

      setState(() {
        // _suggestedSentences = suggestions;
        _isLoadingSuggestions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSuggestions = false;
        print("Error occurred during suggestion request"); // TODO: Better error handling
      });
    }
  }

  void _addSentence(Sentence sentence) {
    setState(() {
      _sentences.add(sentence);
      // _suggestedSentences.remove(sentence);
    });
  }

  void _removeSentence(Sentence sentence) {
    setState(() {
      _sentences.remove(sentence);
      // _suggestedSentences.add(sentence);
    });
  }

  Future<void> _finishCreation() async {
    setState(() {
      _isSaving = true;
    });

    try {
      if (_sentences.isEmpty) {
        await _skipAndFinish();
        return;
      }

      // TODO: refine and maybe check if the sentence already exists in the database. 
      final List<Sentence> sentencesAdded;
      try {
        sentencesAdded = await SentencesService.insertSentenceList(sentences: _sentences);

        final sentenceIds = sentencesAdded.map((s) => s.id).whereType<String>().toList();
        final collectionId = widget.collection.id!;

        final bool addToCollectionResult = await CollectionSentencesService.addMultSentencesToCollection(sentenceIds: sentenceIds, collectionId: collectionId);
      } catch (e) {
        // TODO: Handle exception during insertion
        print('Something went wrong during adding sentences to Collection: $e');
        return;
      }

      if (mounted) {
        Navigator.pop(context, {
          'status': 'completed', 
          'collection': widget.collection, 
          'sentences': sentencesAdded
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving sentences: $e'))
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
    
  }

  Future<void> _skipAndFinish() async {
    setState(() {
      _isSaving = true;
    });

    try {
      if (mounted) {
        Navigator.pop(context, {
          'status': 'completed', 
          'collection': widget.collection, 
          'skipped': true
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('')
          )
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Sentences'),
        backgroundColor: AppColors.darkBackground,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // Collection info header
          _collectionInfoHeader(),

          Expanded(
            child: _isLoadingSuggestions
                ? Center(child: CircularProgressIndicator())
                : ListView(
                    padding: EdgeInsets.all(20),
                    children: [

                      // Added sentences
                      if (_sentences.isNotEmpty) ...[
                        Text(
                          'Added to Collection',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 8),
                        ..._sentences.map((sentence) => _buildSentenceCard(
                          sentence: sentence,
                          isAdded: true,
                          onTap: () => _removeSentence(sentence),
                        )),
                        SizedBox(height: 32),
                      ],

                      // Suggested sentences
                      Text(
                        'Suggested Sentences',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                      ..._suggestedSentences.map((sentence) => _buildSentenceCard(
                        sentence: sentence,
                        isAdded: false,
                        onTap: () => _addSentence(sentence), 
                      )),
                    ],
                  ),
          ),

          // ✅ Bottom action bar
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkBackground,
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : () async {
                      if (_sentences.isNotEmpty) {
                        final shouldSkip = await _showSkipConfirmationDialog();
                        if (shouldSkip) {
                          _skipAndFinish();
                        }
                        // If should skip is false, do nothing
                      } else {
                        // No sentences, skip immediately
                        _skipAndFinish();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cardBackground,
                      foregroundColor: Colors.white.withOpacity(0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(10)
                      )
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Skip for now'),
                  ),
                ),

                if (_sentences.isNotEmpty) ...[
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _finishCreation, 
                      style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: AppColors.secondaryAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      ),
                      child: _isSaving
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, color: AppColors.darkBackground, size: 20),
                            const SizedBox(width: 7),
                            Text('Done (${_sentences.length})', style: TextStyle(color: AppColors.darkBackground),),
                          ]
                        )
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _collectionInfoHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      color: AppColors.darkBackground,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondaryAccent, 
              borderRadius: BorderRadius.circular(12)
            ),
            child: Icon(widget.collection.icon, color: Colors.white, size: 26),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.collection.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      widget.collection.language.flagEmoji, 
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.collection.language.displayName,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentenceCard({
    required Sentence sentence,
    required bool isAdded,
    required VoidCallback onTap,
  }) {

    Color cardColor;
    Color borderColor;
    Color textColor;

    if (isAdded) {
      cardColor = AppColors.secondaryAccent.withOpacity(0.07);
      borderColor = AppColors.secondaryAccent.withOpacity(0.4);
      textColor = Colors.white;
    } else if (_sentences.contains(sentence)) {
      cardColor = Colors.grey.withOpacity(0.15);
      borderColor = Colors.transparent;
      textColor = const Color.fromARGB(255, 156, 152, 152);
    } else {
      cardColor = AppColors.darkBackground;
      borderColor = Colors.white12;
      textColor = Colors.white;
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      margin: EdgeInsets.only(bottom: 8),
      child: Card(
        color: cardColor,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: borderColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sentence.text, 
                style: TextStyle(
                  color: textColor, 
                  fontSize: 18,
                  fontWeight: isAdded ? FontWeight.w600 : FontWeight.normal
                ),
              ), 
              const SizedBox(height: 2),
              Text(
                sentence.translation, 
                style: TextStyle(
                  color: textColor.withOpacity(0.7), 
                  fontSize: 15,
                ),
              ), 
            ],
          ),
          onTap: onTap,
        )
      ),
    );
  }

  Future<bool> _showSkipConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context, 
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), 
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded, 
                color: Colors.orange,
                size: 28,
              ), 
              SizedBox(width: 8),
              Text(
                'Skip sentences?', 
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 20, 
                  fontWeight: FontWeight.bold
                ),
              )
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You have ${_sentences.length} sentence${_sentences.length == 1 ? '' : 's'} selected. ', 
                style: TextStyle(
                  color: Colors.white70, 
                  fontSize: 16
                ),
              ), 
              SizedBox(height: 12), 
              Text(
                'If you skip now, your collection will be created without any sentences. You can add sentences later. ', 
                style: TextStyle(
                  color: Colors.white60, 
                  fontSize: 14
                ),
              ), 
              SizedBox(height: 16), 
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(8), 
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3)
                  )
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline, 
                      color: Colors.orange,
                      size: 20,
                    ), 
                    SizedBox(width: 8), 
                    Expanded(
                      child: Text(
                        'Tip: Complete the collection now to start practicing immediately! ', 
                        style: TextStyle(
                          color: Colors.orange.shade200, 
                          fontSize: 13
                        ),
                      )
                    )
                  ],
                ),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
              ),
              child: Text('Cancel')
            ), 

            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), 
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)
                ),
              ),
              child: Text('Skip anyway')
            )
          ],
        );
      }
    );

    return result ?? false;
  }
}
