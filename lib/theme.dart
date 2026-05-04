import 'package:flutter/material.dart';

class AppColors {
  static const orange = Color(0xFFFF6D00);
  static const orangeDark = Color(0xFFE65100);
  static const orangeDim = Color(0x26FF6D00);  // 15% opacity
  static const orangeGlow = Color(0x4DFF6D00); // 30% opacity

  static const darkBg = Color(0xFF0A0A0A);
  static const darkSurface = Color(0xFF141414);
  static const darkCard = Color(0xFF1C1C1C);
  static const border = Color(0xFF282828);

  static const white70 = Color(0xB3FFFFFF);
  static const white40 = Color(0x66FFFFFF);
  static const white12 = Color(0x12FFFFFF);

  static const green = Color(0xFF00E676);
  static const red = Color(0xFFFF5252);
  static const redDim = Color(0x26FF5252);

  // Tema claro (exterior / sol directo)
  static const lightBg = Color(0xFFF5F5F5);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFEEEEEE);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.orange,
          secondary: AppColors.orange,
          surface: AppColors.darkSurface,
          onPrimary: Colors.black,
          onSurface: Colors.white,
        ),
        cardColor: AppColors.darkCard,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 56),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.orange,
            side: const BorderSide(color: AppColors.orange, width: 2),
            minimumSize: const Size(double.infinity, 56),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkBg,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
          ),
        ),
        textTheme: const TextTheme(
          displayLarge:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: AppColors.white70, fontSize: 16),
          bodyMedium: TextStyle(color: AppColors.white40, fontSize: 14),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
          ),
          hintStyle: const TextStyle(color: AppColors.white40),
        ),
        useMaterial3: true,
      );

  // Tema claro — alto contraste para uso en exterior con sol directo
  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBg,
        colorScheme: const ColorScheme.light(
          primary: AppColors.orangeDark,
          secondary: AppColors.orangeDark,
          surface: AppColors.lightSurface,
          onPrimary: Colors.white,
          onSurface: Colors.black,
        ),
        cardColor: AppColors.lightCard,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orangeDark,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.orangeDark,
            side: const BorderSide(color: AppColors.orangeDark, width: 2),
            minimumSize: const Size(double.infinity, 56),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.lightSurface,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
          ),
        ),
        textTheme: const TextTheme(
          displayLarge:
              TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.black54, fontSize: 14),
        ),
        useMaterial3: true,
      );
}
