import 'package:flutter/material.dart';

class AppShadow {
  AppShadow._();

  static List<BoxShadow> card(bool isDark) => isDark ? [] : [
    const BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static List<BoxShadow> cardHover(bool isDark) => isDark ? [] : [
    const BoxShadow(color: Color(0x12000000), blurRadius: 16, offset: Offset(0, 4)),
  ];
  static List<BoxShadow> bottomNav(bool isDark) => isDark ? [] : [
    const BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, -2)),
  ];
  static List<BoxShadow> bottomSheet(bool isDark) => isDark ? [] : [
    const BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, -8)),
  ];
  static List<BoxShadow> fab(bool isDark) => isDark ? [] : [
    const BoxShadow(color: Color(0x29000000), blurRadius: 16, offset: Offset(0, 4)),
  ];
}
