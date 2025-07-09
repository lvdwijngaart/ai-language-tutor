

import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/screens/home/collections_screen.dart';
import 'package:ai_lang_tutor_v2/screens/home/home_screen.dart';
import 'package:ai_lang_tutor_v2/screens/home/practice_screen.dart';
import 'package:flutter/material.dart';

class BottomNavigation extends StatefulWidget{
  final int initialIndex;

  const BottomNavigation({
    super.key, 
    this.initialIndex = 0
  });

  @override
  State<StatefulWidget> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  late int _selectedIndex;

  final List<Widget> _screens = const [
    HomeScreen(), 
    CollectionsScreen(), 
    PracticeScreen(), 
    HomeScreen(), 
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground, 
          boxShadow: [ 
            BoxShadow(
              color: Colors.black.withOpacity(0.3), 
              blurRadius: 10, 
              offset: const Offset(0, -2)
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
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home), 
              label: 'Home', 
            ), 
            BottomNavigationBarItem(
              icon: Icon(Icons.collections_bookmark), 
              label: 'Collections'
            ), 
            BottomNavigationBarItem(
              icon: Icon(Icons.quiz), 
              label: 'Pracitce'
            ), 
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Social'
            )
          ]
        ),
      ),
    );

    
  }
}