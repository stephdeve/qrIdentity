import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _lightPrimary = Color(0xFF5B86E5);
  static const _lightSecondary = Color(0xFF36D1DC);
  static const _darkPrimary = Color(0xFF7F00FF);
  static const _darkSecondary = Color(0xFFE100FF);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _lightPrimary,
      primary: _lightPrimary,
      secondary: _lightSecondary,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _darkPrimary,
      primary: _darkPrimary,
      secondary: _darkSecondary,
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
  );

  static Gradient get mainGradient => const LinearGradient(
        colors: [Color(0xFF5B86E5), Color(0xFF36D1DC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static Gradient get darkGradient => const LinearGradient(
        colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
