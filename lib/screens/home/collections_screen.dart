import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/database/collection.dart';
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/providers/collections_provider.dart';
import 'package:ai_lang_tutor_v2/providers/language_provider.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/collections_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CollectionsScreen extends StatelessWidget {
  final double headerSize = 22;

  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageProvider, CollectionsProvider>(
      builder: (context, languageProvider, collectionsProvider, child) {
        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Text('Collections', style: AppTextStyles.pageHeader),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Challenge button
                      _buildChallengeButton(),
                      const SizedBox(height: 30),

                      // List of user's Collections
                      _buildUserCollectionsList(
                        context: context,
                        collectionsProvider: collectionsProvider,
                      ),
                      const SizedBox(height: 30),

                      // List of public Collections
                      _buildPublicCollectionsList(
                        context: context,
                        collectionsProvider: collectionsProvider,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserCollectionsList({
    required BuildContext context,
    required CollectionsProvider collectionsProvider,
  }) {
    final personalCollections = collectionsProvider.personalCollections;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Your Collections',
          style: TextStyle(
            color: Colors.white,
            fontSize: headerSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        if (collectionsProvider.isLoadingPersonal) ...[
          Center(
            child: Column(
              children: [
                CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  'Loading your collections...',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ] else if (collectionsProvider.personalError != null) ...[
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.errorColor,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  'Error loading collections',
                  style: TextStyle(
                    color: AppColors.errorColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  collectionsProvider.personalError!,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    final languageProvider = Provider.of<LanguageProvider>(
                      context,
                      listen: false,
                    );
                    collectionsProvider.refresh(
                      languageProvider.selectedLanguage,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ] else ...[
          // If collection has any records, show these in Grid layout
          if (personalCollections.isNotEmpty) ...[
            ...personalCollections.map(
              (collection) => _buildcollectionButton(
                icon: collection.icon ?? Icons.star,
                title: collection.title,
                nrOfSentences: collection.nrOfSentences,
                onTap: () async {
                  final result = await context.push(
                    '/collections/${collection.id}/view',
                  );
                  if (result == 'deleted') {
                    final languageProvider = Provider.of<LanguageProvider>(
                      context,
                      listen: false,
                    );
                    collectionsProvider.refresh(
                      languageProvider.selectedLanguage,
                    );
                  }
                },
              ),
            ),
          ],
          if (personalCollections.isEmpty) ...[
            Center(
              child: Text(
                'No Collections saved yet. Create one or look through the public collections!',
                style: AppTextStyles.heading3,
              ),
            ),
          ],
          const SizedBox(height: 5),

          // Create new Collection button
          GestureDetector(
            onTap: () async {
              final result = await context.push('/collections/create');

              if (result == 'created') {
                final languageProvider = Provider.of<LanguageProvider>(
                  context,
                  listen: false,
                );
                collectionsProvider.refresh(languageProvider.selectedLanguage);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.add, color: Colors.white, size: 32),
                  const SizedBox(width: 20),

                  Text(
                    'Create New Collection',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPublicCollectionsList({
    required BuildContext context,
    required CollectionsProvider collectionsProvider,
  }) {
    final maxRows = 2;
    final columns = 2;
    final maxItems = maxRows * columns;

    final publicCollections = collectionsProvider.publicCollections;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Public Collections',
          style: TextStyle(
            color: Colors.white,
            fontSize: headerSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        if (collectionsProvider.isLoadingPublic) ...[
          Center(
            child: Column(
              children: [
                CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  'Loading public collections...',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ] else if (collectionsProvider.publicError != null) ...[
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.errorColor,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  'Error loading collections',
                  style: TextStyle(
                    color: AppColors.errorColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  collectionsProvider.publicError!,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    final languageProvider = Provider.of<LanguageProvider>(
                      context,
                      listen: false,
                    );
                    collectionsProvider.refresh(
                      languageProvider.selectedLanguage,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ] else ...[
          if (publicCollections.isNotEmpty) ...[
            ...publicCollections.map(
              (collection) => _buildcollectionButton(
                icon: collection.icon ?? Icons.star,
                title: collection.title,
                nrOfSentences: collection.nrOfSentences,
                onTap: () => context.push('/collections/${collection.id}/view'),
              ),
            ),
          ],
          if (publicCollections.isEmpty) ...[
            Center(
              child: Text(
                'No Public Collections saved yet. Find and save a collection to start learning new vocab!',
                style: AppTextStyles.heading3,
              ),
            ),
          ],
        ],
        const SizedBox(height: 5),

        // Find Public Collection button
        GestureDetector(
          onTap: () {
            context.push('/collections/public-collections');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.secondaryAccent.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.add, color: Colors.white, size: 32),
                const SizedBox(width: 20),

                Text(
                  'Find Public Collections',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildcollectionButton({
    required IconData icon,
    required String title,
    required int nrOfSentences,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondaryAccent.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.secondaryAccent, size: 22),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$nrOfSentences sentences',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeButton() {
    return GestureDetector(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 28, 120, 111),
              const Color(0xFF2EC4B6),
              // const Color(0xFF2EC4B6)
            ],
          ),
          // boxShadow: [
          //   BoxShadow(
          //     color: AppColors.secondaryAccent,
          //     blurRadius: 8,
          //     offset: Offset(0, 3),
          //   ),
          // ],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Challenge a Friend!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Invite a friend to a playful quiz battle for xxx\'s glory.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.2,
                    ),
                    softWrap: true,
                    maxLines: null,
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 15),
              child: Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
