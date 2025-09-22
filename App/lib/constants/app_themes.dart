import 'package:flutter/material.dart';

class AppThemes {
  // Your brand colors
  static const Color primaryCyan = Color(0xFF2DC5F7);
  static const Color secondaryCyan = Color(0xFF01FFFF);
  static const Color darkBackground = Color(0xFF000000);

  // --- LIGHT THEME ---
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryCyan,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5), // A slightly off-white for comfort
    colorScheme: const ColorScheme.light(
      primary: primaryCyan,
      secondary: secondaryCyan,
      background: Color(0xFFF5F5F5),
      onBackground: Colors.black,
      surface: Colors.white,
      onSurface: Colors.black,
      error: Colors.redAccent,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 1,
      iconTheme: IconThemeData(color: Colors.black),
    ),
    cardColor: Colors.white,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryCyan,
        foregroundColor: Colors.white,
      ),
    ),
  );

  // --- DARK THEME ---
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryCyan,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: primaryCyan,
      secondary: secondaryCyan,
      background: darkBackground,
      onBackground: Colors.white,
      surface: Color(0xFF1C1C1E), // A slightly lighter black for surfaces
      onSurface: Colors.white,
      error: Colors.red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1C1C1E),
      foregroundColor: Colors.white,
    ),
    cardColor: const Color(0xFF1C1C1E),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryCyan,
        foregroundColor: Colors.black, // Black text on bright cyan looks great
      ),
    ),
  );
}