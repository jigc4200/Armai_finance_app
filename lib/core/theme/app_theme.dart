import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // El secreto UX: Fondo blanco o blanquecino ultra limpio
    scaffoldBackgroundColor: const Color(0xFFF2F2F2),

    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2D20D8), // Azul/morado profundo
      primaryContainer: Color(0xFFC7E8FF),
      onPrimaryContainer: Color(0xFF0A0A0A),
      secondary: Color(0xFF10B981), // Verde éxito/ingresos
      error: Color(0xFFFF3B30), // Rojo iOS para gastos/alerta
      surface: Colors.white, // Tarjetas y formularios
      onSurface: Color(0xFF0A0A0A), // Texto principal
      onSurfaceVariant: Color(0xFF8A8A8A), // Texto secundario
    ),

    // Tipografía de Alto Contraste
    textTheme: TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w900,
        color: const Color(0xFF0A0A0A),
        letterSpacing: -0.8,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w800,
        color: const Color(0xFF0A0A0A),
        letterSpacing: -0.8,
      ),
      bodyLarge: GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        color: const Color(0xFF0A0A0A),
      ),
      bodyMedium: GoogleFonts.inter(
        fontWeight: FontWeight.normal,
        color: const Color(0xFF8A8A8A),
      ),
      labelSmall: GoogleFonts.shareTechMono(color: const Color(0xFFFF3B30)),
    ),

    // Tarjetas Bento (Sin sombras, bordes de 1px ultra finos)
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE6E6E6), width: 1),
      ),
    ),

    // Inputs estilo Bento (limpios con bordes suaves de 12px)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE6E6E6), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE6E6E6), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF2D20D8), width: 1.5),
      ),
      labelStyle: const TextStyle(color: Color(0xFF8A8A8A)),
      hintStyle: const TextStyle(color: Color(0xFFC7C7CC)),
    ),
  );

  static ThemeData get dark => light;
}
