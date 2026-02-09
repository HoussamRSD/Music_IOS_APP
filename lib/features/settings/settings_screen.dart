import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../ui/components/glass_container.dart';
import 'navigation_settings_screen.dart';
import 'font_settings_screen.dart';
import 'providers/font_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTextStyles = ref.watch(appTextStylesProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        middle: Text(
          'Settings',
          style: appTextStyles.titleMedium(color: Colors.white),
        ),
        previousPageTitle: 'Back',
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GlassContainer(
                borderRadius: BorderRadius.circular(12),
                opacity: 0.1,
                blur: 20,
                child: Column(
                  children: [
                    _buildSettingsItem(
                      icon: CupertinoIcons.slider_horizontal_3,
                      title: 'Customize Navigation',
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) =>
                                const NavigationSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: CupertinoIcons.textformat,
                      title: 'Font Style',
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => const FontSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: CupertinoIcons.music_note_list,
                      title: 'Audio Quality',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: CupertinoIcons.paintbrush,
                      title: 'Appearance',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: CupertinoIcons.info,
                      title: 'About DOPLIN',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Version 1.0.0 (1)',
                style: AppTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return CupertinoListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(
        title,
        style: AppTheme.textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      trailing: const Icon(
        CupertinoIcons.chevron_right,
        color: AppTheme.textSecondary,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 50, color: Colors.white.withOpacity(0.1));
  }
}
