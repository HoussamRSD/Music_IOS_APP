import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Search'),
            backgroundColor: Color(0xCC1C1C1E),
            border: null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CupertinoSearchTextField(
                backgroundColor: AppTheme.surfaceHighlight,
                placeholderStyle: AppTheme.textTheme.bodyMedium,
                style: AppTheme.textTheme.bodyLarge,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.6,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final category = _categories[index % _categories.length];
                return _CategoryCard(item: category);
              }, childCount: _categories.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _CategoryItem {
  final String title;
  final Color color;
  final String image;

  const _CategoryItem(this.title, this.color, this.image);
}

const _categories = [
  _CategoryItem('Pop', Color(0xFFFF2D55), 'assets/pop.jpg'),
  _CategoryItem('Rock', Color(0xFFFF3B30), 'assets/rock.jpg'),
  _CategoryItem('Hip-Hop', Color(0xFFFF9500), 'assets/hiphop.jpg'),
  _CategoryItem('Electronic', Color(0xFF5856D6), 'assets/electro.jpg'),
  _CategoryItem('Jazz', Color(0xFF007AFF), 'assets/jazz.jpg'),
  _CategoryItem('Classical', Color(0xFFFFCC00), 'assets/classical.jpg'),
  _CategoryItem('R&B', Color(0xFFAF52DE), 'assets/rnb.jpg'),
  _CategoryItem('Indie', Color(0xFF34C759), 'assets/indie.jpg'),
];

class _CategoryCard extends StatelessWidget {
  final _CategoryItem item;

  const _CategoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(12),
        // Add image/gradient?
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background gradient or pattern
          Positioned(
            right: -20,
            bottom: -10,
            child: Transform.rotate(
              angle: 0.4,
              child: Icon(
                CupertinoIcons.music_note_2,
                size: 80,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                item.title,
                style: AppTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
