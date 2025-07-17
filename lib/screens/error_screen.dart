import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_lang_tutor_v2/constants/app_constants.dart';

class ErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  final bool showGoBackButton;
  final String? customBackRoute;
  final IconData icon;

  const ErrorScreen({
    Key? key,
    this.title = 'Something Went Wrong',
    this.message = 'An unexpected error occurred. Please try again.',
    this.showGoBackButton = true,
    this.customBackRoute,
    this.icon = Icons.error_outline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text('Error'),
        backgroundColor: AppColors.darkBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: showGoBackButton
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => _handleGoBack(context),
              )
            : null,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ Error icon
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 64,
                  color: Colors.red,
                ),
              ),
              
              SizedBox(height: 32),
              
              // ✅ Error title
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 16),
              
              // ✅ Error message
              Text(
                message,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 48),
              
              // ✅ Action buttons
              if (showGoBackButton) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleGoBack(context),
                        icon: Icon(Icons.arrow_back),
                        label: Text('Go Back'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cardBackground,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(width: 16),
                    
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/home/collections'),
                        icon: Icon(Icons.home),
                        label: Text('Home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryAccent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleGoBack(BuildContext context) {
    if (customBackRoute != null) {
      context.go(customBackRoute!);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home/collections'); // Fallback route
    }
  }
}