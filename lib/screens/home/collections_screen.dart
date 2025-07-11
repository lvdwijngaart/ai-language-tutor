import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/database/collection.dart';
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/collections_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CollectionsScreen extends StatefulWidget {
  final Future<List<Collection>> personalCollections;
  final Future<List<Collection>> publicCollections;
  const CollectionsScreen({
    super.key,
    required this.personalCollections,
    required this.publicCollections,
  });

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  final double headerSize = 22;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  'Collections',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                  FutureBuilder(
                    future: widget.personalCollections,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else {
                        final collections = snapshot.data ?? [];
                        return _buildUserCollectionsList(
                          collections: collections,
                        );
                      }
                    },
                  ),
                  // _buildUserCollectionsList(collections: collec),
                  const SizedBox(height: 30),

                  // List of public Collections
                  FutureBuilder(
                    future: widget.publicCollections,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final collections = snapshot.data ?? [];
                      return _buildPublicCollectionsList(
                        collections: collections,
                      );
                    },
                  ), 
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCollectionsList({
    required List<Collection> collections, 
  }) {
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

        // If collection has any records, show these in Grid layout
        if (collections.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: collections.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 10,
              childAspectRatio: 2,
            ),
            itemBuilder: (context, index) {
              final item = collections[index];
              return _buildcollectionButton(
                icon: item.icon ?? Icons.star,
                title: item.title,
                nrOfSentences: item.nrOfSentences,
                onTap: () {},
              );
            },
          ),
        ],
        if (collections.isEmpty) ...[
          Center(
            child: Text(
              'No Collections saved yet. Create one or look through the public collections!',
              style: AppTextStyles.heading3,
            ),
          ),
        ],
        const SizedBox(height: 12),

        // Create new Collection button
        GestureDetector(
          onTap: () {
            context.push('/collections/create');
            setState(() {});
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
    );
  }

  Widget _buildPublicCollectionsList({required List<Collection> collections}) {
    final maxRows = 2;
    final columns = 2;
    final maxItems = maxRows * columns;

    // final List<String> collections = ["1", "2", "3", "4"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //
        Text(
          'Public Collections',
          style: TextStyle(
            color: Colors.white,
            fontSize: headerSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: collections.length > maxItems
              ? maxItems
              : collections.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 10,
            childAspectRatio: 1.9,
          ),
          itemBuilder: (context, index) {
            final item = collections[index];
            return _buildcollectionButton(
              icon: item.icon ?? Icons.star,
              title: item.title,
              nrOfSentences: item.nrOfSentences,
              onTap: () {},
            );
          },
        ),
        const SizedBox(height: 12),

        // Create new Collection button
        GestureDetector(
          onTap: () {}, // TODO
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
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 18),
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
                  Container(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
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
