import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Controlled Palette (Dashboard Accent System)
  static const Color accentBlue = Color(0xFF007AFF);
  static const Color accentOrange = Color(0xFFFF9500);
  static const Color accentGreen = Color(0xFF34C759);
  static const Color accentPurple = Color(0xFFAF52DE);

  // Soft Dark Palette
  static const Color background = Color(0xFF1C1C1E);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceElevated = Color(0xFF2C2C2E);
  
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textMuted = Color(0xFF48484A);

  // Compatibility getters for the new screens
  static Color get backgroundColor => background;
  static Color get accentColor => accentBlue;
  
  static TextStyle get labelStyle => GoogleFonts.outfit(
    color: textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  static TextStyle get bodyStyle => GoogleFonts.outfit(
    color: textPrimary.withOpacity(0.85),
    fontSize: 16,
    height: 1.5,
  );

  static TextStyle get aiTextStyle => GoogleFonts.outfit(
    color: accentBlue,
    fontSize: 16,
    height: 1.5,
  );

  static TextStyle get pronunciationStyle => GoogleFonts.outfit(
    color: accentBlue,
    fontSize: 16,
    fontStyle: FontStyle.italic,
  );

  static InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(color: textSecondary),
      fillColor: surface,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.all(16),
    );
  }

  static ThemeData get softDarkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      // Default to Secondary Font: Outfit
      fontFamily: GoogleFonts.outfit().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: accentBlue,
        surface: surface,
        onSurface: textPrimary,
        secondary: accentPurple,
        tertiary: accentOrange,
        error: Color(0xFFFF453A),
      ),
      scaffoldBackgroundColor: background,
      
      // Typography overrides for Primary Font: Instrument Serif
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.instrumentSerif(
          textStyle: const TextStyle(
            color: textPrimary,
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        headlineMedium: GoogleFonts.instrumentSerif(
          textStyle: const TextStyle(
            color: textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        titleLarge: GoogleFonts.instrumentSerif(
          textStyle: const TextStyle(
            color: textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        // The following will use the global outfit fontFamily by default, 
        // but we define them here for specific weights/sizes.
        titleMedium: const TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        bodyLarge: const TextStyle(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: const TextStyle(
          color: textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        labelSmall: const TextStyle(
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),

      // AppBar Theme (Primary Font)
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.instrumentSerif(
          textStyle: const TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: accentBlue),
      ),

      // Card Theme (Standard Dashboard Rounded)
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0, 
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Search Bar Theme
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(surface),
        elevation: WidgetStateProperty.all(0),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16)),
        textStyle: WidgetStateProperty.all(const TextStyle(color: textPrimary)),
        hintStyle: WidgetStateProperty.all(const TextStyle(color: textSecondary)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.outfit(color: textSecondary),
      ),
    );
  }

  // Utility Decoration for specialized cards
  static BoxDecoration accentCardDecoration(Color color) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    );
  }
}
