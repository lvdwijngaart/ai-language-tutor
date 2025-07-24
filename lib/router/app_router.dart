import 'package:ai_lang_tutor_v2/constants/app_transitions.dart';
import 'package:ai_lang_tutor_v2/models/database/collection.dart';
import 'package:ai_lang_tutor_v2/screens/collections/collection_form_screen.dart';
import 'package:ai_lang_tutor_v2/screens/collections/public_collections_screen.dart';
import 'package:ai_lang_tutor_v2/screens/collections/sentence_screen.dart';
import 'package:ai_lang_tutor_v2/screens/collections/sentence_suggestions.dart';
import 'package:ai_lang_tutor_v2/screens/collections/single_collection_screen.dart';
import 'package:ai_lang_tutor_v2/screens/error_screen.dart';
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
          return AppTransitions.slideUptransition(key: state.pageKey, child: CollectionFormScreen(mode: CollectionFormMode.create));
        }
      ),
      GoRoute(
        path: '/collections/:id/suggested-sentences', 
        name: 'sentence-suggestions', 
        builder: (context, state) {
          final collection = state.extra as Collection;
          return SentenceSuggestions(collection: collection);
        }
      ), 
      GoRoute(
        path: '/collections/public-collections', 
        name: 'public-collections',
        builder: (context, state) {
          return PublicCollectionsScreen();
        }
      ), 
      GoRoute(
        path: '/collections/:id/view',
        name: 'single-collection-view', 
        pageBuilder: (context, state) {
          final String? collectionId = state.pathParameters['id'];

          if (collectionId == null || collectionId.isEmpty) {
            return MaterialPage(
              child: ErrorScreen(
                title: 'Collection Not Found', 
                message: 'The collection ID is missing or invalid', 
                showGoBackButton: true
              ),
            );
          }

          return AppTransitions.slideUptransition(
            key: state.pageKey,
            child: SingleCollectionScreen(collectionId: collectionId),
            duration: Duration(milliseconds: 1500)
          );
        }
      ), 

      GoRoute(
        path: '/collections/:id/edit', 
        name: 'edit-collection', 
        builder: (context, state) {
          final collection = state.extra as Collection;
          return CollectionFormScreen(mode: CollectionFormMode.edit, existingCollection: collection);
        },
      ), 

      GoRoute(
        path: '/collections/:id/add-sentences', 
        name: 'add-sentences',
        builder: (context, state) {
          final String collectionId = state.pathParameters['id']!;
          final collection = state.extra as Collection;
          return AddSentencesScreen(collectionId: collectionId, collection: collection);
        },
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
