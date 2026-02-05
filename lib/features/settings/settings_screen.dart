import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
      ),
      child: Center(
        child: Text(
          'Settings Content Coming Soon',
          style: AppTheme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}
