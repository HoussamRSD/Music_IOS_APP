import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_text_styles.dart';

const _fontKey = 'app_font_family';

/// Available font options for the app
enum AppFont {
  pacifico('Pacifico'),
  inter('Inter'),
  roboto('Roboto'),
  outfit('Outfit'),
  montserrat('Montserrat');

  final String displayName;
  const AppFont(this.displayName);

  String get fontFamily => displayName;
}

class FontNotifier extends Notifier<AppFont> {
  @override
  AppFont build() {
    _loadFont();
    return AppFont.pacifico; // Default font
  }

  Future<void> _loadFont() async {
    final prefs = await SharedPreferences.getInstance();
    final fontName = prefs.getString(_fontKey);
    if (fontName != null) {
      final font = AppFont.values.firstWhere(
        (f) => f.fontFamily == fontName,
        orElse: () => AppFont.pacifico,
      );
      state = font;
    }
  }

  Future<void> setFont(AppFont font) async {
    state = font;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontKey, font.fontFamily);
  }
}

final fontProvider = NotifierProvider<FontNotifier, AppFont>(FontNotifier.new);

/// Provider that gives access to AppTextStyles with the selected font
final appTextStylesProvider = Provider<AppTextStyles>((ref) {
  final font = ref.watch(fontProvider);
  return AppTextStyles(font.fontFamily);
});
