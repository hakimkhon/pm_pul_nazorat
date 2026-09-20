import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ---- LIGHT — to'qroq, boyroq brend ranglari ----
  static const Color deepTeal = Color(0xFF082625); // avvalgidan to'qroq
  static const Color emerald = Color(0xFF129468); // to'yingan zumrad
  static const Color gold = Color(0xFFD9900F); // boyroq, to'qroq oltin
  static const Color coral = Color(0xFFD6453D); // to'qroq korall-qizil
  static const Color bg = Color(0xFFEFF3F1);
  static const Color ink = Color(0xFF0B1B17);

  // ---- DARK — chuqur, "qora emerald" fon ----
  static const Color darkBg = Color(0xFF0A1513);
  static const Color darkSurface = Color(0xFF12211D);
  static const Color darkSurfaceAlt = Color(0xFF193029);
  static const Color emeraldBright = Color(0xFF34E3A8);
  static const Color goldBright = Color(0xFFF2B33D);
  static const Color coralBright = Color(0xFFFF7A6E);
  static const Color textLight = Color(0xFFE9F3EF);
  static const Color textMuted = Color(0xFF8FAA9F);

  // Eski nomlar bilan moslik (statik, temaga bog'liq bo'lmagan joylarda)
  static const Color primary = deepTeal;
  static const Color income = emerald;
  static const Color expense = coral;
  static const double radiusLarge = 24;
  static const double radiusMedium = 16;
  static const double radiusSmall = 10;

  // ---- Kontekstga qarab moslashuvchi semantik ranglar ----
  static Color surface(BuildContext c) => Theme.of(c).colorScheme.surface;
  static Color onSurface(BuildContext c) => Theme.of(c).colorScheme.onSurface;
  static Color mutedText(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? textMuted : ink.withValues(alpha: 0.55);
  static Color brandPrimary(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? emeraldBright : deepTeal;
  static Color brandGold(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? goldBright : gold;
  static Color brandIncome(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? emeraldBright : emerald;
  static Color brandExpense(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? coralBright : coral;

  static ThemeData light = _build(
    brightness: Brightness.light,
    scaffoldBg: bg,
    surface: Colors.white,
    textColor: ink,
    seed: deepTeal,
    fabBg: gold,
    fabFg: deepTeal,
  );

  static ThemeData dark = _build(
    brightness: Brightness.dark,
    scaffoldBg: darkBg,
    surface: darkSurface,
    textColor: textLight,
    seed: emeraldBright,
    fabBg: goldBright,
    fabFg: darkBg,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffoldBg,
    required Color surface,
    required Color textColor,
    required Color seed,
    required Color fabBg,
    required Color fabFg,
  }) {
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? textMuted : textColor.withValues(alpha: 0.55);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
        primary: isDark ? emeraldBright : deepTeal,
        secondary: isDark ? goldBright : gold,
        error: isDark ? coralBright : coral,
        surface: surface,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 34, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 24, fontWeight: FontWeight.w700, color: textColor, letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: textColor),
        titleMedium: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
        bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 15, color: textColor.withValues(alpha: 0.8), height: 1.4),
        labelSmall: GoogleFonts.plusJakartaSans(fontSize: 13, color: muted, fontWeight: FontWeight.w500),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: textColor,
        titleTextStyle: GoogleFonts.plusJakartaSans(color: textColor, fontSize: 20, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall + 4),
          borderSide: BorderSide(color: textColor.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall + 4),
          borderSide: BorderSide(color: textColor.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall + 4),
          borderSide: BorderSide(color: isDark ? emeraldBright : deepTeal, width: 1.6),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(color: muted, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: isDark ? darkBg : Colors.white,
          backgroundColor: isDark ? emeraldBright : deepTeal,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall + 4)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
        side: BorderSide.none,
        backgroundColor: textColor.withValues(alpha: isDark ? 0.08 : 0.04),
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: fabBg,
        foregroundColor: fabFg,
        elevation: 4,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: isDark ? emeraldBright : deepTeal,
        unselectedItemColor: muted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
        titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
        contentTextStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: textColor.withValues(alpha: 0.75), height: 1.4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? (isDark ? emeraldBright : emerald) : textColor.withValues(alpha: isDark ? 0.24 : 0.18)),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }

  static List<BoxShadow> softShadow({Color tint = deepTeal, double opacity = 0.08}) => [
        BoxShadow(color: tint.withValues(alpha: opacity), blurRadius: 24, offset: const Offset(0, 8)),
      ];
}