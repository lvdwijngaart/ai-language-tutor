

// Enum for word states
import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:flutter/material.dart';

enum WordState {
  unselected, // Grey - not selectable
  selectable, // Lighter - can be selected to extend range
  selected, // Blue - currently selected
}

enum TokenType {
  word, 
  punctuation, 
  space
}

class Token {
  final String text;
  final TokenType type;
  final int? wordIndex;

  Token({
    required this.text, 
    required this.type, 
    this.wordIndex
  });
}

class ClozeSelectionWidget extends StatefulWidget {
  final String text;
  final Function(Set<int>, List<String>, int? startChar, int? endChar) onSelectionChanged;
  final Color boxColor;

  const ClozeSelectionWidget({
    super.key,
    required this.text, 
    required this.onSelectionChanged, 
    this.boxColor = AppColors.darkBackground
  });

  @override
  State<ClozeSelectionWidget> createState() => _ClozeSelectionWidgetState();
}

class _ClozeSelectionWidgetState extends State<ClozeSelectionWidget> {
  Set<int> _selectedWordIndices = {};
  List<String> _words = [];
  List<Token> _tokens = [];

  @override
  void initState() {
    super.initState();
    _parseText();
  }

  void _parseText() {
    _words.clear();
    _tokens.clear();
    
    // Split the 
    final RegExp wordPattern = RegExp(r'\b\w+\b');
    final matches = wordPattern.allMatches(widget.text);

    int currentPos = 0;
    int wordIndex = 0;

    for (final match in matches) {
      // Add any punctuations/spaces before this word
      if (match.start > currentPos) {
        final punctuationText = widget.text.substring(currentPos, match.start);
        // Split punctuation and spaces into individual tokens
        for (int i = 0; i < punctuationText.length; i++) {
          final char = punctuationText[i];
          _tokens.add(Token(text: char, type: char == ' ' ? TokenType.space : TokenType.punctuation));
        }
      }

      // Add the word
      final word = match.group(0)!;
      _words.add(word);
      _tokens.add(Token(
        text: word, 
        type: TokenType.word, 
        wordIndex: wordIndex
      ));

      wordIndex++;
      currentPos = match.end;
    }

    // Add any remaining punctuations/spaces at the end
    if (currentPos < widget.text.length) {
      final remaining = widget.text.substring(currentPos);
      for (int i = 0; i < remaining.length; i++) {
        final char = remaining[i];
        _tokens.add(Token(
          text: char, 
          type: char == ' ' ? TokenType.space : TokenType.punctuation
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.boxColor, 
            borderRadius: BorderRadius.circular(12)
          ),
          child: Wrap(
            spacing: 0,
            runSpacing: 8,
            children: _tokens.map((token) {
              return _buildToken(token);
            }).toList(),
          ),
        )
      ],
    );
  }

  Widget _buildToken(Token token) {
    switch (token.type) {
      case TokenType.space: 
        return SizedBox (width: 8);

      case TokenType.punctuation: 
        return Text(
          ' ${token.text}', 
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16
          ),
        );
      
      case TokenType.word: 
        final wordIndex = token.wordIndex!;
        final wordState = _getWordState(wordIndex);

        return GestureDetector(
          onTap: () => _handleWordTap(wordIndex),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getWordBackgroundColor(wordState), 
              borderRadius: BorderRadius.circular(6), 
              border: Border.all(color: _getWordBorderColor(wordState))
            ),
            child: Text(
              token.text, 
              style: TextStyle(
                color: _getWordTextColor(wordState), 
                fontWeight: wordState == WordState.selected
                    ? FontWeight.bold
                    : FontWeight.normal
              ),
            ),
          ),
        );
    }
  }

  WordState _getWordState(int index) {
    if (_selectedWordIndices.isEmpty) {
      return WordState.selectable;
    }

    if (_selectedWordIndices.contains(index)) {
      return WordState.selected;
    }

    int minSelected = _selectedWordIndices.reduce((a, b) => a < b ? a : b);
    int maxSelected = _selectedWordIndices.reduce((a, b) => a > b ? a : b);

    if (index == minSelected - 1 || index == maxSelected + 1) {
      return WordState.selectable;
    }
    
    return WordState.unselected;
  }

  void _handleWordTap(int index) {
    setState(() {
      if (_selectedWordIndices.isEmpty) {
        _selectedWordIndices.add(index);
      } else if (_selectedWordIndices.contains(index)) {
        _removeWordFromSelection(index);
      } else {
        _extendSelection(index);
      }
    });
    
    // Calculate character positions and notify parent
    final positions = _calculateCharacterPositions();
    widget.onSelectionChanged(_selectedWordIndices, _words, positions['startChar'], positions['endChar']);
  }

  Map<String, int?> _calculateCharacterPositions() {
    if (_selectedWordIndices.isEmpty) {
      return {'startChar': null, 'endChar': null};
    }

    final originalSentence = widget.text;
    int minIndex = _selectedWordIndices.reduce((a, b) => a < b ? a : b);
    int maxIndex = _selectedWordIndices.reduce((a, b) => a > b ? a : b);

    // Calculate start position by finding the cleaned word in original sentence
    int startChar = 0;
    for (int i = 0; i < minIndex; i++) {
      final cleanedWord = _words[i];
      final wordIndex = originalSentence.indexOf(cleanedWord, startChar);
      if (wordIndex != -1) {
        startChar = wordIndex + cleanedWord.length;
        // Skip any spaces after this word
        while (startChar < originalSentence.length && originalSentence[startChar] == ' ') {
          startChar++;
        }
      }
    }

    // Find start of first selected word
    final firstSelectedWord = _words[minIndex];
    final wordStart = originalSentence.indexOf(firstSelectedWord, startChar);
    if (wordStart == -1) {
      return {'startChar': null, 'endChar': null}; 
    }

    // Calculate end position
    int endChar = wordStart;
    for (int i = minIndex; i <= maxIndex; i++) {
      final cleanedWord = _words[i];
      final wordIndex = originalSentence.indexOf(cleanedWord, endChar);
      if (wordIndex != -1) {
        endChar = wordIndex + cleanedWord.length;
      }
    }

    return {'startChar': wordStart, 'endChar': endChar};
  }

  void _removeWordFromSelection(int index) {
    int minSelected = _selectedWordIndices.reduce((a, b) => a < b ? a : b);
    int maxSelected = _selectedWordIndices.reduce((a, b) => a > b ? a : b);

    if (index == minSelected) {
      _selectedWordIndices.remove(index);
    } else if (index == maxSelected) {
      _selectedWordIndices.remove(index);
    } else {
      _selectedWordIndices.clear();
    }
  }

  void _extendSelection(int index) {
    int minSelected = _selectedWordIndices.reduce((a, b) => a < b ? a : b);
    int maxSelected = _selectedWordIndices.reduce((a, b) => a > b ? a : b);

    if (index == minSelected - 1 || index == maxSelected + 1) {
      _selectedWordIndices.add(index);
    }
  }

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

  // void clearSelection() {
  //   setState(() {
  //     _selectedWordIndices.clear();
  //     widget.onSelectionChanged(_selectedWordIndices, _words, );
  //   });
  // }
}