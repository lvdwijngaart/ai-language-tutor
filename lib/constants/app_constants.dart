import 'package:flutter/material.dart';

class AppColors {
  // Dark theme colors based on PROJECT_SPEC.md
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color primaryText = Color(0xFFE0E0E0);
  static const Color electricBlue = Color(0xFF3A86FF);
  static const Color secondaryAccent = Color(0xFF2EC4B6);
  
  // Additional colors for better UI
  static const Color cardBackground = Color(0xFF2A2A2A);
  static const Color inputBackground = Color(0xFF333333);
  static const Color errorColor = Color(0xFFFF6B6B);
  static const Color successColor = Color(0xFF51CF66);
  static const Color disabledColor = Color(0xFF666666);
}

class AppTextStyles {
  static const TextStyle pageHeader = TextStyle(
    color: Colors.white,
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.primaryText,
  );
  
  static TextStyle caption = TextStyle(
    fontSize: 14,
    color: AppColors.primaryText.withOpacity(0.7),
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

class AppSpacing {
  static const double xs = 4.0;
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}
