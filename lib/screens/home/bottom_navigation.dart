import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/database/collection.dart';
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/screens/home/collections_screen.dart';
import 'package:ai_lang_tutor_v2/screens/home/home_screen.dart';
import 'package:ai_lang_tutor_v2/screens/home/practice_screen.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/collections_service.dart';
import 'package:ai_lang_tutor_v2/services/supabase_client.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class BottomNavigation extends StatefulWidget {
  final int initialIndex;

  const BottomNavigation({super.key, this.initialIndex = 0});

  @override
  State<StatefulWidget> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  late int _selectedIndex;
  late PageController _pageController;

  late Future<List<Collection>> _personalCollections;
  late Future<List<Collection>> _publicCollections;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _selectedIndex);
    _personalCollections = CollectionsService.getPersonalCollections(
      userId: supabase.auth.currentUser!.id,
    );
    Logger _logger = Logger();
    _publicCollections = CollectionsService.getHighlightCollections(
      nrOfResults: 4,
      language: Language.spanish,
      userId: supabase.auth.currentUser!.id
    );
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
    final List<Widget> _screens = [
      HomeScreen(),
      CollectionsScreen(
        personalCollections: _personalCollections,
        publicCollections: _publicCollections,
      ),
      PracticeScreen(),
      HomeScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: PageView(
        controller: _pageController,
        children: _screens,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        physics:
            const NeverScrollableScrollPhysics(), // Prevent swipe if you want only nav bar control
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
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
}
