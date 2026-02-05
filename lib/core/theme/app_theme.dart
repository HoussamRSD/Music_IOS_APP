import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_constants.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryColor = Color(0xFF2997FF); // iOS Blue variant
  static const Color accentColor = Color(0xFFBF5AF2); // iOS Purple
  static const Color backgroundColor = Color(0xFF000000); // Pure Black for OLED
  static const Color surfaceColor = Color(0xFF1C1C1E); // iOS Dark Surface

  // Text Styles
  static TextTheme get textTheme => GoogleFonts.interTextTheme().copyWith(
    displayLarge: GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: CupertinoColors.white,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: CupertinoColors.white,
    ),
    bodyLarge: GoogleFonts.inter(fontSize: 17, color: CupertinoColors.white),
    bodyMedium: GoogleFonts.inter(
      fontSize: 15,
      color: CupertinoColors.systemGrey,
    ),
  );

  static const CupertinoThemeData darkTheme = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    barBackgroundColor: Color(0xCC1C1C1E), // Slightly transparent
    textTheme: CupertinoTextThemeData(
      primaryColor: primaryColor,
      textStyle: TextStyle(fontFamily: 'Inter', color: CupertinoColors.white),
    ),
  );

  // Liquid Glass Decorations
  static BoxDecoration get glassDecoration => BoxDecoration(
    color: Colors.white.withValues(alpha: AppConstants.glassOpacity),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.white.withValues(alpha: AppConstants.glassBorderOpacity),
      width: AppConstants.glassBorderWidth,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 15,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
