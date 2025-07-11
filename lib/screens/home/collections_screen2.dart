import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CollectionsScreen extends StatelessWidget {
  final double headerSize = 26;

  const CollectionsScreen({
    super.key,
    // Possibly other parameters
  });

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
                  const SizedBox(height: 20),

                  // List of user's Collections
                  _buildUserCollectionsList(),
                  const SizedBox(height: 20),

                  // List of public Collections
                  _buildPublicCollectionsList(),
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
    Map<String, dynamic>?
    map,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //
        Text(
          'Your Collections',
          style: TextStyle(
            color: Colors.white,
            fontSize: headerSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          spacing: 16,
          children: [
            _buildcollectionButton(
              icon: Icons.abc,
              title: 'French Basics',
              nrOfSentences: 20,
              onTap: () {},
            ),

            _buildcollectionButton(
              icon: Icons.text_decrease,
              title: 'French basics and shit',
              nrOfSentences: 20,
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Create new Collection button
        GestureDetector(
          onTap: () {}, 
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

  Widget _buildPublicCollectionsList() {
    final maxRows = 2;
    final columns = 2;
    final maxItems = maxRows * columns;

    final List<String> collections = ["1", "2", "3", "4"];

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
              icon: Icons.subject,
              title: 'French Basics',
              nrOfSentences: 20,
              onTap: () {},
            );
          },
        ),
        const SizedBox(height: 16),

        // Create new Collection button
        GestureDetector(
          onTap: () {}, 
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 49, 206, 101).withOpacity(0.9),
                  const Color.fromARGB(255, 58, 255, 183).withOpacity(0.9),
                ],
              ),
              // color: AppColors.cardBackground,
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.secondaryAccent.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.secondaryAccent, size: 48),
              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
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
              AppColors.secondaryAccent,
              const Color.fromARGB(255, 58, 255, 189),
              // const Color(0xFF2EC4B6)
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryAccent,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
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
