import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/database/collection.dart';
import 'package:ai_lang_tutor_v2/models/database/sentence.dart';
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/sentences/collection_sentences_service.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/sentences/sentences_service.dart';
import 'package:ai_lang_tutor_v2/utils/logger.dart';
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

      // TODO: Get sentence suggestions somewhere
      // final suggestions = ...

      setState(() {
        // _suggestedSentences = suggestions;
        _isLoadingSuggestions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSuggestions = false;
      });
      
    }
  }

  void _addSentence(Sentence sentence) {
    setState(() {
      _sentences.add(sentence);
    });
  }

  void _removeSentence(Sentence sentence) {
    setState(() {
      _sentences.remove(sentence);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong while adding sentences to your collection. ')
          )
        );
        logger.e('Something went wrong during adding sentences to Collection: $e');
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
        automaticallyImplyLeading: false, // This disables the back button
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

final prompt = """ 
    You are a language tutor for Spanish. Here are some example sentences from a user's vocabulary collection, 
    where each sentence includes a cloze word (marked by {}):  
    1. {Imaginemos} que estamos en un restaurante. 
    2. Qué tipo de aplicaciones sueles programar? 
    3. Se atrevió a contradecir al profesor durante la clase. 
    Based on the style and difficulty of these sentences, 
    generate 5 new sentences with cloze deletions to help the user practice similar vocabulary. """;

//     Generate 5 new Spanish practice sentences with a single cloze deletion in each (use curly braces {} to mark the cloze word). The sentences should closely match the style, complexity, tone, and vocabulary level of the given examples (natural sentences, moderate fluency, focus on verbs and useful expressions). After generating each Spanish sentence, provide its accurate English translation.

// For each sentence, return the following fields:
// - sentence: the full Spanish sentence, with exactly one word inside {} for cloze deletion
// - translation: the full English translation, with the cloze word translated in context
// - startClozeChar: zero-based index of the first character of the cloze word in the sentence (counting from beginning, including special or accented characters)
// - endClozeChar: zero-based index for the last character of the cloze word in the sentence (inclusive)

// Work step-by-step to make sure sentences meet the vocabulary and difficulty style, the cloze is useful, and the translations are faithful to the context before creating the final output.

// Output your response as a JSON array of exactly 5 objects, each with the fields specified above. Do not include any extra commentary or formatting.

// Example:
// [
//   {
//     "sentence": "{Comenzaré} a estudiar después de cenar.",
//     "translation": "I will start studying after dinner.",
//     "startClozeChar": 0,
//     "endClozeChar": 9
//   },
//   {
//     "sentence": "¿{Sabes} dónde dejé las llaves?",
//     "translation": "Do you know where I left the keys?",
//     "startClozeChar": 1,
//     "endClozeChar": 6
//   }
//   // (3 more objects in same format)
// ]

// (Remember: Provide only the JSON array in your answer with 5 items. Sentences must be original but comparable in level and vocabulary to the examples. All cloze deletions should be useful for vocabulary practice. Calculate indices carefully, including special characters.)

// Important: 
// - Only output a JSON array of 5 objects, nothing else.
// - Precisely calculate startClozeChar and endClozeChar, accounting for special characters.
// - Each sentence must have exactly one cloze deletion, matching the style/difficulty of the provided examples.