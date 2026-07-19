import 'package:flutter/material.dart';

class NexaColors {
  static const navy = Color(0xFF0B1D3A);
  static const navy2 = Color(0xFF0D2348);
  static const navy3 = Color(0xFF162F5A);
  static const blue = Color(0xFF126BFF);
  static const blue2 = Color(0xFF3D87FF);
  static const blueLight = Color(0xFFE8F1FF);
  static const purple = Color(0xFF6D3CFF);
  static const purpleLight = Color(0xFFEDE8FF);
  static const gold = Color(0xFFFFc107);
  static const goldLight = Color(0xFFFFF8E1);
  static const bg = Color(0xFFF3F6FB);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFDDE3EE);
  static const txt = Color(0xFF0B1D3A);
  static const txt2 = Color(0xFF4A5568);
  static const txt3 = Color(0xFF8FA3C0);
  static const green = Color(0xFF10B981);
  static const red = Color(0xFFEF4444);
  static const orange = Color(0xFFF97316);
}

class NexaTheme {
  static ThemeData get theme => ThemeData(
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: NexaColors.bg,
    colorScheme: const ColorScheme.light(
      primary: NexaColors.blue,
      secondary: NexaColors.purple,
      surface: NexaColors.card,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: NexaColors.navy,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
    color: NexaColors.card,
    elevation: 0,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: const BorderSide(color: NexaColors.border),
  ),
),
  );
}
