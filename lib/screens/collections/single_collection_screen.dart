import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/database/collection.dart';
import 'package:ai_lang_tutor_v2/models/database/sentence.dart';
import 'package:ai_lang_tutor_v2/providers/collections_provider.dart';
import 'package:ai_lang_tutor_v2/screens/error_screen.dart';
import 'package:ai_lang_tutor_v2/utils/print_cloze_sentence.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SingleCollectionScreen extends StatefulWidget {
  final String collectionId;

  const SingleCollectionScreen({
    Key? key,
    required this.collectionId,
  }) : super(key: key);

  @override
  State<SingleCollectionScreen> createState() => _SingleCollectionScreenState();
}

class _SingleCollectionScreenState extends State<SingleCollectionScreen>
    with SingleTickerProviderStateMixin {
  
  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadCollectionData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
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
            message: 'Unable to load collection details. ${provider.collectionError}',
            customBackRoute: '/home/collections',
          );
        }

        // Handle loading state
        if (provider.isLoadingCollection || provider.selectedCollection == null) {
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
                  child: _buildBody(provider.selectedCollection!, provider.collectionSentences),
                ),
              ),
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(Collection collection) {
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
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: AppColors.electricBlue, size: 20),
                  SizedBox(width: 12),
                  Text('Edit Collection', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, color: AppColors.electricBlue, size: 20),
                  SizedBox(width: 12),
                  Text('Share Collection', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text('Delete Collection', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(Collection collection, List<Sentence> sentences) {
    return Column(
      children: [
        // Collection header
        _buildCollectionHeader(collection),
        
        // Action buttons
        _buildActionButtons(sentences),
        
        // Sentences list
        Expanded(child: _buildSentencesList(sentences)),
      ],
    );
  }

  Widget _buildCollectionHeader(Collection collection) {
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
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
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
                  value: '${collection.nrOfSentences}',
                  color: AppColors.electricBlue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: collection.isPublic ? Icons.public : Icons.lock,
                  label: collection.isPublic ? 'Public' : 'Private',
                  value: collection.isPublic ? 'Shared' : 'Personal',
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
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
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
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(List<Sentence> sentences) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
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
        ],
      ),
    );
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
          
          Expanded(
            child: sentences.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemCount: sentences.length,
                    itemBuilder: (context, index) {
                      return _buildSentenceCard(sentences[index], index);
                    },
                  ),
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
          Icon(
            Icons.text_snippet_outlined,
            size: 64,
            color: Colors.white38,
          ),
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
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
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
          title: printClozeSentence2(sentence),
          subtitle: Text(
            sentence.translation,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
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
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
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
        _deleteCollection();
        break;
    }
  }

  void _startPractice() {
    HapticFeedback.lightImpact();
    context.push('/collections/${widget.collectionId}/practice');
  }

  void _addSentences() {
    HapticFeedback.lightImpact();
    context.push('/collections/${widget.collectionId}/add-sentences');
  }

  void _editCollection() {
    // TODO: Navigate to edit collection screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit collection feature coming soon!')),
    );
  }

  void _shareCollection() {
    // TODO: Implement sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share feature coming soon!')),
    );
  }

  void _deleteCollection() {
    // TODO: Show delete confirmation dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Delete feature coming soon!')),
    );
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

  void _deleteSentence(Sentence sentence) {
    // TODO: Show delete confirmation and remove sentence
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Delete sentence feature coming soon!')),
    );
  }
}