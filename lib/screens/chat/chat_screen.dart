import 'package:ai_lang_tutor_v2/components/analysis/sentence_analysis_widget.dart';
import 'package:ai_lang_tutor_v2/components/chat/chat_message_bubble.dart';
import 'package:ai_lang_tutor_v2/components/chat/dropdowns.dart';
import 'package:ai_lang_tutor_v2/components/chat/input_area.dart';
import 'package:ai_lang_tutor_v2/components/chat/loading_indicator.dart';
import 'package:ai_lang_tutor_v2/constants/chat_constants.dart';
import 'package:ai_lang_tutor_v2/models/chat_message.dart';
import 'package:ai_lang_tutor_v2/models/sentence_analysis.dart';
import 'package:ai_lang_tutor_v2/services/speech_to_text_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import '../../components/chat/conversation_starters.dart';
import '../../constants/app_constants.dart' show AppColors, AppSpacing, AppTextStyles, cardBackground, secondaryAccent;
import '../../models/app_enums.dart' show Language, ProficiencyLevel;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.isTestMode = false}); 

  final bool isTestMode;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final Logger _logger = Logger();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  Language _targetLanguage = Language.spanish; // Default target language, change to configuration
  ProficiencyLevel _proficiencyLevel = ProficiencyLevel.intermediate; // Default proficiency level, change to configuration

  // Speech to text states
  bool _speechEnabled = false; // Change based on configuration
  bool _isListening = false; // Change based on speech recognition state
  String _currentTranscript = ''; // Change based on speech recognition state

  // When chat starts, show conversation starters
  bool _showConversationStarters = false; 

  @override 
  void initState() {
    super.initState();
    _addInitialMessage(); // Add initial message to the chat
    _initSpeech();

    // Run diagnostic in debug mode

  }

  @override
  void dispose() {
    _messageController.dispose();
    // Clean up any resources or state here
    super.dispose();
  }

  // Initialize speech recognition
  void _initSpeech() async {
    bool initialized = await SpeechToTextService.initialize(
      onError: (error) {
        _logger.e('Speech recognition error: $error');
        if (mounted && error.permanent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Speech recognition is not available on this device.'), 
              backgroundColor: Colors.orange, 
              duration: Duration(seconds: 3),
            ), 
          );
        }

        // Update state to reflect speech recognition is not available
        if (mounted) {
          setState(() {
            _speechEnabled = false;
            _isListening = false;
          });
        }
      },
      onStatus: (status) {
        _logger.i('Speech recognition status: $status');
        if (status == 'notListening' && mounted) {
          setState(() {
            _isListening = false;
          });
        }
      }, 
      logger: _logger, 
    );

    // If speech is initialized successfully, update state
    if (mounted) {
      setState(() {
        _speechEnabled = initialized;
      });
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
    _logger.i('Initial message added: $initialMessage');
  }

  // Function to change target language
  void _changeTargetLanguage(Language newLanguage) {
    setState(() {
      _targetLanguage = newLanguage;
      _logger.i('Target language changed to: ${newLanguage.displayName}');
    });
  }

  // Function to change proficiency level
  void _changeProficiencyLevel(ProficiencyLevel newLevel) {
    setState(() {
      _proficiencyLevel = newLevel;
      _logger.i('Proficiency level changed to: ${newLevel.displayName}');
    });
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
    _logger.i('Sending conversation starter: $starter');
    _logger.w('Function _sendConversationStarter is not implemented yet.');
  }

  // Show sentence analysis panel
  _showSentenceAnalysis(SentenceAnalysis analysis, ChatMessage message) {
    _logger.i('Showing sentence analysis for: ${analysis.sentence}');
    // Build analysis panel
    // SentenceAnalysisWidget();

    if (!mounted) return;

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
          }
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
    _logger.i('Starting speech recognition...');
    if (!_speechEnabled) {
      _logger.w('Speech recognition is not enabled, cannot start listening.');
      return;
    }

    String locale = _targetLanguage.localeCode; 

    bool success = await SpeechToTextService.startListening(
      // TODO: Consider adding support for multi locale understanding. 
      //If the user speaks a bit of the target language, and then some english, it should still work. 
      //Or it should recognize that the target language is not spoken, and tell the user to try and speak the target language.
      localeId: locale,
      onResult: (result) {
        _logger.i('Speech recognition received: ${result.recognizedWords}');
        if (mounted) {
          setState(() {
            _currentTranscript = result.recognizedWords;
            _messageController.text = _currentTranscript;
          });
        }
      }
    );

    _logger.i('Start listening success: $success');

    if (mounted) {
      setState(() {
        _isListening = success;
        if (!success) {
          _currentTranscript = '';
        }
      });

      // Scroll to bottom to show the live transcript preview
      if (success) {
        _scrollToBottom();
      }
    }

    _logger.i('Updated state - isListening: $_isListening');
  }

  // Stop listening for speech
  void _stopListening() async {
    await SpeechToTextService.stopListening(_logger);

    if (mounted) {
      setState(() {
        _isListening = false;
      });

      if (_currentTranscript.isNotEmpty) {
        // If there is a transcript, show it to the user and ask if they want to send it or redo it/cancel
        _logger.w('stopListening not yet implemented to handle transcript confirmation.');
      }
    }
  }

  // Handle sending a message
  void _sendMessage({String? customMessage, String? preCommand = ''}) {

    String messageText = customMessage ?? _messageController.text.trim();
    if (messageText.isEmpty) return;

    // Hide conversation starters after first user message
    setState(() {
      _showConversationStarters = false;
    });

    // Add user message
    _messages.add(ChatMessage(
      text: messageText, 
      isUserMessage: true
    ));

    // Clear input field if message was taken from input
    if (customMessage == null) {
      _messageController.clear();
    }

    setState(() {});  // Used to rebuild the widget
    _scrollToBottom();

    // Get AI response
    //TODO: implement AI functionality

  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            color: AppColors.darkBackground, 
            child: Row(
              children: [

                // Language Selector
                Expanded(
                  flex: 9,   
                  child: TutorChatDropdown<Language>(
                    value: _targetLanguage, 
                    items: Language.values.map<DropdownMenuItem<Language>>((Language language) {
                      return DropdownMenuItem<Language>(
                        value: language, 
                        child: Row(
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                            Text(language.flagEmoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(language.displayName, style: const TextStyle(color: Color(0xFF3A86FF), fontSize: 16)),
                          ],
                        )
                      );
                    }).toList(), 
                    onChanged: (Language? newLanguage) {
                      if (newLanguage == _targetLanguage) return; // No change, do nothing

                      if (newLanguage != null) {
                        setState(() {
                          _changeTargetLanguage(newLanguage);
                          _logger.i('Target Language changed to: ${newLanguage.displayName}');
                        });
                      }
                    }, 
                    itemBuilder: (BuildContext context) {
                      return Language.values.map<Widget>((Language language) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(language.flagEmoji, style: const TextStyle(fontSize: AppSpacing.medium)), 
                            const SizedBox(width: 6),
                            Text(language.displayName, style: const TextStyle(color: AppColors.electricBlue, fontSize: 16),)
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
                          _logger.i('Proficiency level changed to: ${newProficiencyLevel.displayName}');
                        });
                      }
                    }, 
                    accentColor: AppColors.secondaryAccent,
                    fontSize: 14,
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
                        (_isLoading ? 1 : 0), // Add one for loading indicator if loading
                        // +1 for when listening (@todo)

              itemBuilder: (context, index) {
                _logger.i('ListView building item $index');
                
                // Loading indicator
                if (_isLoading && index == _messages.length + (_showConversationStarters ? 1 : 0) + (_isLoading ? 1 : 0)) {
                  return const LoadingIndicator();
                }

                // Conversation starters
                if (_showConversationStarters && index == _messages.length) {
                  return ConversationStarters(
                    proficiencyLevel: _proficiencyLevel,
                    onStarterTapped: _sendConversationStarter,
                  );
                }

                // Live transcript preview


                // Regular chat messages
                final message = _messages[index];
                return ChatMessageBubble(
                  message: message, 
                  onSentenceTap: _showSentenceAnalysis,
                );

              }
            )
          ), 

          // Chat Input are
          ChatInputArea(
            messageController: _messageController,
            speechEnabled: _speechEnabled, // Change based on configuration
            isListening: _isListening, // Change based on speech recognition state
            currentTranscript: _currentTranscript, // Change based on speech recognition state
            onSendMessage: () {
              // Handle speech toggle
              _logger.w('onSendMessage functionality not implemented yet.');
            },
            onToggleSpeech: () {
              // Handle speech toggle
              _toggleListening();
            },
            onForceReinitializeSpeech: _forceReinitializeSpeech, // Optional callback for reinitializing speech
          ),
        ]
      )
    );
  }
}