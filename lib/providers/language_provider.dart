

import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Language _selectedLanguage = Language.spanish;

  Language get selectedLanguage => _selectedLanguage;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString('selected_language');

      if (savedLanguageCode != null) {
        _selectedLanguage = Language.fromCode(savedLanguageCode);
        notifyListeners();
      }
    } catch (e) {
      // Handle error TODO
    }
  }

  void changeLanguage(Language newLanguage) {
    if (_selectedLanguage == newLanguage) return;

    _selectedLanguage = newLanguage;
    _saveLanguage();
    notifyListeners();
  }

  Future<void> _saveLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_language', _selectedLanguage.localeCode);
    } catch (e) {
      // Handle error TODO
    }
  }
}