import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../features/navigation/providers/navigation_provider.dart';
import '../../ui/components/glass_container.dart';

class NavigationSettingsScreen extends ConsumerWidget {
  const NavigationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(navigationProvider);
    final order = settings.order;

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      navigationBar: const CupertinoNavigationBar(
        middle: Text(
          'Customize Navigation',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        previousPageTitle: 'Settings',
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Drag to reorder. Toggle to hide/show. Tap star to set default.',
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: order.length,
                onReorder: (oldIndex, newIndex) {
                  ref
                      .read(navigationProvider.notifier)
                      .reorder(oldIndex, newIndex);
                },
                proxyDecorator: (child, index, animation) {
                  return Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  );
                },
                itemBuilder: (context, index) {
                  final tab = order[index];
                  final isVisible = !settings.hidden.contains(tab);
                  final isDefault = settings.defaultTab == tab;

                  return Container(
                    key: ValueKey(tab),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: GlassContainer(
                      borderRadius: BorderRadius.circular(12),
                      opacity: 0.1,
                      blur: 10,
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: Icon(tab.icon, color: AppTheme.primaryColor),
                          title: Row(
                            children: [
                              Text(
                                tab.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Pacifico',
                                  fontSize: 18,
                                ),
                              ),
                              if (isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Default',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Default tab star button
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                minSize: 32,
                                onPressed: isVisible
                                    ? () {
                                        ref
                                            .read(navigationProvider.notifier)
                                            .setDefaultTab(tab);
                                      }
                                    : null,
                                child: Icon(
                                  isDefault
                                      ? CupertinoIcons.star_fill
                                      : CupertinoIcons.star,
                                  color: isDefault
                                      ? Colors.amber
                                      : (isVisible
                                            ? AppTheme.textSecondary
                                            : AppTheme.textSecondary.withValues(
                                                alpha: 0.3,
                                              )),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Visibility toggle
                              CupertinoSwitch(
                                value: isVisible,
                                activeColor: AppTheme.primaryColor,
                                onChanged: (value) {
                                  ref
                                      .read(navigationProvider.notifier)
                                      .toggleVisibility(tab);
                                },
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.drag_handle,
                                color: AppTheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
