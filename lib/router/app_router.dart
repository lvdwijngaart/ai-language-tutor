import 'package:ai_lang_tutor_v2/constants/app_transitions.dart';
import 'package:ai_lang_tutor_v2/models/database/collection.dart';
import 'package:ai_lang_tutor_v2/screens/collections/add_collection_screen.dart';
import 'package:ai_lang_tutor_v2/screens/collections/sentence_suggestions.dart';
import 'package:ai_lang_tutor_v2/screens/home/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/reset_password_screen.dart';
// import '../screens/auth/new_password_screen.dart';
import '../screens/chat/chat_screen.dart';

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home/home',
    refreshListenable: _AuthNotifier(),
    redirect: (context, state) {
      final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      // If user is logged in and trying to access auth routes, redirect to home
      if (isLoggedIn && isAuthRoute) {
        return '/home/home';
      }

      // If user is not logged in and trying to access home, redirect to login
      if (!isLoggedIn && !isAuthRoute) {
        return '/auth/login';
      }

      return null; // No redirect needed
    },
    routes: [
      // GoRoute(
      //   path: '/',
      //   redirect:(context, state) {
      //     final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
      //     return isLoggedIn ? '/chat' : '/auth/login';
      //   },
      // ),

      // Authentication routes
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/reset-password',
        name: 'reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      // GoRoute(
      //   path: '/auth/new-password',
      //   name: 'new-password',
      //   builder: (context, state) {
      //     final accessToken = state.uri.queryParameters['access_token'];
      //     final refreshToken = state.uri.queryParameters['refresh_token'];
      //     return NewPasswordScreen(
      //       accessToken: accessToken,
      //       refreshToken: refreshToken,
      //     );
      //   },
      // ),

      // Main app routes
      GoRoute(
        path: '/home/:tab',
        name: 'home-tab',
        builder: (context, state) {
          final tab = state.pathParameters['tab'] ?? 'home';
          int initialIndex = 0;
          switch (tab) {
            case 'collections':
              initialIndex = 1;
              break;
            case 'practice':
              initialIndex = 2;
              break;
            case 'social':
              initialIndex = 3;
              break;
            default:
              initialIndex = 0;
          }
          return BottomNavigation(initialIndex: initialIndex);
        },
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        redirect: (context, state) => '/home/home',
      ),
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/collections/create',
        name: 'create-new-collection',
        pageBuilder: (context, state) { 
          return AppTransitions.slideUptransition(key: state.pageKey, child: AddCollectionScreen());
        }
      ),
      GoRoute(
        path: '/collections/:id/suggested-sentences', 
        name: 'sentence-suggestions', 
        builder: (context, state) {
          final collection = state.extra as Collection;
          return SentenceSuggestions(collection: collection);
        }
      )
    ],

    // Error page
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text(
            'Error: ${state.error}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    },
  );
}
