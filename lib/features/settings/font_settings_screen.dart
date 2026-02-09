import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../ui/components/glass_container.dart';
import 'providers/font_provider.dart';

class FontSettingsScreen extends ConsumerWidget {
  const FontSettingsScreen({super.key});

  TextStyle _getFontPreviewStyle(AppFont font) {
    switch (font) {
      case AppFont.pacifico:
        return GoogleFonts.pacifico(fontSize: 16, color: Colors.white);
      case AppFont.inter:
        return GoogleFonts.inter(fontSize: 16, color: Colors.white);
      case AppFont.roboto:
        return GoogleFonts.roboto(fontSize: 16, color: Colors.white);
      case AppFont.outfit:
        return GoogleFonts.outfit(fontSize: 16, color: Colors.white);
      case AppFont.montserrat:
        return GoogleFonts.montserrat(fontSize: 16, color: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFont = ref.watch(fontProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        middle: Text('Font Style', style: TextStyle(color: Colors.white)),
        previousPageTitle: 'Settings',
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GlassContainer(
            borderRadius: BorderRadius.circular(12),
            opacity: 0.1,
            blur: 20,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: AppFont.values.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 50,
                color: Colors.white.withOpacity(0.1),
              ),
              itemBuilder: (context, index) {
                final font = AppFont.values[index];
                final isSelected = font == currentFont;

                return CupertinoListTile(
                  leading: Icon(
                    CupertinoIcons.textformat,
                    color: isSelected ? AppTheme.primaryColor : Colors.white54,
                  ),
                  title: Text(
                    font.displayName,
                    style: _getFontPreviewStyle(font),
                  ),
                  subtitle: Text(
                    'The quick brown fox jumps over the lazy dog',
                    style: _getFontPreviewStyle(
                      font,
                    ).copyWith(fontSize: 12, color: Colors.white54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: isSelected
                      ? const Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          color: AppTheme.primaryColor,
                        )
                      : null,
                  onTap: () {
                    ref.read(fontProvider.notifier).setFont(font);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
