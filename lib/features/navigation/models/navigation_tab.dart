import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

enum NavigationTab {
  home,
  songs,
  playlists,
  artists;

  String get label {
    switch (this) {
      case NavigationTab.home:
        return 'Home';
      case NavigationTab.songs:
        return 'Songs';
      case NavigationTab.playlists:
        return 'Playlists';
      case NavigationTab.artists:
        return 'Artists';
    }
  }

  IconData get icon {
    switch (this) {
      case NavigationTab.home:
        return CupertinoIcons.home;
      case NavigationTab.songs:
        return CupertinoIcons.music_note;
      case NavigationTab.playlists:
        return CupertinoIcons.music_note_list;
      case NavigationTab.artists:
        return CupertinoIcons.person_2;
    }
  }

  /// Route path for router navigation
  String get routePath {
    switch (this) {
      case NavigationTab.home:
        return '/home';
      case NavigationTab.songs:
      case NavigationTab.playlists:
      case NavigationTab.artists:
        return '/library';
    }
  }

  /// Branch index for StatefulNavigationShell
  int get branchIndex {
    switch (this) {
      case NavigationTab.home:
        return 0;
      case NavigationTab.songs:
      case NavigationTab.playlists:
      case NavigationTab.artists:
        return 1;
    }
  }

  /// Library tab index (for Songs, Playlists, Artists)
  int? get libraryTabIndex {
    switch (this) {
      case NavigationTab.home:
        return null;
      case NavigationTab.songs:
        return 0;
      case NavigationTab.playlists:
        return 1;
      case NavigationTab.artists:
        return 2;
    }
  }
}

class NavigationSettings {
  final List<NavigationTab> order;
  final Set<NavigationTab> hidden;
  final NavigationTab defaultTab;

  const NavigationSettings({
    required this.order,
    this.hidden = const {},
    this.defaultTab = NavigationTab.home,
  });

  factory NavigationSettings.initial() {
    return const NavigationSettings(
      order: NavigationTab.values,
      hidden: {},
      defaultTab: NavigationTab.home,
    );
  }

  NavigationSettings copyWith({
    List<NavigationTab>? order,
    Set<NavigationTab>? hidden,
    NavigationTab? defaultTab,
  }) {
    return NavigationSettings(
      order: order ?? this.order,
      hidden: hidden ?? this.hidden,
      defaultTab: defaultTab ?? this.defaultTab,
    );
  }

  /// Get visible tabs in order
  List<NavigationTab> get visibleTabs =>
      order.where((tab) => !hidden.contains(tab)).toList();

  /// Serialize to JSON string for persistence
  String toJson() {
    return jsonEncode({
      'order': order.map((t) => t.name).toList(),
      'hidden': hidden.map((t) => t.name).toList(),
      'defaultTab': defaultTab.name,
    });
  }

  /// Deserialize from JSON string
  factory NavigationSettings.fromJson(String jsonString) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);

      final orderNames = (data['order'] as List<dynamic>?) ?? [];
      final hiddenNames = (data['hidden'] as List<dynamic>?) ?? [];
      final defaultTabName = data['defaultTab'] as String?;

      final order = orderNames
          .map(
            (name) => NavigationTab.values.firstWhere(
              (t) => t.name == name,
              orElse: () => NavigationTab.home,
            ),
          )
          .toList();

      // Ensure all tabs are present in order
      for (final tab in NavigationTab.values) {
        if (!order.contains(tab)) {
          order.add(tab);
        }
      }

      final hidden = hiddenNames
          .map(
            (name) => NavigationTab.values.firstWhere(
              (t) => t.name == name,
              orElse: () => NavigationTab.home,
            ),
          )
          .toSet();

      final defaultTab = NavigationTab.values.firstWhere(
        (t) => t.name == defaultTabName,
        orElse: () => NavigationTab.home,
      );

      return NavigationSettings(
        order: order,
        hidden: hidden,
        defaultTab: defaultTab,
      );
    } catch (e) {
      return NavigationSettings.initial();
    }
  }
}
