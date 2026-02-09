import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors - iOS 17 Style
  static const Color primaryColor = Color(0xFFFA2D48); // Apple Music Red/Pink
  static const Color secondaryColor = Color(0xFFEB4D3D);

  static const Color backgroundColor = Color(0xFF000000); // OLED Black
  static const Color surfaceColor = Color(
    0xFF1C1C1E,
  ); // iOS System Gray 6 (Dark)
  static const Color surfaceHighlight = Color(
    0xFF2C2C2E,
  ); // iOS System Gray 5 (Dark)

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93); // iOS System Gray
  static const Color textTertiary = Color(0xFF48484A); // iOS System Gray 3

  // Get the appropriate Google Font TextStyle based on font family name
  static TextStyle _getGoogleFont(
    String fontFamily, {
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = textPrimary,
    double? letterSpacing,
  }) {
    switch (fontFamily) {
      case 'Pacifico':
        return GoogleFonts.pacifico(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          letterSpacing: letterSpacing,
        );
      case 'Inter':
        return GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          letterSpacing: letterSpacing,
        );
      case 'Roboto':
        return GoogleFonts.roboto(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          letterSpacing: letterSpacing,
        );
      case 'Outfit':
        return GoogleFonts.outfit(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          letterSpacing: letterSpacing,
        );
      case 'Montserrat':
        return GoogleFonts.montserrat(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          letterSpacing: letterSpacing,
        );
      default:
        return GoogleFonts.pacifico(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          letterSpacing: letterSpacing,
        );
    }
  }

  // Default text theme (uses Pacifico for backward compatibility)
  static TextTheme get textTheme => getTextTheme('Pacifico');

  // Typography - Dynamic font selection
  static TextTheme getTextTheme(String fontFamily) => TextTheme(
    displayLarge: _getGoogleFont(
      fontFamily,
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: textPrimary,
      letterSpacing: -0.4,
    ),
    displayMedium: _getGoogleFont(
      fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: textPrimary,
      letterSpacing: -0.4,
    ),
    titleLarge: _getGoogleFont(
      fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
    titleMedium: _getGoogleFont(
      fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
    bodyLarge: _getGoogleFont(
      fontFamily,
      fontSize: 17,
      fontWeight: FontWeight.w400,
      color: textPrimary,
    ),
    bodyMedium: _getGoogleFont(
      fontFamily,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: textSecondary,
    ),
    labelSmall: _getGoogleFont(
      fontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: textSecondary,
      letterSpacing: 0.1,
    ),
    bodySmall: _getGoogleFont(
      fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: textSecondary,
    ),
    titleSmall: _getGoogleFont(
      fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
  );

  // Default dark theme (uses Pacifico for backward compatibility)
  static CupertinoThemeData get darkTheme => getDarkTheme('Pacifico');

  static CupertinoThemeData getDarkTheme(String fontFamily) =>
      CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        barBackgroundColor: const Color(0xD91C1C1E), // Translucent Tab Bar
        textTheme: CupertinoTextThemeData(
          primaryColor: primaryColor,
          textStyle: _getGoogleFont(
            fontFamily,
            color: CupertinoColors.white,
            fontSize: 17,
          ),
        ),
      );
}
