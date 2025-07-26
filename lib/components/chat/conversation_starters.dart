

import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:flutter/material.dart';

class ConversationStarters extends StatelessWidget{
  final ProficiencyLevel proficiencyLevel;
  final Function(String) onStarterTapped;
  

  const ConversationStarters({
    super.key, 
    required this.proficiencyLevel, 
    required this.onStarterTapped,
  });

  @override 
  Widget build(BuildContext context) {
    final List<String> conversationStarters = _getConversationStarters(proficiencyLevel);

    return Container(
      margin: EdgeInsets.only(top: 15, left: 45, bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What would you like to talk about?', 
            style: TextStyle(
              color: Colors.white, 
              fontSize: 14, 
              fontWeight: FontWeight.bold
            ),
          ), 
          SizedBox(height: 8), 
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...conversationStarters.map((starter) => 
                _buildConversationStarterButton(starter),
              )
            ]
          ),   
        ],
      ),
    );
  }


  Widget _buildConversationStarterButton(String conversationStarter) {
    return GestureDetector(
      onTap: () => onStarterTapped(conversationStarter),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.electricBlue.withValues(alpha: 0.15), 
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.3), width: 1)
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline, 
              size: 16, 
              color: AppColors.electricBlue,
            ), 
            SizedBox(width: 6), 
            Text(
              conversationStarter, 
              style: const TextStyle(
                color: AppColors.electricBlue, 
                fontSize: 13, 
                fontWeight: FontWeight.w500
              ),
            )
          ],
        ),
      ),
    );
  }

  List<String> _getConversationStarters(ProficiencyLevel proficiencyLevel) {
    switch (proficiencyLevel) {
      case ProficiencyLevel.beginner: 
        return [
          'Introduce myself',
          'Order food at a restaurant', 
          'Ask for directions',
          'Talk about hobbies',
          'Discuss the weather',
        ];
      
      case ProficiencyLevel.intermediate: 
        return [
          'Plan a vacation',
          'Discuss current events',
          'Share opinions about movies',
          'Talk about work/career',
          'Describe cultural differences',
        ];
      
      case ProficiencyLevel.advanced: 
        return [
          'Debate environmental issues',
          'Analyze literature/philosophy',
          'Discuss business strategies',
          'Explore historical events',
          'Express complex emotions',
        ];
      
    }
  }
}