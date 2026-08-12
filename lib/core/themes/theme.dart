import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemePreset { minimalist, pixelArt, artDeco ,aurora, ascii, cybersigilism  }

class AppTheme {
  AppTheme._();

  static ThemeData themeFor(AppThemePreset preset) {
    switch (preset) {
      case AppThemePreset.minimalist:
        return _minimalist();
      case AppThemePreset.pixelArt:
        return _pixelArt();
      case AppThemePreset.artDeco:
        return _artDeco();
      case AppThemePreset.aurora:

        return _aurora();
      case AppThemePreset.ascii:

        return _ascii();
      case AppThemePreset.cybersigilism:
        return _cybersigilism();
    }
  }

  static ThemeData _minimalist() {
    final colorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF2B2B2B));

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
    );
  }
  static ThemeData _pixelArt() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00E5A0),
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: GoogleFonts.pressStart2pTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(), // no radius specified = sharp square corners
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: const RoundedRectangleBorder(),
        ),
      ),
    );
  }
  static ThemeData _artDeco() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFC9A227), // gold
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0B0B0B), // deliberate near-black
      textTheme: GoogleFonts.cinzelTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
    );
  }
  static ThemeData _cybersigilism() {
    final base = GoogleFonts.cormorantTextTheme(ThemeData.dark().textTheme);
    final gothicTitle = GoogleFonts.pirataOne();

    final textTheme = base.copyWith(
      displayLarge: gothicTitle.copyWith(fontSize: base.displayLarge?.fontSize),
      headlineLarge: gothicTitle.copyWith(fontSize: base.headlineLarge?.fontSize),
      titleLarge: gothicTitle.copyWith(fontSize: base.titleLarge?.fontSize),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF8A8FA3), // desaturated silver-lavender
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF0A0A0C),
      primary: const Color(0xFFD8D8E0),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colorScheme.onSurface.withOpacity(0.2)),
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
  static ThemeData _aurora() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2EE6A8), // aurora green
      brightness: Brightness.dark,
    ).copyWith(
      secondary: const Color(0xFF8A5CF6), // violet band
      tertiary: const Color(0xFFEC5FA6),  // pink band
      surface: const Color(0xFF0B0E1A),   // night-sky navy-black
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: GoogleFonts.orbitronTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
  static ThemeData _ascii() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF33FF66), // phosphor terminal green
      brightness: Brightness.dark,
    ).copyWith(surface: Colors.black);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: GoogleFonts.spaceMonoTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colorScheme.primary.withOpacity(0.6)),
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
}