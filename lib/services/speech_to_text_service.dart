

import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechToTextService {

  static SpeechToText _speechToText = SpeechToText();
  static bool _speechEnabled = false;
  static bool _isListening = false;

  static bool get speechEnabled => _speechEnabled;
  static bool get isListening => _isListening;

  // Initialize the speech recognition service
  static Future<bool> initialize({
    Function(SpeechRecognitionError)? onError, 
    Function(String)? onStatus,
    Logger? logger,
  }) async {
    try {
      logger?.i('Initializing speech to text service...');

      // First check if permissions are granted
      PermissionStatus status = await Permission.microphone.status;
      PermissionStatus speechStatus = await Permission.speech.status;

      logger?.i('Microphone permission status: $status');
      logger?.i('Speech permission status: $speechStatus');

      // Check if speech recognition is available on the device: 
      bool isAvaliable = await _speechToText.hasPermission;
      logger?.i('Speech to text has permissions (before init): $isAvaliable');

      // Initialize speech recognition with comprehensive error handling
      logger?.i('Initializing speech to text...');
      bool initResult = false;

      try {
        initResult = await _speechToText.initialize(
          onError: onError,
          onStatus: onStatus,
          debugLogging: true, 
        );
      } catch (e) {
        logger?.e('Error initializing speech to text: $e');
        initResult = false;
      }

      _speechEnabled = initResult;
      logger?.i('Speech recognition initialized: $_speechEnabled');

      if (_speechEnabled) {
        // Test if locales are available
        logger?.i('Checking available locales...');
        try {
          var locales = await _speechToText.locales();
          logger?.i('Available locales: ${locales.length}');

          if (locales.isNotEmpty) {
            logger?.i('Sample locales:');
            for (var locale in locales.take(5)) {
              logger?.i('Locale: ${locale.name} (${locale.localeId})');
            }
          } else {
            logger?.w('WARNING: No locales avaliable for speech recognition.');
            _speechEnabled = false;
          }
        } catch (e) {
          logger?.e('Error getting locales: $e');
        }

        // Final permission check
        isAvaliable = await _speechToText.hasPermission;
        logger?.i('Speech to text has permissions (after init): $isAvaliable');

        // If permissions are not available after initialization, disable speech recognition
        if (!isAvaliable) {
          logger?.w('No permissions after initialization, disabling speech recognition.');
          _speechEnabled = false;
        } 
      } else {
        logger?.w('Speech recognition initialization failed.');
      }

      // Log the final state
      logger?.i('=== Speech to Text Service Initialized ===');
      return _speechEnabled;

    } catch (e) {
      logger?.e('Error checking permissions: $e');
      logger?.e('Error type: ${e.runtimeType}');
      _speechEnabled = false;
      return false;
    }
  }

  // Start listening
  static Future<bool> startListening({
    required Function(SpeechRecognitionResult) onResult,
    String? localeId, 
    Function(double)? onSoundLevelChange, 
    Logger? logger
  }) async {
    logger?.i('=== Starting speech recognition ===');
    logger?.i('Speech enabled: $_speechEnabled');

    if (!_speechEnabled) {
      logger?.w('Speech recognition is not enabled, cannot start listening.');
      return false;
    }

    // Check if we already have permissions (don't request again if we already have them)
    bool available = await _speechToText.hasPermission;
    if (!available) {
      logger?.w('Speech recognition permission not available, requesting...');
      
      // Only request permissions if we don't have them
      Map<Permission, PermissionStatus> permissions = await [
        Permission.microphone, 
        Permission.speech,
      ].request();

      logger?.i('Microphone permission status: ${permissions[Permission.microphone]}');
      logger?.i('Speech permission status: ${permissions[Permission.speech]}');

      bool micGranted = permissions[Permission.microphone]?.isGranted ?? false;
      if(!micGranted) {
        logger?.w('Microphone permission denied');
        return false;
      }

      // Check again after requesting
      available = await _speechToText.hasPermission;
      if (!available) {
        logger?.w('Speech recognition permission still not available after request.');
        return false;
      }
    }
    
    // Check if already listening
    if (_speechToText.isListening) {
      logger?.w('Already listening, stopping first...');
      await _speechToText.stop();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    try {
      logger?.i('Starting speech recognition with locale: ${localeId ?? "default"}');
      
      await _speechToText.listen(
        onResult: onResult,
        localeId: localeId, 
        listenMode: ListenMode.dictation, // TODO: Look into ListenOptions and also make so that if pauseFor is reached, it lets the user know/stops listening and brings confirmation window
        partialResults: true, 
        pauseFor: const Duration(seconds: 10), // Reduced pause time
        listenFor: const Duration(seconds: 60), // Reduced listen time
        onSoundLevelChange: onSoundLevelChange,
      );
      
      logger?.i('Speech recognition listen command sent.');
      _isListening = true;

      // Wait a moment and check if we're actually listening
      await Future.delayed(const Duration(milliseconds: 500));
      bool actuallyListening = _speechToText.isListening;
      logger?.i('Actually listening after delay: $actuallyListening');

      // Update our state based on actual listening status
      _isListening = actuallyListening;

      if (!actuallyListening) {
        logger?.w('Speech recognition started but is not actually listening.');
        return false;
      }

      logger?.i('Speech recognition started successfully.');
      return true;

    } catch (e) {
      logger?.e('Listen error: $e');
      logger?.e('Error type: ${e.runtimeType}');

      _isListening = false;
      return false;
    }
  }

  // Stop listening
  static Future<void> stopListening(Logger? logger) async{
    logger?.i('Stopping speech recognition...');
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
        logger?.i('Speech recognition stopped successfully.');
      } else {
        logger?.i('Speech recognition was not listening, nothing to stop.');
      }
    } catch (e) {
      logger?.e('Error stopping speech recognition: $e');
    } finally {
      _isListening = false;
      logger?.i('Speech recognition state reset to not listening.');
    }
  }

  // Get available locales
  static Future<List<LocaleName>> getLocales(Logger? logger) async {
    try {
      return await _speechToText.locales();
    } catch (e) {
      logger?.e('Error fetching locales: $e');
      return [];
    }
  }

  // Force reinitialize the speech recognition service
  static Future<bool> forceReinitialize({
    Function(SpeechRecognitionError)? onError, 
    Function(String)? onStatus,
    Logger? logger,
  }) async {
    logger?.i('Forcing reinitialization of speech to text service...');

    try {
      // Stop any ongoing listening
      if (_isListening) {
        await stopListening(logger);
      }

      // Create a fresh instance
      _speechToText = SpeechToText();
      _speechEnabled = false;

      // Request permissions first
      Map<Permission, PermissionStatus> permissions = await [
        Permission.microphone, 
        Permission.speech,
      ].request();

      logger?.i('Permissions after request: $permissions');

      // Try to initialize
      bool initResult = await _speechToText.initialize(
        onError: onError,
        onStatus: onStatus,
        debugLogging: true, 
      );

      logger?.i('Force initialization result: $initResult');

      if (initResult) {
        _speechEnabled = true;

        // Test Locales
        try {
          var locales = await _speechToText.locales();
          logger?.i('Available locales after force init');
          if (locales.isNotEmpty) {
            logger?.i('Sample locales:');
            for (var locale in locales.take(5)) {
              logger?.i('Locale: ${locale.name} (${locale.localeId})');
            }
          }
        } catch (e) {
          logger?.e('Error getting locales after force init: $e');
        }
      }

      logger?.i('=== END FORCE REINITIALIZATION ===');
      return _speechEnabled;
    } catch (e) {
      logger?.e('Error during force reinitialization: $e');
      _speechEnabled = false;
      return false;
    }
  }

  // Diagnostic function
  static Future<void> runDiagnostic(Logger? logger) async {
    logger?.i('Diagnostic function not implemented yet.');
  }

}