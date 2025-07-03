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
    initialLocation: '/', 
    refreshListenable: _AuthNotifier(),
    redirect: (context, state) {
      final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      // If user is logged in and trying to access auth routes, redirect to home
      if (isLoggedIn && isAuthRoute) {
        return '/chat';
      }

      // If user is not logged in and trying to access home, redirect to login
      if (!isLoggedIn && !isAuthRoute) {
        return '/auth/login';
      }

      return null; // No redirect needed
    }, 
    routes: [
      GoRoute(
        path: '/', 
        redirect:(context, state) {
          final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
          return isLoggedIn ? '/chat' : '/auth/login';
        },
      ), 

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
      // GoRoute(
      //   path: '/home',
      //   name: 'home',
      //   builder: (context, state) => const HomeScreenAlt2(),
      // ),
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) => const ChatScreen(),
      ),
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
    }
  );
}
