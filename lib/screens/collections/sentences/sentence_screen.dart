import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/screens/collections/sentences/sentence_screen_tabs/ai_suggestion_tab.dart';
import 'package:ai_lang_tutor_v2/screens/collections/sentences/sentence_screen_tabs/custom_sentence_tab.dart';
import 'package:ai_lang_tutor_v2/screens/collections/sentences/sentence_screen_tabs/search_tab.dart';
import 'package:flutter/material.dart';
import 'package:ai_lang_tutor_v2/models/database/collection.dart';

enum AddSentenceMode { suggestions, wordSearch, custom }

class AddSentencesScreen extends StatefulWidget {
  final String collectionId;
  final Collection collection;

  const AddSentencesScreen({
    super.key, 
    required this.collectionId, 
    required this.collection
  });

  @override
  State<AddSentencesScreen> createState() => _AddSentencesScreenState();
}

class _AddSentencesScreenState extends State<AddSentencesScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                AiSuggestionTab(
                  collection: widget.collection, 
                ),
                SearchTab(
                  collection: widget.collection, 
                ),
                CustomSentenceTab(
                  collection: widget.collection,
                ),
              ],
            ),
          ),
          // _buildBottomActions(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.darkBackground,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Sentences'),
          Text(
            widget.collection.title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        // TODO: Figure out if I need this?
        // if (_selectedSentences.isNotEmpty)
        //   Container(
        //     margin: EdgeInsets.only(right: 16),
        //     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        //     decoration: BoxDecoration(
        //       color: AppColors.electricBlue,
        //       borderRadius: BorderRadius.circular(16),
        //     ),
        //     child: Text(
        //       '${_selectedSentences.length} selected',
        //       style: TextStyle(
        //         color: Colors.white,
        //         fontWeight: FontWeight.bold,
        //         fontSize: 12,
        //       ),
        //     ),
        //   ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.darkBackground,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.electricBlue,
        unselectedLabelColor: Colors.white70,
        indicatorColor: AppColors.electricBlue,
        tabs: [
          Tab(
            icon: Icon(Icons.auto_awesome),
            text: 'Suggestions',
          ),
          Tab(
            icon: Icon(Icons.search),
            text: 'Word Search',
          ),
          Tab(
            icon: Icon(Icons.create),
            text: 'Custom',
          ),
        ],
      ),
    );
  }

}