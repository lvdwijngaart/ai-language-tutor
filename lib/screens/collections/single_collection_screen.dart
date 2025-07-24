import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/database/collection.dart';
import 'package:ai_lang_tutor_v2/models/database/sentence.dart';
import 'package:ai_lang_tutor_v2/providers/collections_provider.dart';
import 'package:ai_lang_tutor_v2/screens/collections/collection_form_screen.dart';
import 'package:ai_lang_tutor_v2/screens/error_screen.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/collections_service.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/sentences/collection_sentences_service.dart';
import 'package:ai_lang_tutor_v2/utils/logger.dart';
import 'package:ai_lang_tutor_v2/utils/print_cloze_sentence.dart';
import 'package:ai_lang_tutor_v2/services/supabase_client.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/collections_save_service.dart';
import 'package:ai_lang_tutor_v2/components/confirmation_dialogue.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SingleCollectionScreen extends StatefulWidget {
  final String collectionId;

  const SingleCollectionScreen({Key? key, required this.collectionId})
    : super(key: key);

  @override
  State<SingleCollectionScreen> createState() => _SingleCollectionScreenState();
}

class _SingleCollectionScreenState extends State<SingleCollectionScreen>
    with SingleTickerProviderStateMixin {
  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Loading states
  bool _isSaving = false;

  bool _isUsersCollection(Collection collection) {
    return supabase.auth.currentUser!.id == collection.createdBy;
  }

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadCollectionData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 0),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0.0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  Future<void> _loadCollectionData() async {
    final provider = Provider.of<CollectionsProvider>(context, listen: false);
    await provider.loadSingleCollection(widget.collectionId);

    // Start entrance animation if successfully loaded
    if (provider.selectedCollection != null) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    // Clear the single collection state when leaving the screen
    final provider = Provider.of<CollectionsProvider>(context, listen: false);
    provider.clearSingleCollection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CollectionsProvider>(
      builder: (context, provider, child) {
        // Handle error state
        if (provider.collectionError != null) {
          return ErrorScreen(
            title: 'Collection Not Found',
            message:
                'Unable to load collection details. ${provider.collectionError}',
            customBackRoute: '/home/collections',
          );
        }

        // Handle loading state
        if (provider.isLoadingCollection ||
            provider.selectedCollection == null) {
          return Scaffold(
            backgroundColor: AppColors.darkBackground,
            appBar: AppBar(
              title: Text('Loading...'),
              backgroundColor: AppColors.darkBackground,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.electricBlue),
                  SizedBox(height: 16),
                  Text(
                    'Loading collection...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          );
        }

        return AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Scaffold(
                backgroundColor: AppColors.darkBackground,
                appBar: _buildAppBar(provider.selectedCollection!),
                body: SlideTransition(
                  position: _slideAnimation,
                  child: _buildBody(
                    provider.selectedCollection!,
                    provider.collectionSentences,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(Collection collection) {
    final bool isUserCollection = _isUsersCollection(collection);
    return AppBar(
      title: Text(collection.title),
      backgroundColor: AppColors.darkBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      actions: [
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          icon: Icon(Icons.more_vert, color: Colors.white),
          color: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) => [
            if (isUserCollection) ...[
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: AppColors.electricBlue, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Edit Collection',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
            PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, color: AppColors.electricBlue, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Share Collection',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            if (isUserCollection) ...[
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Delete Collection',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildBody(Collection collection, List<Sentence> sentences) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCollectionHeader(collection),
          _buildActionButtons(collection, sentences),
          _buildSentencesList(sentences),
        ],
      ),
    );
  }

  Widget _buildCollectionHeader(Collection collection) {
    final bool isUserCollection = _isUsersCollection(collection);
    final collectionsProvider = Provider.of<CollectionsProvider>(context);
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Collection icon and basic info
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondaryAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  collection.icon ?? Icons.star,
                  color: AppColors.secondaryAccent,
                  size: 32,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          collection.language.flagEmoji,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(width: 8),
                        Text(
                          collection.language.displayName,
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Description
          if (collection.description?.isNotEmpty == true) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                collection.description!,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
            SizedBox(height: 16),
          ],

          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.quiz,
                  label: 'Sentences',
                  value: '${collectionsProvider.collectionSentences.length}',
                  color: AppColors.electricBlue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: collection.isPublic ? Icons.public : Icons.lock,
                  label: collection.isPublic ? 'Public' : 'Private',
                  value: isUserCollection
                      ? 'You'
                      : (collection.profile?['display_name'] as String?) ??
                            'Anonymous',
                  color: collection.isPublic ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Collection collection, List<Sentence> sentences) {
    final userId = supabase.auth.currentUser?.id;
    final isOwner = collection.createdBy == userId;
    final collectionsProvider = Provider.of<CollectionsProvider>(
      context,
      listen: false,
    );
    final isSaved = collectionsProvider.isCollectionSaved(collection.id!);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (isOwner) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: sentences.isNotEmpty ? _startPractice : null,
                icon: Icon(Icons.play_arrow),
                label: Text('Start Practice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _addSentences,
                icon: Icon(Icons.add),
                label: Text('Add Sentences'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else if (isSaved) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: sentences.isNotEmpty ? _startPractice : null,
                icon: Icon(Icons.play_arrow),
                label: Text('Start Practice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : () => _saveCollection(collection),
                icon: _isSaving
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white70,
                          ),
                        ),
                      )
                    : Icon(Icons.bookmark_remove),
                label: Text(_isSaving ? 'Removing...' : 'Un-save Collection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSaving
                      ? Colors.orange.withOpacity(0.6)
                      : Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : () => _saveCollection(collection),
                icon: _isSaving
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white70,
                          ),
                        ),
                      )
                    : Icon(Icons.bookmark_add),
                label: Text(_isSaving ? 'Saving...' : 'Save Collection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSaving
                      ? AppColors.secondaryAccent.withOpacity(0.6)
                      : AppColors.secondaryAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Handle saving/unsaving a collection
  void _saveCollection(Collection collection) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final collectionsProvider = Provider.of<CollectionsProvider>(
      context,
      listen: false,
    );
    final isSaved = collectionsProvider.isCollectionSaved(collection.id!);

    if (isSaved) {
      // Show confirmation dialog for unsaving
      final shouldUnsave = await UnsaveConfirmationDialog.show(
        context: context,
        title: 'Remove Collection',
        message:
            'Are you sure you want to remove "${collection.title}" from your saved collections?',
      );
      if (shouldUnsave == true) {
        setState(() {
          _isSaving = true;
        });
        await _unsaveCollection(collection);
        setState(() {
          _isSaving = false;
        });
      }
    } else {
      // Show confirmation dialog for saving
      final shouldSave = await SaveConfirmationDialog.show(
        context: context,
        title: 'Save Collection',
        message:
            'Do you want to save "${collection.title}" to your collections?',
      );
      if (shouldSave == true) {
        setState(() {
          _isSaving = true;
        });
        await _saveCollectionToUser(collection);
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Save collection to user
  // TODO: Make the collection saves have a active field and check if it is active, otherwise create a new collection save
  Future<void> _saveCollectionToUser(Collection collection) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final result = await CollectionsSaveService.createCollectionSave(
        userId: userId,
        collectionId: collection.id!,
      );
      if (result && mounted) {
        // Add collection to the appropriate provider list
        final collectionsProvider = Provider.of<CollectionsProvider>(
          context,
          listen: false,
        );

        // Add to personal collections if user owns it, otherwise to public collections
        if (collection.createdBy == userId) {
          collectionsProvider.addCollection(collection);
        } else {
          collectionsProvider.addPublicCollection(collection);
        }

        // Small delay before showing success message
        await Future.delayed(Duration(milliseconds: 200));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.bookmark_added, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Collection saved to your library!'),
                ],
              ),
              backgroundColor: AppColors.secondaryAccent,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Failed to save collection. Please try again.'),
              ],
            ),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  // Unsave collection from user
  // TODO: Probably make the collectionSave have an inactive field and set to inactive, so progress is kept
  Future<void> _unsaveCollection(Collection collection) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final result = await CollectionsSaveService.deleteCollectionSave(
        userId: userId,
        collectionId: collection.id!,
      );
      if (result && mounted) {
        // Remove collection from provider state
        final collectionsProvider = Provider.of<CollectionsProvider>(
          context,
          listen: false,
        );
        collectionsProvider.removeCollection(collection.id!);

        // Small delay before showing success message
        await Future.delayed(Duration(milliseconds: 200));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.bookmark_remove, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Collection removed from your library.'),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Failed to remove collection. Please try again.'),
              ],
            ),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildSentencesList(List<Sentence> sentences) {
    return Container(
      margin: EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Sentences',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
              ],
            ),
          ),
          SizedBox(height: 16),

          sentences.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  itemCount: sentences.length,
                  itemBuilder: (context, index) {
                    return _buildSentenceCard(sentences[index], index);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.text_snippet_outlined, size: 64, color: Colors.white38),
          SizedBox(height: 16),
          Text(
            'No sentences yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add some sentences to start practicing',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addSentences,
            icon: Icon(Icons.add),
            label: Text('Add Sentences'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryAccent,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentenceCard(Sentence sentence, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Card(
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white12),
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: CircleAvatar(
            backgroundColor: AppColors.electricBlue.withOpacity(0.2),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: AppColors.electricBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: printClozeSentence(sentence: sentence, showAsBlank: false),
          subtitle: Text(
            sentence.translation,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _copySentence(sentence.text),
                    icon: Icon(Icons.copy, size: 16),
                    label: Text('Copy'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.electricBlue,
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _editSentence(sentence),
                    icon: Icon(Icons.edit, size: 16),
                    label: Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.secondaryAccent,
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _deleteSentence(sentence),
                    icon: Icon(Icons.delete, size: 16),
                    label: Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Action handlers
  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _editCollection();
        break;
      case 'share':
        _shareCollection();
        break;
      case 'delete':
        DeleteConfirmationDialog.show(
          context: context,
          title: 'Delete this Collection?',
          message:
              'Are you sure you want to delete this collection? This can not be undone. ',
          onConfirm: () => _deleteCollection(),
        );
        break;
    }
  }

  void _startPractice() {
    HapticFeedback.lightImpact();
    context.push('/collections/${widget.collectionId}/practice');
  }

  void _addSentences() async {
    final collectionProvider = Provider.of<CollectionsProvider>(context, listen: false);
    final Collection collection = collectionProvider.selectedCollection!;
    HapticFeedback.lightImpact();
    final addSentenceResult = await context.push(
      '/collections/${widget.collectionId}/add-sentences', 
      extra: collection
    );

    if (addSentenceResult == 'added') {
      collectionProvider.loadSingleCollection(widget.collectionId);
    }
  }

  void _editCollection() async {
    final collectionProvider = Provider.of<CollectionsProvider>(context, listen: false);
    final Collection collection = collectionProvider.selectedCollection!;

    final CollectionFormResult result = await context.push(
      '/collections/${collection.id}/edit', 
      extra: collection
    ) as CollectionFormResult;

    if (result.status == CollectionFormStatus.completed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.successColor,
          content: Text('Your collection has been edited successfully!')
        )
      );
      collectionProvider.selectedCollection = result.collection;
    } else if (result.status == CollectionFormStatus.cancelled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.errorColor, 
          content: Text('Something went wrong while saving your collection. Try again later. ')
        )
      );
    }
  }

  void _shareCollection() {
    // TODO: Implement sharing
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Share feature coming soon!')));
  }

  void _deleteCollection() async {
    try {
      final result = await CollectionsSaveService.deleteCollectionSave(
        userId: supabase.auth.currentUser!.id,
        collectionId: widget.collectionId,
      );

      // Route back to last page
      if (result && mounted) {
        context.pop('deleted');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Something went wrong while deleting your colleciton. Refresh and try again. ',
          ),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  void _copySentence(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sentence copied to clipboard'),
        backgroundColor: AppColors.electricBlue,
      ),
    );
  }

  void _editSentence(Sentence sentence) {
    // TODO: Navigate to edit sentence screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit sentence feature coming soon!')),
    );
  }

  void _deleteSentence(Sentence sentence) async {
    // TODO Confirmation dialogue

    try {
      final success = await CollectionSentencesService.removeSentenceFromCollection(sentenceId: sentence.id!, collectionId: widget.collectionId);

      if (success) {
        final collectionsProvider = Provider.of<CollectionsProvider>(context, listen: false);
        collectionsProvider.removeSentenceFromCollection(sentence.id!);


        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Sentence removed successfully'),
                ],
              ),
              backgroundColor: AppColors.successColor,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      logger.e('Something went wrong while removing sentence from collection ${widget.collectionId}');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Failed to remove sentence. Please try again.'),
              ],
            ),
            backgroundColor: AppColors.errorColor,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    
  }
}
