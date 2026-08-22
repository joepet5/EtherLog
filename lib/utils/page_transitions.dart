import 'package:flutter/material.dart';

import '../services/profile_storage.dart';

/// Supported transition styles (stored in ProfileStorage).
class TransitionStyle {
  static const none = 'none';
  static const fade = 'fade';
  static const slideUp = 'slide_up';
  static const slideDown = 'slide_down';
  static const slideRight = 'slide_right';
  static const slideLeft = 'slide_left';
  static const scaleFade = 'scale_fade';
  static const zoomIn = 'zoom_in';
  static const sharedAxis = 'shared_axis';
  static const cupertino = 'cupertino';
  static const rotateFade = 'rotate_fade';
  static const sizeFade = 'size_fade';

  /// key → label for Profile UI chips
  static const labels = <String, String>{
    none: 'System default',
    fade: 'Fade',
    slideUp: 'Slide up',
    slideDown: 'Slide down',
    slideRight: 'Slide from right',
    slideLeft: 'Slide from left',
    scaleFade: 'Scale + fade',
    zoomIn: 'Zoom in',
    sharedAxis: 'Shared axis',
    cupertino: 'iOS style',
    rotateFade: 'Soft rotate',
    sizeFade: 'Expand + fade',
  };

  static const allKeys = <String>[
    none,
    fade,
    slideUp,
    slideDown,
    slideRight,
    slideLeft,
    scaleFade,
    zoomIn,
    sharedAxis,
    cupertino,
    rotateFade,
    sizeFade,
  ];
}

class AppPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final String style;

  AppPageRoute({required this.page, required this.style})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: _durationFor(style),
    reverseTransitionDuration: _reverseFor(style),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      switch (style) {
        case TransitionStyle.fade:
          return FadeTransition(opacity: curved, child: child);

        case TransitionStyle.slideUp:
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );

        case TransitionStyle.slideDown:
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.08),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );

        case TransitionStyle.slideRight:
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );

        case TransitionStyle.slideLeft:
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );

        case TransitionStyle.scaleFade:
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
              child: child,
            ),
          );

        case TransitionStyle.zoomIn:
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1).animate(curved),
              child: child,
            ),
          );

        case TransitionStyle.sharedAxis:
        // Horizontal shared-axis feel (Material motion)
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.15, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );

        case TransitionStyle.cupertino:
        // iOS-like full-width push from the right
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.linearToEaseOut,
              reverseCurve: Curves.easeInToLinear,
            )),
            child: child,
          );

        case TransitionStyle.rotateFade:
          return FadeTransition(
            opacity: curved,
            child: RotationTransition(
              turns: Tween<double>(begin: -0.01, end: 0).animate(curved),
              child: child,
            ),
          );

        case TransitionStyle.sizeFade:
          return FadeTransition(
            opacity: curved,
            child: Align(
              alignment: Alignment.center,
              child: SizeTransition(
                sizeFactor: Tween<double>(begin: 0.92, end: 1).animate(curved),
                axisAlignment: 0,
                child: child,
              ),
            ),
          );

        case TransitionStyle.none:
        default:
          return child;
      }
    },
  );

  static Duration _durationFor(String style) {
    switch (style) {
      case TransitionStyle.none:
        return const Duration(milliseconds: 200);
      case TransitionStyle.cupertino:
        return const Duration(milliseconds: 400);
      case TransitionStyle.zoomIn:
        return const Duration(milliseconds: 360);
      default:
        return const Duration(milliseconds: 320);
    }
  }

  static Duration _reverseFor(String style) {
    switch (style) {
      case TransitionStyle.cupertino:
        return const Duration(milliseconds: 350);
      default:
        return const Duration(milliseconds: 280);
    }
  }

  /// Push [page] using the user's preferred transition from ProfileStorage.
  static Future<T?> push<T>(BuildContext context, Widget page, {bool noAnimation = false}) async {
    if (noAnimation) {
      return Navigator.push<T>(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
    final style = await ProfileStorage.getTransitionStyle();
    if (style == TransitionStyle.none) {
      return Navigator.push<T>(
        context,
        PageRouteBuilder(transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero, pageBuilder: (_, __, ___) => page),
      );
    }
    return Navigator.push<T>(
      context,
      AppPageRoute<T>(page: page, style: style),
    );
  }

  /// Replace current route with preferred transition.
  static Future<T?> pushReplacement<T, TO>(
      BuildContext context,
      Widget page, {
        TO? result,
      }) async {
    final style = await ProfileStorage.getTransitionStyle();
    if (style == TransitionStyle.none) {
      return Navigator.pushReplacement<T, TO>(
        context,
        PageRouteBuilder(transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero, pageBuilder: (_, __, ___) => page),
        result: result,
      );
    }
    return Navigator.pushReplacement<T, TO>(
      context,
      AppPageRoute<T>(page: page, style: style),
      result: result,
    );
  }
}