import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Library', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
      ),
      child: Center(
        child: Text(
          'Library Content Coming Soon',
          style: AppTheme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}
