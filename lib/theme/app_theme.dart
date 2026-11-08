import 'package:flutter/material.dart';

import 'estado_colores.dart';

class AppTheme {
  AppTheme._();

  static ThemeData oscuro() => _construir(_esquemaOscuro, EstadoColores.oscuro);

  static ThemeData claro() => _construir(_esquemaClaro, EstadoColores.claro);

  static final _esquemaOscuro =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFFF57C00),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFFF57C00),
        onPrimary: const Color(0xFF12151A),
        primaryContainer: const Color(0xFFFFB786),
        onPrimaryContainer: const Color(0xFF572800),
        secondary: const Color(0xFF29B6F6),
        onSecondary: const Color(0xFF00344B),
        secondaryContainer: const Color(0xFF00A9E8),
        onSecondaryContainer: const Color(0xFF003952),
        tertiary: const Color(0xFF66BB6A),
        onTertiary: const Color(0xFF00390E),
        error: const Color(0xFFEF5350),
        onError: const Color(0xFFFFFFFF),
        errorContainer: const Color(0xFF2A181A),
        onErrorContainer: const Color(0xFFEF5350),
        surface: const Color(0xFF12151A),
        onSurface: const Color(0xFFFFFFFF),
        onSurfaceVariant: const Color(0xFFDEC1AF),
        surfaceContainerLowest: const Color(0xFF0B0E13),
        surfaceContainer: const Color(0xFF1E232B),
        surfaceContainerHigh: const Color(0xFF262D38),
        outline: const Color(0xFF374151),
        outlineVariant: const Color(0xFF2B3441),
      );

  static final _esquemaClaro =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFFF57C00),
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFFF57C00),
        onPrimary: const Color(0xFF12151A),
        primaryContainer: const Color(0xFFFFE0B2),
        onPrimaryContainer: const Color(0xFFB85400),
        secondary: const Color(0xFF0288D1),
        onSecondary: const Color(0xFFFFFFFF),
        secondaryContainer: const Color(0xFFB3E5FC),
        onSecondaryContainer: const Color(0xFF01579B),
        tertiary: const Color(0xFF2E7D32),
        onTertiary: const Color(0xFFFFFFFF),
        error: const Color(0xFFD32F2F),
        onError: const Color(0xFFFFFFFF),
        errorContainer: const Color(0xFFFFCDD2),
        onErrorContainer: const Color(0xFFB71C1C),
        surface: const Color(0xFFF3F4F6),
        onSurface: const Color(0xFF12151A),
        onSurfaceVariant: const Color(0xFF4B5563),
        surfaceContainerLowest: const Color(0xFFFFFFFF),
        surfaceContainer: const Color(0xFFFFFFFF),
        surfaceContainerHigh: const Color(0xFFE5E7EB),
        outline: const Color(0xFFD1D5DB),
        outlineVariant: const Color(0xFFE5E7EB),
      );

  static ThemeData _construir(ColorScheme esquema, EstadoColores estados) {
    final esBase = ThemeData(colorScheme: esquema, useMaterial3: true);
    final textTheme = _construirTextTheme(esquema);

    return esBase.copyWith(
      scaffoldBackgroundColor: esquema.surface,
      extensions: [estados],
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: esquema.surface,
        foregroundColor: esquema.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.headlineSmall,
      ),

      cardTheme: CardThemeData(
        color: esquema.surfaceContainer,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: esquema.outlineVariant),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: esquema.primary,
          foregroundColor: esquema.onPrimary,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(
            fontFamily: 'Barlow Condensed',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: esquema.onSurface,
          side: BorderSide(color: esquema.outlineVariant),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: esquema.surfaceContainerLowest,
        constraints: const BoxConstraints(minHeight: 52),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: esquema.outline, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: esquema.outline, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: esquema.primary, width: 1.5),
        ),
      ),
    );
  }

  static TextTheme _construirTextTheme(ColorScheme esquema) {
    return TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Barlow Condensed',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 36 / 32,
        color: esquema.onSurface,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Barlow Condensed',
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 32 / 28,
        color: esquema.onSurface,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Barlow Condensed',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 26 / 22,
        color: esquema.onSurface,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 26 / 18,
        color: esquema.onSurface,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: esquema.onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: esquema.onSurface,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        color: esquema.onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Barlow Condensed',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: esquema.onSurface,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Barlow Condensed',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        height: 16 / 13,
        color: esquema.onSurface,
      ),
    );
  }
}
