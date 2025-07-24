import 'package:ai_lang_tutor_v2/models/database/collection.dart';
import 'package:ai_lang_tutor_v2/models/database/sentence.dart';
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/collections_service.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/sentences/sentences_service.dart';
import 'package:ai_lang_tutor_v2/services/supabase_client.dart';
import 'package:ai_lang_tutor_v2/utils/logger.dart';
import 'package:flutter/material.dart';

class CollectionsProvider extends ChangeNotifier {

  List<Collection> _personalCollections = [];
  List<Collection> _publicCollections = [];

  bool _isLoadingPersonal = false;
  bool _isLoadingPublic = false;

  String? _personalError;
  String? _publicError;

  // Getters: 
  
  // Getters for home/collections page
  List<Collection> get personalCollections => _personalCollections;
  List<Collection> get publicCollections => _publicCollections;
  
  bool get isLoadingPersonal => _isLoadingPersonal;
  bool get isLoadingPublic => _isLoadingPublic;
  bool get isLoading => _isLoadingPersonal || _isLoadingPublic;
  
  String? get personalError => _personalError;
  String? get publicError => _publicError;
  bool get hasErrors => _personalError != null || _publicError != null;

  Future<void> loadCollections(Language language) async {

    logger.i('Loading collections for ${language.displayName}');

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
      logger.i('Personal collections loaded: ${personalCollections.length} items');
    } catch (e) {
      _personalError = e.toString();
      _personalCollections = [];
      logger.e('Error loading personal collections: $e');
    } finally {
      _isLoadingPersonal = false;
    }

    try {
      final publicCollections = await CollectionsService.getPublicCollections(
        userId: supabase.auth.currentUser!.id, 
        language: language
      );

      _publicCollections = publicCollections;
      _publicError = null;
      logger.i('Public collections loaded: ${publicCollections.length} items');
    } catch (e) {
      _publicError = e.toString();
      _publicCollections = [];
      logger.e('Error loading public collections: $e');
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

  void addPublicCollection(Collection collection) {
    _publicCollections.add(collection);
    notifyListeners();
  }

  void removeCollection(String collectionId) {
    _personalCollections.removeWhere((collection) => collection.id == collectionId);
    _publicCollections.removeWhere((collection) => collection.id == collectionId);
    notifyListeners();
  }

  void updateCollection(Collection updatedCollection) {
    final index = _personalCollections.indexWhere((c) => c.id == updatedCollection.id);
    if (index != -1) {
      _personalCollections[index] = updatedCollection;
      notifyListeners();
    }
  }

  // Helper method to check if a collection is saved by the user
  bool isCollectionSaved(String collectionId) {
    return _personalCollections.any((c) => c.id == collectionId) ||
           _publicCollections.any((c) => c.id == collectionId);
  }

  // Helper method to get user's saved collection IDs for filtering
  List<String> get savedCollectionIds {
    final personalIds = _personalCollections.map((c) => c.id!).toList();
    final publicIds = _publicCollections.map((c) => c.id!).toList();
    return [...personalIds, ...publicIds];
  }

  void clear() {
    _personalCollections.clear();
    _publicCollections.clear();
    _searchResults.clear();
    _selectedCollection = null;
    _collectionSentences.clear();
    _personalError = null;
    _publicError = null;
    _collectionError = null;
    _isLoadingPersonal = false;
    _isLoadingPublic = false;
    _isLoadingCollection = false;
    _isSearching = false;
    _isLoadingMore = false;
    _searchTerm = '';
    _selectedCategory = 0;
    _currentPage = 0;
    _hasMoreResults = true;
    notifyListeners();
  }

  // Search and pagination state for public collections
  List<Collection> _searchResults = [];
  String _searchTerm = '';
  int _selectedCategory = 0;
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMoreResults = true;
  bool _isLoadingMore = false;
  bool _isSearching = false;

  // Single collection state
  Collection? _selectedCollection;
  List<Sentence> _collectionSentences = [];
  bool _isLoadingCollection = false;
  String? _collectionError;
  
  // Getters for search state
  List<Collection> get searchResults => _searchResults;
  String get searchTerm => _searchTerm;
  int get selectedCategory => _selectedCategory;
  bool get hasMoreResults => _hasMoreResults;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSearching => _isSearching;

  // Getters for single collection state
  Collection? get selectedCollection => _selectedCollection;
  set selectedCollection(Collection? collection) {
    _selectedCollection = collection;
    notifyListeners();
  }
  List<Sentence> get collectionSentences => _collectionSentences;
  bool get isLoadingCollection => _isLoadingCollection;
  String? get collectionError => _collectionError;

  // Search public collections with pagination
  Future<void> searchPublicCollections({
    required String searchTerm,
    required int categoryIndex,
    required Language language,
    bool loadMore = false,
  }) async {
    if (!loadMore) {
      _currentPage = 0;
      _searchResults.clear();
      _hasMoreResults = true;
      _isSearching = true;
    }

    if (!_hasMoreResults && loadMore) return;

    if (loadMore) {
      _isLoadingMore = true;
    } else {
      _isSearching = true;
    }
    
    _publicError = null;
    notifyListeners();

    try {
      final results = await CollectionsService.searchPublicCollections(
        searchTerm: searchTerm,
        categoryFilter: _getCategoryFilter(categoryIndex),
        language: language,
        userId: supabase.auth.currentUser!.id,
        savedCollectionIds: savedCollectionIds,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (loadMore) {
        _searchResults.addAll(results);
      } else {
        _searchResults = results;
      }

      _hasMoreResults = results.length == _pageSize;      // TODO: This does not necessarily mean there is more
      if (_hasMoreResults) _currentPage++;

      _searchTerm = searchTerm;
      _selectedCategory = categoryIndex;
      _publicError = null;
      
      logger.i('Search completed: ${results.length} results, page: $_currentPage');

    } catch (e) {
      _publicError = e.toString();
      if (!loadMore) _searchResults = [];
      logger.e('Error searching public collections: $e');
    } finally {
      _isSearching = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Load more search results
  Future<void> loadMoreSearchResults({
    required String searchTerm,
    required int categoryIndex,
    required Language language,
  }) async {
    if (!_hasMoreResults || _isLoadingMore) return;
    
    await searchPublicCollections(
      searchTerm: searchTerm,
      categoryIndex: categoryIndex,
      language: language,
      loadMore: true,
    );
  }

  // Load single collection details
  Future<void> loadSingleCollection(String collectionId) async {
    _isLoadingCollection = true;
    _collectionError = null;
    _selectedCollection = null;
    _collectionSentences = [];
    notifyListeners();

    try {
      // Load collection details
      final collection = await CollectionsService.getCollectionById(collectionId);
      _selectedCollection = collection;

      // Load sentences for this collection
      final sentences = await SentencesService.getSentencesByCollectionId(
        collectionId: collectionId,
      );
      _collectionSentences = sentences;

      _collectionError = null;
      logger.i('Single collection loaded: ${collection.title} with ${sentences.length} sentences');

    } catch (e) {
      _collectionError = e.toString();
      _selectedCollection = null;
      _collectionSentences = [];
      logger.e('Error loading single collection: $e');
    } finally {
      _isLoadingCollection = false;
      notifyListeners();
    }
  }

  void removeSentenceFromCollection(String sentenceId) {
    _collectionSentences.removeWhere((sentence) => sentence.id == sentenceId);
    notifyListeners();
  }

  // Helper to convert category index to filter
  String _getCategoryFilter(int categoryIndex) {
    switch (categoryIndex) {
      case 0: return 'all';
      case 1: return 'popular';
      case 2: return 'recent';
      case 3: return 'featured';
      default: return 'all';
    }
  }

  // Clear search results
  void clearSearch() {
    _searchResults.clear();
    _searchTerm = '';
    _selectedCategory = 0;
    _currentPage = 0;
    _hasMoreResults = true;
    _isLoadingMore = false;
    _isSearching = false;
    notifyListeners();
  }

  // Clear single collection data
  void clearSingleCollection() {
    _selectedCollection = null;
    _collectionSentences = [];
    _collectionError = null;
    _isLoadingCollection = false;
    notifyListeners();
  }

  void removeFromSearch(String collectionId) {
    
  }
}