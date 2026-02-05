import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Search', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
      ),
      child: Center(
        child: Text(
          'Search Content Coming Soon',
          style: AppTheme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}
