import 'dart:convert';

import 'package:ai_lang_tutor_v2/components/analysis/sentence_analysis_widget.dart';
import 'package:ai_lang_tutor_v2/components/chat/chat_bubbles/ai_message_chat_bubble.dart';
import 'package:ai_lang_tutor_v2/components/chat/chat_bubbles/transcript_chat_bubble.dart';
import 'package:ai_lang_tutor_v2/components/chat/chat_bubbles/loading_chat_bubble.dart';
import 'package:ai_lang_tutor_v2/components/chat/chat_bubbles/user_chat_bubble.dart';
import 'package:ai_lang_tutor_v2/components/chat/dropdowns.dart';
import 'package:ai_lang_tutor_v2/components/chat/input_area.dart';
import 'package:ai_lang_tutor_v2/components/chat/transcript_confirmation.dart';
import 'package:ai_lang_tutor_v2/constants/chat_constants.dart';
import 'package:ai_lang_tutor_v2/models/other/ai_response.dart';
import 'package:ai_lang_tutor_v2/models/other/chat_message.dart';
import 'package:ai_lang_tutor_v2/models/other/sentence_analysis.dart';
import 'package:ai_lang_tutor_v2/models/enums/transcript_confirmation_result.dart';
import 'package:ai_lang_tutor_v2/providers/language_provider.dart';
import 'package:ai_lang_tutor_v2/services/ai_tutor_service.dart';
import 'package:ai_lang_tutor_v2/services/speech_to_text_service.dart';
import 'package:ai_lang_tutor_v2/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ai_lang_tutor_v2/components/chat/conversation_starters.dart';
import 'package:ai_lang_tutor_v2/constants/app_constants.dart' show AppColors, AppSpacing, AppTextStyles, cardBackground, errorColor, secondaryAccent;
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart' show Language, ProficiencyLevel;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.isTestMode = false}); 

  final bool isTestMode;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  ProficiencyLevel _proficiencyLevel = ProficiencyLevel.intermediate; // Default proficiency level, change to configuration
  
  Language get _targetLanguage {
    return Provider.of<LanguageProvider>(context, listen: false).selectedLanguage;
  }

  // Speech to text states
  bool _speechEnabled = false; 
  bool _isListening = false; 
  String _currentTranscript = '';

  // When chat starts, show conversation starters
  bool _showConversationStarters = true; 

  @override 
  void initState() {
    super.initState();
    _addInitialMessage(); 
    _initSpeech();  
  }

  @override
  void dispose() {
    _messageController.dispose();
    // Clean up any resources or state here
    super.dispose();
  }

  // Initialize speech recognition
  void _initSpeech() async {
    logger.i('Initializing speech recognition...');
    bool initialized = await SpeechToTextService.initialize(
      onError: (error) {
        logger.e('Speech recognition error: ${error.errorMsg}');
        if (mounted) {
          // Show different messages based on error message
          // TODO: Something might be going wrong here because when I start the mic and don't talk, it should say something like "No speech detected" but it says speech recognition is not available
          String errorMessage = 'Speech recognition error occurred.';
          if (error.permanent) {
            errorMessage = 'Speech recognition is not available on this device.';
          } else if (error.errorMsg.toLowerCase().contains('network')) {
            errorMessage = 'Network error. Check your internet connection.';
          } else if (error.errorMsg.toLowerCase().contains('no_match')) {
            errorMessage = 'No speech detected. Please try again.';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage), 
              backgroundColor: error.permanent ? Colors.red : Colors.orange, 
              duration: Duration(seconds: 3),
            ), 
          );
        }

        // Update state to reflect speech recognition is not available
        if (mounted && error.permanent) {
          setState(() {
            _speechEnabled = false;
            _isListening = false;
          });
        }
      },
      onStatus: (status) {
        logger.i('Speech recognition status: $status');
        if (mounted) {
          if (status == 'notListening') {
            setState(() {
              _isListening = false;
            });
          } else if (status == 'listening') {
            setState(() {
              _isListening = true;
            });
          }
        }
      }, 
      logger: logger, 
    );

    // If speech is initialized successfully, update state
    if (mounted) {
      setState(() {
        _speechEnabled = initialized;
      });
      
      if (initialized) {
        logger.i('Speech recognition initialized successfully');
      } else {
        logger.w('Speech recognition initialization failed');
      }
    }
  }

  // Force reinitialize speech-to-text service
  void _forceReinitializeSpeech() async {
    setState(() {
      _speechEnabled = false; 
      _isListening = false;
      _currentTranscript = '';
    });

    await SpeechToTextService.forceReinitialize();
    _initSpeech();
  }
  
  // Add initial message
  void _addInitialMessage() {
    ChatMessage initialMessage = StandardChatMessages.initialMessage;
    _messages.add(initialMessage);
    logger.i('Initial message added: $initialMessage');
  }

  // Function to change target language
  void _changeTargetLanguage(Language newLanguage) {
    if (_targetLanguage == newLanguage) return;

    // Update global language state through provider
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    languageProvider.changeLanguage(newLanguage);

    _messages.add(StandardChatMessages.changeLanguageMessage(newLanguage));

    // Update the chat UI
    setState(() {});
    _scrollToBottom();
  }

  // Function to change proficiency level
  void _changeProficiencyLevel(ProficiencyLevel newLevel) {
    setState(() {
      _proficiencyLevel = newLevel;
    });

    _messages.add(StandardChatMessages.changeProficiencyLevel(newLevel));
    
    setState(() {});
    _scrollToBottom();
  }

  // Scroll to bottom of chat
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Handle sending a conversation starter
  void _sendConversationStarter(String starter) {
    // Format and send to AI
    logger.i('Sending conversation starter: $starter');

    // Formulate the message that will be sent to the 
    String message = 'Please start a conversation with me about the following topic: $starter';

    _sendMessage(customMessage: message, userAnalysis: false);
  }

  // Show sentence analysis panel
  void _showSentenceAnalysis(SentenceAnalysis analysis, ChatMessage message) {
    if (!mounted) return;
    logger.i('Showing sentence analysis for: ${analysis.sentence}');

    // Show analysis widget as bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, 
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground, 
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SentenceAnalysisWidget(
          sentenceAnalysis: analysis, 
          isUserMessage: message.isUserMessage, 
          onClose: () {
            Navigator.of(context).pop();
          }, 
          language: _targetLanguage,
        ),
      ),
    );
  }

  // Toggle microphone/speech recognition
  void _toggleListening() async {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  // Start listening for speech
  void _startListening() async {
    logger.i('Starting speech recognition...');
    if (!_speechEnabled) {
      logger.w('Speech recognition is not enabled, cannot start listening.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition is not available. Try reinitializing.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Clear any previous transcript
    setState(() {
      _currentTranscript = '';
      _messageController.text = '';
    });

    // Use target languages localeCode
    String locale = _targetLanguage.localeCode; 

    bool success = await SpeechToTextService.startListening(
      // TODO: Consider adding support for multi locale understanding. 
      //If the user speaks a bit of the target language, and then some english, it should still work. 
      //Or it should recognize that the target language is not spoken, and tell the user to try and speak the target language.
      localeId: locale,
      onResult: (result) {
        logger.i('Speech recognition received: ${result.recognizedWords}');
        if (mounted) {
          setState(() {
            _currentTranscript = result.recognizedWords;
          });
          _scrollToBottom();
        }
      },
      logger: logger,
    );

    logger.i('Start listening success: $success');

    if (mounted) {
      setState(() {
        _isListening = success;
        if (!success) {
          _currentTranscript = '';
        }
      });

      // Show error message if listening failed
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start speech recognition. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // Scroll to bottom to show the live transcript preview
        _scrollToBottom();
      }
    }

    logger.i('Updated state - isListening: $_isListening');
  }

  // Stop listening for speech
  void _stopListening() async {
    logger.i('Stopping speech recognition...');
    await SpeechToTextService.stopListening(logger);

    if (mounted) {
      setState(() {
        _isListening = false;
      });

      // If there is a transcript, you could show a confirmation dialog here
      if (_currentTranscript.isNotEmpty) {
        logger.i('Transcript received: $_currentTranscript');
        _showTranscriptConfirmation(_currentTranscript);
      }
    }
  }

  // Handle sending a message
  void _sendMessage({String? customMessage, String? preCommand = '', bool userAnalysis = true}) async {

    String messageText = customMessage ?? _messageController.text.trim();
    if (messageText.isEmpty) return;

    // Add user message
    ChatMessage userMessage = ChatMessage(
      text: messageText, 
      isUserMessage: true, 
      targetLanguage: _targetLanguage, 
      proficiencyLevel: _proficiencyLevel
    );
    _messages.add(userMessage);

    // Clear input field if message was taken from input
    if (customMessage == null) {
      _messageController.clear();
    }

    // Get ready for AI request
    setState(() {
      _showConversationStarters = false;
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      // Get AI response
      final AIResponse aiMessage = await AILanguageTutorService.sendMessage(
        message: userMessage, 
        conversationHistory: _messages, 
        targetLanguage: _targetLanguage, 
        proficiencyLevel: _proficiencyLevel, 
        analyzeUserMessage: userAnalysis, 
        onUserAnalysisReady: (userAnalysis) { 
          userMessage.sentenceAnalyses = userAnalysis.aiMessage.sentenceAnalyses;
          setState(() {});
        },
      );

      logger.i(aiMessage.toString());
      logger.i(jsonEncode(userMessage.toJson()));
      _messages.add(aiMessage.aiMessage);
      // _messages.add(ChatMessage(text: 'Total tokens: ' + aiMessage.totalTokens.toString(), isUserMessage: false));
    } catch (e) {
      logger.e('Error getting the AI\'s response');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get the AI\'s response. Try again later'), 
          backgroundColor: AppColors.errorColor,
        )
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _showTranscriptConfirmation(String transcript) async {

    final result = await showDialog<TranscriptConfirmationResult>(
      context: context,
      builder: (BuildContext context) {
        return TranscriptConfirmationDialog(
          transcript: transcript, 
          onSend: () => Navigator.of(context).pop(TranscriptConfirmationResult.send), 
          onRetry: () => Navigator.of(context).pop(TranscriptConfirmationResult.retry), 
          onCancel: () => Navigator.of(context).pop(TranscriptConfirmationResult.cancel)
        );
      }
    );

    if (result != null && mounted) {
      switch (result) {
        case TranscriptConfirmationResult.send: 
          _sendMessage(customMessage: transcript);
          break;
        case TranscriptConfirmationResult.retry: 
          _startListening();
          break;
        case TranscriptConfirmationResult.cancel: 
          setState(() {
            _currentTranscript = '';
            _messageController.clear();
          });
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final targetLanguage = languageProvider.selectedLanguage;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text(
          'AI Tutor Chat',
          style: AppTextStyles.heading1
        ), 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => context.go('/home'), 
        ),
      ), 
      body: Column(
        children: [

          // Language and Proficiency Level Selectors
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
            color: AppColors.darkBackground, 
            child: Row(
              children: [

                // Language Selector
                Expanded(
                  flex: 9,   
                  child: TutorChatDropdown<Language>(
                    value: targetLanguage, 
                    items: Language.values.map<DropdownMenuItem<Language>>((Language language) {
                      return DropdownMenuItem<Language>(
                        value: language, 
                        child: Row(
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                            Text(language.flagEmoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                language.displayName, 
                                style: const TextStyle(color: AppColors.electricBlue, fontSize: 16), 
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              )
                            )
                          ],
                        )
                      );
                    }).toList(), 
                    onChanged: (Language? newLanguage) {
                      if (newLanguage != null && newLanguage != targetLanguage) {
                        _changeTargetLanguage(newLanguage);
                      } 
                    }, 
                    itemBuilder: (BuildContext context) {
                      return Language.values.map<Widget>((Language language) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(language.flagEmoji, style: TextStyle(fontSize: 16)), 
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                language.displayName, 
                                style: const TextStyle(color: AppColors.electricBlue, fontSize: 16), 
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              )
                            )
                          ],
                        );
                      }).toList();
                    },
                    accentColor: AppColors.electricBlue,
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.electricBlue),
                  ),
                ),

                // Proficiency Level Selector
                Expanded(
                  flex: 7, 
                  child: TutorChatDropdown<ProficiencyLevel>(
                    value: _proficiencyLevel, 
                    items: ProficiencyLevel.values.map<DropdownMenuItem<ProficiencyLevel>>((ProficiencyLevel level) {
                      return DropdownMenuItem<ProficiencyLevel>(
                        value: level, 
                        child: Text(level.displayName, textAlign: TextAlign.center)
                      );
                    }).toList(),
                    onChanged: (ProficiencyLevel? newProficiencyLevel) {
                      if (newProficiencyLevel == _proficiencyLevel) return; // No change, do nothing

                      if (newProficiencyLevel != null) {
                        setState(() {
                          _changeProficiencyLevel(newProficiencyLevel);
                          logger.i('Proficiency level changed to: ${newProficiencyLevel.displayName}');
                        });
                      }
                    }, 
                    accentColor: AppColors.secondaryAccent,
                    fontSize: 15,
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.secondaryAccent),
                  )
                ), 
              ]
            ),
          ),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController, 
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + 
                        (_showConversationStarters ? 1 : 0) + // Add one for conversation starters if enabled
                        (_isLoading ? 1 : 0) + // Add one for loading indicator if loading
                        (_isListening ? 1 : 0),

              itemBuilder: (context, index) {
                logger.i('ListView building item $index');
                
                // Loading indicator
                if (_isLoading && index == _messages.length + (_showConversationStarters ? 1 : 0) + (_isListening ? 1 : 0)) {
                  return LoadingChatBubble();
                }

                // Live transcript preview
                if (_isListening && 
                    index == _messages.length + (_showConversationStarters ? 1 : 0)) {
                  return TranscriptChatBubble(currentTranscript: _currentTranscript);
                }

                // Conversation starters
                if (_showConversationStarters && index == _messages.length) {
                  return ConversationStarters(
                    proficiencyLevel: _proficiencyLevel,
                    onStarterTapped: _sendConversationStarter,
                  );
                }

                // Regular chat messages
                final message = _messages[index];
                if (message.isUserMessage) {
                  return UserChatBubble(
                    message: message, 
                    onSentenceTap: _showSentenceAnalysis
                  );
                } else {
                  return AIMessageChatBubble(
                    message: message, 
                    onSentenceTap: _showSentenceAnalysis,
                  );
                }

              }
            )
          ), 

          // Chat Input are
          ChatInputArea(
            messageController: _messageController,
            speechEnabled: _speechEnabled, // Change based on configuration
            isListening: _isListening, // Change based on speech recognition state
            currentTranscript: _currentTranscript, // Change based on speech recognition state
            onSendMessage: _sendMessage,
            onToggleSpeech: _toggleListening,
            onForceReinitializeSpeech: _forceReinitializeSpeech, // Optional callback for reinitializing speech
          ),
        ]
      )
    );
  }
}