import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const background = Color(0xFFF5F7FB);
  const surface = Color(0xFFFFFFFF);
  const card = Color(0xFFFFFFFF);
  const primaryBlue = Color(0xFF2F6DDE);
  const ink = Color(0xFF111827);
  const muted = Color(0xFF6B7280);
  const line = Color(0xFFE5E7EB);

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: Color(0xFF22C55E),
      surface: surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: ink,
      centerTitle: false,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: line),
      ),
    ),
    dividerColor: line,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primaryBlue,
      unselectedItemColor: muted,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
      type: BottomNavigationBarType.fixed,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      hintStyle: const TextStyle(color: muted),
      labelStyle: const TextStyle(color: muted),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: line),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryBlue),
      ),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: ink),
      bodySmall: TextStyle(color: muted),
    ),
  );
}
