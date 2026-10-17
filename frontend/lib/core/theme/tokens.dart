import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0F766E);
  static const primarySoft = Color(0xFFE0F2F1);
  static const accent = Color(0xFFF59E0B);

  static const success = Color(0xFF15803D);
  static const warning = Color(0xFFB45309);
  static const error = Color(0xFFB42318);
  static const errorDark = Color(0xFFFDA29B);

  static const bg = Color(0xFFF6F8F9);
  static const surface = Colors.white;
  static const surfaceAlt = Color(0xFFEEF2F3);
  static const border = Color(0xFFD9E1E4);
  static const textPrimary = Color(0xFF0F1B1E);
  static const textSecondary = Color(0xFF55666B);

  static const bgDark = Color(0xFF0B1416);
  static const surfaceDark = Color(0xFF121E21);
  static const surfaceAltDark = Color(0xFF1A2A2E);
  static const borderDark = Color(0xFF2A3D42);
  static const textPrimaryDark = Color(0xFFE8F0F2);
  static const textSecondaryDark = Color(0xFF9DB1B6);
  static const primaryOnDark = Color(0xFF2DD4BF);
  static const onPrimaryDark = Color(0xFF04211E);
}

class AppSpace {
  static const double s4 = 4, s8 = 8, s12 = 12, s16 = 16;
  static const double s24 = 24, s32 = 32, s48 = 48;
}

class AppRadius {
  static const double sm = 8, md = 14, lg = 24;
}

class AppShadow {
  static const low = [
    BoxShadow(color: Color(0x0F0F1B1E), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const high = [
    BoxShadow(color: Color(0x1F0F1B1E), blurRadius: 24, offset: Offset(0, 8)),
  ];
}

class AppMotion {
  static const fast = Duration(milliseconds: 200);
  static const normal = Duration(milliseconds: 300);
  static const curve = Curves.easeOutCubic;
}

const double kMinTouch = 48;
