import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'glass_container.dart';

class TabHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onActionPressed;
  final IconData? actionIcon;
  final String? actionLabel;
  final bool showAction;

  const TabHeader({
    super.key,
    required this.title,
    required this.icon,
    this.onActionPressed,
    this.actionIcon,
    this.actionLabel,
    this.showAction = true,
  });

  @override
  Widget build(BuildContext context) {
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
              style: AppTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 28,
              ),
            ),
          ),
          // Action button
          if (showAction && actionIcon != null && onActionPressed != null)
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
