import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

/// Extension to easily apply the app's selected font to any TextStyle
extension AppTextStyleExtension on TextStyle {
  /// Apply the selected font family while preserving other style properties
  TextStyle withAppFont(String fontFamily) {
    switch (fontFamily) {
      // Script / decorative
      case 'Pacifico':
        return GoogleFonts.pacifico(textStyle: this);
      case 'Abril Fatface':
        return GoogleFonts.abrilFatface(textStyle: this);
      case 'Bebas Neue':
        return GoogleFonts.bebasNeue(textStyle: this);

      // Modern UI / very good in bold
      case 'Inter':
        return GoogleFonts.inter(textStyle: this);
      case 'Roboto':
        return GoogleFonts.roboto(textStyle: this);
      case 'Poppins':
        return GoogleFonts.poppins(textStyle: this);
      case 'DM Sans':
        return GoogleFonts.dmSans(textStyle: this);
      case 'Work Sans':
        return GoogleFonts.workSans(textStyle: this);
      case 'Montserrat':
        return GoogleFonts.montserrat(textStyle: this);
      case 'Outfit':
        return GoogleFonts.outfit(textStyle: this);

      // Classic “popular” sans (bold looks solid)
      case 'Open Sans':
        return GoogleFonts.openSans(textStyle: this);
      case 'Lato':
        return GoogleFonts.lato(textStyle: this);
      case 'Raleway':
        return GoogleFonts.raleway(textStyle: this);
      case 'Nunito':
        return GoogleFonts.nunito(textStyle: this);
      case 'Source Sans 3':
        return GoogleFonts.sourceSans3(textStyle: this);
      case 'Ubuntu':
        return GoogleFonts.ubuntu(textStyle: this);
      case 'Oswald':
        return GoogleFonts.oswald(textStyle: this);

      // Serif options (nice bold titles)
      case 'Playfair Display':
        return GoogleFonts.playfairDisplay(textStyle: this);
      case 'Merriweather':
        return GoogleFonts.merriweather(textStyle: this);

      default:
        return GoogleFonts.inter(textStyle: this);
    }
  }
}

/// Helper class to get text styles that use the app's selected font
class AppTextStyles {
  final String fontFamily;

  const AppTextStyles(this.fontFamily);

  TextStyle _getFont({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = CupertinoColors.white,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) {
    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
    );
    return baseStyle.withAppFont(fontFamily);
  }

  // Display styles
  TextStyle displayLarge({Color? color}) => _getFont(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: color ?? CupertinoColors.white,
    letterSpacing: -0.4,
  );

  TextStyle displayMedium({Color? color}) => _getFont(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: color ?? CupertinoColors.white,
    letterSpacing: -0.4,
  );

  // Title styles
  TextStyle titleLarge({Color? color}) => _getFont(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: color ?? CupertinoColors.white,
  );

  TextStyle titleMedium({Color? color}) => _getFont(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: color ?? CupertinoColors.white,
  );

  TextStyle titleSmall({Color? color}) => _getFont(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: color ?? CupertinoColors.white,
  );

  // Body styles
  TextStyle bodyLarge({Color? color}) => _getFont(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: color ?? CupertinoColors.white,
  );

  TextStyle bodyMedium({Color? color}) => _getFont(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: color ?? CupertinoColors.white.withValues(alpha: 0.7),
  );

  TextStyle bodySmall({Color? color}) => _getFont(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: color ?? CupertinoColors.white.withValues(alpha: 0.6),
  );

  // Label styles
  TextStyle labelLarge({Color? color}) => _getFont(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: color ?? CupertinoColors.white,
  );

  TextStyle labelMedium({Color? color}) => _getFont(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: color ?? CupertinoColors.white.withValues(alpha: 0.7),
  );

  TextStyle labelSmall({Color? color}) => _getFont(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: color ?? CupertinoColors.white.withValues(alpha: 0.6),
  );

  // Custom style with full control
  TextStyle custom({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = CupertinoColors.white,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) => _getFont(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
    decoration: decoration,
  );
}
