import 'package:ai_lang_tutor_v2/router/app_router.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'constants/app_constants.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  _setupOpenAI(); 
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AI Language Tutor',
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          background: AppColors.darkBackground,
          primary: AppColors.electricBlue,
          secondary: AppColors.secondaryAccent,
          surface: AppColors.cardBackground,
          error: AppColors.errorColor,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}

void _setupOpenAI() {
  if (dotenv.env['OPENAI_API_KEY'] == null || dotenv.env['OPENAI_API_KEY']!.isEmpty) {
    print("OPENAI API KEY is not defined. ");
    return;
  }

  OpenAI.apiKey = dotenv.env['OPENAI_API_KEY']!;

}
