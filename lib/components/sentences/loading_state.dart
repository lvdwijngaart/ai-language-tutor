

import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class LoadingState extends StatelessWidget {
  final String message;

  const LoadingState({
    super.key, 
    required this.message
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.electricBlue),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

}