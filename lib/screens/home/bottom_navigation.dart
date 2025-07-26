import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/database/collection.dart';
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/providers/collections_provider.dart';
import 'package:ai_lang_tutor_v2/providers/language_provider.dart';
import 'package:ai_lang_tutor_v2/screens/home/collections_screen.dart';
import 'package:ai_lang_tutor_v2/screens/home/home_screen.dart';
import 'package:ai_lang_tutor_v2/screens/home/practice_screen.dart';
import 'package:ai_lang_tutor_v2/screens/placeholder_screen.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/collections_service.dart';
import 'package:ai_lang_tutor_v2/services/supabase_client.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class BottomNavigation extends StatefulWidget {
  final int initialIndex;

  const BottomNavigation({super.key, this.initialIndex = 0});

  @override
  State<StatefulWidget> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  late int _selectedIndex;
  late PageController _pageController;

  bool _collectionsInitialized = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.ease,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageProvider, CollectionsProvider>(
      builder: (context, languageProvider, collectionsProvider, child) {
        if (!_collectionsInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            collectionsProvider.loadCollections(languageProvider.selectedLanguage);
            _collectionsInitialized = true;
          });
        }

        final List<Widget> screens = [
          HomeScreen(),
          CollectionsScreen(),
          // PracticeScreen(),
          PlaceholderScreen(title: 'Practice', icon: Icons.quiz, color: const Color(0xFFFFB800)),
          // HomeScreen(),
          PlaceholderScreen(title: 'Social', icon: Icons.people, color: const Color(0xFF6C5CE7 ))
        ];

        return Scaffold(
          backgroundColor: AppColors.darkBackground,
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            // Prevent swipe if you want only nav bar control:
            // physics: const NeverScrollableScrollPhysics(), 
            children: screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              selectedItemColor: AppColors.electricBlue,
              unselectedItemColor: Colors.white60,
              onTap: _onTabTapped,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.collections_bookmark),
                  label: 'Collections',
                ),
                BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Practice'),
                BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Social'),
              ],
            ),
          ),
        );
      }
    );
  }
}
