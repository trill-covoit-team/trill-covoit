import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'tokens.dart';

class AppFadeThroughTransitionsBuilder extends PageTransitionsBuilder {
  const AppFadeThroughTransitionsBuilder();

  @override
  Duration get transitionDuration => AppMotion.normal;

  @override
  Duration get reverseTransitionDuration => AppMotion.normal;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return FadeThroughTransition(
      animation: animation.drive(CurveTween(curve: AppMotion.emphasized)),
      secondaryAnimation: secondaryAnimation.drive(
        CurveTween(curve: AppMotion.emphasized),
      ),
      fillColor: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }
}

class AppCupertinoTransitionsBuilder extends CupertinoPageTransitionsBuilder {
  const AppCupertinoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => MediaQuery.disableAnimationsOf(context)
      ? child
      : super.buildTransitions(
          route,
          context,
          animation,
          secondaryAnimation,
          child,
        );
}
