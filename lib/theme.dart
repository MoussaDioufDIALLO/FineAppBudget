import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppColors {
  static const green = Color(0xFF1FD4A5);
  static const ink = Color(0xFF1E1E1E);
  static const grey = Color(0xFFF5F5F5);
  static const muted = Color(0xFF9A9A9A);
  static const mint = Color(0xFFF1FFF3);
  static const dark = Color(0xFF052224);
  static const blue = Color(0xFF0068FF);
  static const sky = Color(0xFF6DB6FE);
  static const field = Color(0xFFDFF7E2);
  static const income = Color(0xFF008F6B);
  static const danger = Color(0xFFE5575B);
}

/// Ombre douce commune aux cartes.
List<BoxShadow> softShadow([double opacity = 0.08]) => [
      BoxShadow(
        color: AppColors.dark.withOpacity(opacity),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ];

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.green).copyWith(
        primary: AppColors.green,
        onPrimary: AppColors.dark,
        surface: AppColors.mint,
      ),
      scaffoldBackgroundColor: AppColors.mint,
      fontFamily: 'Poppins',
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      }),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.dark,
        centerTitle: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: AppColors.dark,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.dark,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: AppColors.green, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.dark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.field,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        floatingLabelStyle: const TextStyle(color: AppColors.dark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.green, width: 1.8),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.dark,
        contentTextStyle: const TextStyle(fontFamily: 'Poppins', color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.mint,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.dark : Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.green : const Color(0xFFB8D8BF)),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );

final money = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
