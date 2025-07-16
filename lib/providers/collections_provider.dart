

import 'package:ai_lang_tutor_v2/models/database/collection.dart';
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/collections_service.dart';
import 'package:ai_lang_tutor_v2/services/supabase_client.dart';
import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CollectionsProvider extends ChangeNotifier {
  final Logger _logger = Logger();

  List<Collection> _personalCollections = [];
  List<Collection> _publicCollections = [];

  bool _isLoadingPersonal = false;
  bool _isLoadingPublic = false;

  String? _personalError;
  String? _publicError;

  // Getters: 
  
  // ✅ Getters for definitive data
  List<Collection> get personalCollections => _personalCollections;
  List<Collection> get publicCollections => _publicCollections;
  
  bool get isLoadingPersonal => _isLoadingPersonal;
  bool get isLoadingPublic => _isLoadingPublic;
  bool get isLoading => _isLoadingPersonal || _isLoadingPublic;
  
  String? get personalError => _personalError;
  String? get publicError => _publicError;
  bool get hasErrors => _personalError != null || _publicError != null;

  // void initialize(Language initialLanguage) {
  //   _currentLanguage = initialLanguage;
  //   loadCollections();
  // }

  // void onLanguageChanged(Language newLanguage) {
  //   if (_currentLanguage != newLanguage) {
  //     _logger.i('Language changed from ${_currentLanguage?.displayName} to ${newLanguage.displayName}');
  //     _currentLanguage = newLanguage;
  //     loadCollections();
  //   }
  // }

  Future<void> loadCollections(Language language) async {
    // if (_currentLanguage == null) {
    //   _logger.w('Cannot load collections: no language set');
    //   return;
    // }

    _logger.i('Loading collections for ${language!.displayName}');

    // Set loading states
    _isLoadingPersonal = true;
    _isLoadingPublic = true;
    _personalError = null;
    _publicError = null;
    notifyListeners();

    try {
      final personalCollections = await CollectionsService.getPersonalCollections(
        userId: supabase.auth.currentUser!.id,
        language: language
      );

      _personalCollections = personalCollections;
      _personalError = null;
      _logger.i('Personal collections loaded: ${personalCollections.length} items');
    } catch (e) {
      _personalError = e.toString();
      _personalCollections = [];
      _logger.e('Error loading personal collections: $e');
    } finally {
      _isLoadingPersonal = false;
    }

    try {
      final publicCollections = await CollectionsService.getHighlightCollections(
        nrOfResults: 4, 
        userId: supabase.auth.currentUser!.id, 
        language: language
      );

      _publicCollections = publicCollections;
      _publicError = null;
      _logger.i('Public collections loaded: ${publicCollections.length} items');
    } catch (e) {
      _publicError = e.toString();
      _publicCollections = [];
      _logger.e('Error loading public collections: $e');
    } finally {
      _isLoadingPublic = false;
    }

    notifyListeners();
  }
  
  Future<void> refresh(Language currentLanguage) async {
    await loadCollections(currentLanguage);
  }

  void addCollection(Collection collection) {
    _personalCollections.add(collection);
    notifyListeners();
  }

  void removeCollection(String collectionId) {
    personalCollections.removeWhere((collection) => collection.id == collectionId);
    notifyListeners();
  }

  void updateCollection(Collection updatedCollection) {
    final index = _personalCollections.indexWhere((c) => c.id == updatedCollection.id);
    if (index != -1) {
      _personalCollections[index] = updatedCollection;
      notifyListeners();
    }
  }

  void clear() {
    _personalCollections.clear();
    _publicCollections.clear();
    _personalError = null;
    _publicError = null;
    _isLoadingPersonal = false;
    _isLoadingPublic = false;
    notifyListeners();
  }
}