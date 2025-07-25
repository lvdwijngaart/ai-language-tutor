import 'dart:ui';

import 'package:ai_lang_tutor_v2/components/home/language_selector.dart';
import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/providers/language_provider.dart';
import 'package:ai_lang_tutor_v2/services/supabase/profiles_service.dart';
import 'package:ai_lang_tutor_v2/services/supabase_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    // Possible other states
  });
  
  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  // @override
  // void setState(VoidCallback fn) {
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top header with greeting
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good evening!', // TODO: Replace with time of day
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              constraints: BoxConstraints(maxWidth: 180),
                              child: Text(
                                supabase.auth.currentUser?.email
                                        ?.split('@')
                                        .first ??
                                    'Anonymous user', // TODO: Replace with user's name or smth
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Language Selector
                        CompactLanguageSelector(),
                        const SizedBox(width: 10),

                        // Settings button
                        PopupMenuButton(
                          onSelected: (String value) async {
                            switch (value) {
                              case 'settings': 
                                context.go('/settings');
                                break;
                              case 'profile': 
                                context.go('/profile');
                                break;
                              case 'logout': 
                                await supabase.auth.signOut();
                                break;
                            }
                          },
                          icon: Icon(Icons.settings, color: Colors.white, size: 30),
                          color: AppColors.cardBackground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppColors.electricBlue.withValues(alpha: 0.3)),
                          ),
                          itemBuilder: (BuildContext popupMenuContext) => [
                            PopupMenuItem<String>(
                              value: 'settings',
                              child: Row(
                                children: [
                                  Icon(Icons.settings, color: AppColors.electricBlue, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Settings',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'profile',
                              child: Row(
                                children: [
                                  Icon(Icons.person, color: AppColors.electricBlue, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Profile',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout, color: Colors.red, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Log Out',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ]
                        )
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Build Menu and Buttons
                _buildActionButtons(context),
                const SizedBox(height: 24),

                // Progress view
                _buildProgressOverview(),
                const SizedBox(height: 24),

                // Quick Actions List
                _buildQuickActionsList(context),
              ],
            ), 
          )
        );
      }
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Primary action - AI Chat
        GestureDetector(
          onTap: () => context.go('/chat'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.electricBlue, AppColors.secondaryAccent],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.electricBlue,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Chat bubble icon
                Icon(Icons.chat_bubble_outline, color: Colors.white, size: 32),
                const SizedBox(width: 16),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start AI Conversation',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Practice with your AI language tutor',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildSecondaryCard(
                title: 'Collections',
                description: 'Manage words',
                accentColor: AppColors.secondaryAccent,
                icon: Icons.collections_bookmark,
                onTap: () async {
                  context.go('/home/collections');
                }, // TODO
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSecondaryCard(
                title: 'Practice',
                description: 'Test your knowledge',
                accentColor: const Color(0xFFFFB800),
                icon: Icons.quiz,
                onTap: () => {context.go('/home/practice')}, // TODO
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryCard({
    required String title,
    required String description,
    required Color accentColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              description,
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Progress overview container
  Widget _buildProgressOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: AppColors.electricBlue, size: 24),
              const SizedBox(width: 8),
              Text(
                'Progress Overview',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '0', // TODO
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Day Streak',
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '0', // TODO
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Words Learned',
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        _buildQuickActionButton(
          icon: Icons.add,
          title: 'Create New Collection',
          description: 'Start building your word library',
          onTap: () {
            context.push('/collections/create');
            setState(() {});
          },
        ),

        _buildQuickActionButton(
          icon: Icons.people,
          title: 'Connect with Friends',
          description: 'Find language learning partners',
          onTap: () => {},
        ),

        _buildQuickActionButton(
          icon: Icons.analytics,
          title: 'View Study Statistics',
          description: 'Track your learning progress',
          onTap: () => {},
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        tileColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.electricBlue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.electricBlue, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.white70,
          size: 16,
        ),
      ),
    );
  }
}
