import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/constants/icon_constants.dart';
import 'package:ai_lang_tutor_v2/models/database/collection.dart';
import 'package:ai_lang_tutor_v2/providers/collections_provider.dart';
import 'package:ai_lang_tutor_v2/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class PublicCollectionsScreen extends StatefulWidget {
  const PublicCollectionsScreen({super.key});

  @override
  State<StatefulWidget> createState() => _PublicCollectionScreenState();
}

class _PublicCollectionScreenState extends State<PublicCollectionsScreen> {
  late TextEditingController _searchController;
  late ScrollController _scrollController;
  String _searchTerm = '';
  int _selectedCategory = 0;

  final List<String> _categories = [
    'All',
    'Popular',
    'Recent',
    'Featured',
  ]; // TODO: Generalize also with the provider (& the query it calls)

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSearch();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  Future<void> _performSearch() async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final collectionsProvider = Provider.of<CollectionsProvider>(
      context,
      listen: false,
    );

    await collectionsProvider.searchPublicCollections(
      searchTerm: _searchTerm,
      categoryIndex: _selectedCategory,
      language: languageProvider.selectedLanguage,
    );
  }

  Future<void> _loadMore() async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final collectionsProvider = Provider.of<CollectionsProvider>(
      context,
      listen: false,
    );

    await collectionsProvider.loadMoreSearchResults(
      searchTerm: _searchTerm,
      categoryIndex: _selectedCategory,
      language: languageProvider.selectedLanguage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Public Collections"), elevation: 0),
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard and unfocus the search bar
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            _buildSearchBar(),
            _buildCategoryTabs(),
            Expanded(child: _buildSearchResults()),
          ],
        ),
      )
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search collections...",
          prefixIcon: Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchTerm = '');
                    _performSearch();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        onChanged: (value) {
          setState(() => _searchTerm = value);
        },
        onSubmitted: (_) => _performSearch(),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategory == index;
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_categories[index]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = index);
                _performSearch();
              },
              backgroundColor: Colors.transparent,
              selectedColor: AppColors.secondaryAccent.withValues(alpha: 0.9),
              checkmarkColor: AppColors.darkBackground,
              side: BorderSide(
                color: isSelected
                    ? AppColors
                          .secondaryAccent // Selected border color
                    : Colors.grey, // Unselected border color
                width: 1,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    return Consumer<CollectionsProvider>(
      builder: (context, provider, child) {
        if (provider.isSearching && provider.searchResults.isEmpty) {
          return _buildLoadingState();
        }

        if (provider.publicError != null && provider.searchResults.isEmpty) {
          return _buildErrorState(provider.publicError!);
        }

        if (provider.searchResults.isEmpty && !provider.isSearching) {
          return _buildEmptyState();
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount:
              provider.searchResults.length + (provider.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.searchResults.length) {
              return _buildLoadingMoreIndicator();
            }
            return _buildCollectionListItem(provider.searchResults[index]);
          },
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("Searching collections..."),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "Error loading collections",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center),
          SizedBox(height: 16),
          ElevatedButton(onPressed: _performSearch, child: Text("Retry")),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No collections found",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 8),
          Text("Try adjusting your search or category filter"),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: EdgeInsets.all(16),
      alignment: Alignment.center,
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildCollectionListItem(Collection collection) {
    // Check if this collection has already been added by the user
    final collectionsProvider = Provider.of<CollectionsProvider>(context, listen: false);
    bool isAdded = false;
    if (collectionsProvider.publicCollections.any((c) => c.id == collection.id)) {
      isAdded = true;
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: isAdded ? AppColors.secondaryAccent.withValues(alpha: 0.7) : Colors.transparent,
        width: isAdded ? 1 : 0,
      ),
      ),
      color: isAdded
        ? AppColors.secondaryAccent.withValues(alpha: 0.10)
        : Theme.of(context).cardColor,
      child: ListTile(
      contentPadding: EdgeInsets.all(16),
      title: Wrap(
        children: [
          Text(
            collection.title,
            style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
          ), 
          if (isAdded) ...[
            Text(
              ' - Saved', 
              style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: AppColors.secondaryAccent, fontWeight: FontWeight.bold)
            )
          ]
        ]
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        if (collection.description?.isNotEmpty == true) ...[
          SizedBox(height: 8),
          Text(
          collection.description!,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        SizedBox(height: 8),
        Row(
          children: [
          Icon(
            Icons.quiz,
            size: 16,
            color: AppColors.electricBlue.withValues(alpha: 0.8),
          ),
          SizedBox(width: 4),
          Text('${collection.nrOfSentences} sentences'),
          SizedBox(width: 16),
          Icon(
            Icons.favorite,
            size: 16,
            color: Colors.red.withValues(alpha: 0.8),
          ),
          SizedBox(width: 4),
          Text('${collection.saves} saves'),
          ],
        ),
        ],
      ),
      leading: IconStyles.smallIconWithPadding(
        icon: collection.icon!,
        backgroundColor: AppColors.secondaryAccent,
        iconColor: AppColors.secondaryAccent,
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () async {
        if (collection.id != null) {
        await context.push('/collections/${collection.id}/view');
        }
        _performSearch();
      },
      ),
    );
  }
}
