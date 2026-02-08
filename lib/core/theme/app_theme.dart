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

  // Typography - San Francisco Style (using Inter as closest open alternative)
  static TextTheme get textTheme => TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: textPrimary,
      letterSpacing: -0.4, // Tight tracking for headers
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: textPrimary,
      letterSpacing: -0.4,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 22,
      fontWeight: FontWeight.w600, // Semi-bold
      color: textPrimary,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 17,
      fontWeight: FontWeight.w400, // Regular
      color: textPrimary,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: textSecondary,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: textSecondary,
      letterSpacing: 0.1,
    ),
  );

  static const CupertinoThemeData darkTheme = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    barBackgroundColor: Color(0xD91C1C1E), // Translucent Tab Bar
    textTheme: CupertinoTextThemeData(
      primaryColor: primaryColor,
      textStyle: TextStyle(
        fontFamily: 'Inter',
        color: CupertinoColors.white,
        fontSize: 17,
      ),
    ),
  );
}
