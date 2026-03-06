import 'package:flutter/material.dart';

class AppAnimation {
  AppAnimation._();
  // Duration
  static const Duration instant = Duration(milliseconds: 50);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration emphasis = Duration(milliseconds: 600);
  // Curves
  static const Curve decelerate = Curves.easeOutCubic;
  static const Curve accelerate = Curves.easeInCubic;
  static const Curve standard = Curves.easeInOutCubic;
  // Page transition
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Curve pageEnter = Curves.easeOutCubic;
  static const Curve pageExit = Curves.easeInCubic;
}
