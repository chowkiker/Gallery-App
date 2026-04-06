import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bg = Color(0xFFF4F6FB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE8EAF0);
  static const Color primary = Color(0xFF3B5BDB);
  static const Color primaryBg = Color(0xFFE8EEFF);
  static const Color accent = Color(0xFF7048E8);
  static const Color text = Color(0xFF0F1624);
  static const Color textSub = Color(0xFF4A5568);
  static const Color textMuted = Color(0xFFA0AEC0);
  static const Color navBg = Color(0xFFFAFBFF);
  static const Color navBorder = Color(0xFFF0F2F9);
  static const Color danger = Color(0xFFE53E3E);
  static const Color dangerBg = Color(0xFFFFF5F5);
  static const Color success = Color(0xFF38A169);
  static const Color successBg = Color(0xFFF0FFF4);
  static const Color warn = Color(0xFFD69E2E);
  static const Color warnBg = Color(0xFFFFFAF0);

  static const Color shadow = Color(0x183B5BDB);
  static const Color shadowDeep = Color(0x2F3B5BDB);
  static const Color shimmerBase = Color(0xFFE8ECF4);
  static const Color shimmerHighlight = Color(0xFFF8F9FF);

  // Inter font name (const-safe for use inside const TextStyle)
  static const String fontFamily = 'Inter';

  // Inter via google_fonts
  static String get googleFontFamily => GoogleFonts.inter().fontFamily ?? 'Inter';

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.interTextTheme(),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        surface: bg,
        error: danger,
      ),
    );
  }
}
