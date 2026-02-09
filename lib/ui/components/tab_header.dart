import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../features/settings/providers/font_provider.dart';
import 'glass_container.dart';

class TabHeader extends ConsumerWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onActionPressed;
  final IconData? actionIcon;
  final String? actionLabel;
  final bool showAction;
  final Widget? actionButton;

  const TabHeader({
    super.key,
    required this.title,
    required this.icon,
    this.onActionPressed,
    this.actionIcon,
    this.actionLabel,
    this.showAction = true,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTextStyles = ref.watch(appTextStylesProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Row(
        children: [
          // Icon in glass container
          GlassContainer(
            borderRadius: BorderRadius.circular(12),
            opacity: 0.08,
            blur: 15,
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Text(
              title,
              style: appTextStyles.titleLarge().copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 28,
              ),
            ),
          ),
          // Action button - custom widget takes precedence
          if (showAction && actionButton != null)
            actionButton!
          else if (showAction && actionIcon != null && onActionPressed != null)
            GestureDetector(
              onTap: onActionPressed,
              child: GlassContainer(
                borderRadius: BorderRadius.circular(12),
                opacity: 0.08,
                blur: 15,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    actionIcon,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
