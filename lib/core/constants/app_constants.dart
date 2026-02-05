class AppConstants {
  static const String appName = 'Glass Music';
  static const String fontFamily =
      'SF Pro Display'; // Fallback if Google Fonts not used, but we'll use Google Fonts 'Inter' or similar as proxy for SF

  // Liquid Glass Constants
  static const double glassBlur = 20.0;
  static const double glassOpacity = 0.15;
  static const double glassBorderOpacity = 0.2;
  static const double glassBorderWidth = 1.0;

  // Animation Durations
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Duration fastDuration = Duration(milliseconds: 150);
}
