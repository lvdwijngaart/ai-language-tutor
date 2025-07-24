

import 'package:ai_lang_tutor_v2/screens/collections/collection_form_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class AppTransitions {

  // Slide up transition with pause and set speed. Works for ListTile objects
  static slideUptransition({
    required LocalKey key, 
    required Widget child, 
    Duration duration = const Duration(milliseconds: 500)
  }) {
    return CustomTransitionPage(
      key: key,
      child: child,
      transitionDuration: Duration(milliseconds: 500),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0, 1);
        const end = Offset.zero;
        const curve = Curves.ease;
        const wait = 0.4;
        final delayedAnimation = CurvedAnimation(
          parent: animation,
          curve: Interval(
            wait, 1,
            curve: curve
          ),
        );
        final tween = Tween(
          begin: begin,
          end: end,
        );
        return SlideTransition(
          position: delayedAnimation.drive(tween),
          child: child,
        );
      },
    );
  }
          
}