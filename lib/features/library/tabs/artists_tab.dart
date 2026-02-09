import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../ui/components/tab_header.dart';
import '../../artists/providers/artist_provider.dart';
import '../../settings/providers/font_provider.dart';

class ArtistsTab extends ConsumerWidget {
  const ArtistsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artists = ref.watch(allArtistsProvider);
    final appTextStyles = ref.watch(appTextStylesProvider);

    if (artists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.person_2_fill,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text('No Artists Found', style: appTextStyles.titleLarge()),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: TabHeader(
            title: 'Artists',
            icon: CupertinoIcons.person_2_fill,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 180),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final artist = artists[index];
                final songCount = ref.watch(artistSongsProvider(artist)).length;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      context.go('/library/artist/${Uri.encodeComponent(artist)}');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.music_mic,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  artist,
                                  style: appTextStyles.bodyLarge(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$songCount song${songCount == 1 ? '' : 's'}',
                                  style: appTextStyles.bodySmall().copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            CupertinoIcons.chevron_right,
                            color: AppTheme.textSecondary.withValues(alpha: 0.5),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: artists.length,
            ),
          ),
        ),
      ],
    );
  }
}
