

import 'package:ai_lang_tutor_v2/models/app_enums.dart';
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
    return Container(

    );
  }
}