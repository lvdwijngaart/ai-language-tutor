import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:flutter/material.dart';

class SentenceSuggestions extends StatefulWidget {
  const SentenceSuggestions({super.key});

  @override
  State<StatefulWidget> createState() => _SentenceSuggestionState();
}

class _SentenceSuggestionState extends State<SentenceSuggestions> {
  @override
  void setState(VoidCallback fn) {
    // TODO: implement setState
    super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(''),
      // ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(left: 20, right: 20, top: 60, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Your collection was added succesfully!', 
                  style: TextStyle(
                    color: AppColors.successColor.withOpacity(0.7), 
                    fontSize: 18, 
                    fontWeight: FontWeight.bold
                  ),
                )
              ),
              const SizedBox(height: 30), 

              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('This will be an example sentence'),
                  ),
                ],
              ),
            ],
          ),
        )
      ),
    );
  }
}
