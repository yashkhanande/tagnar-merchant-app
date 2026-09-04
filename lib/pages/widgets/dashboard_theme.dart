import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DashboardTheme {
  DashboardTheme._();

  static const background = Color(0xFF0B192E);
  static const surface = Color(0xFF142D50);
  static const border = Color(0xFF294B73);
  static const accent = Color(0xFF93C5FD);
  static const secondary = Color(0xFFCBD5E1);
  static const iconBackground = Color(0xFF203F65);

  static final data = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      onPrimary: background,
      surface: surface,
      onSurface: Colors.white,
      onSurfaceVariant: secondary,
      outline: border,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: const BorderSide(color: border),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
  );
}