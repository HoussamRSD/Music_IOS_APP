import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

enum NavigationTab {
  home,
  songs,
  playlists,
  artists,
  favorites,
  youtube;

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
      case NavigationTab.favorites:
        return 'Favorites';
      case NavigationTab.youtube:
        return 'YouTube';
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
      case NavigationTab.favorites:
        return CupertinoIcons.heart_fill;
      case NavigationTab.youtube:
        return CupertinoIcons.play_rectangle;
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
      case NavigationTab.favorites:
        return '/library';
      case NavigationTab.youtube:
        return '/youtube';
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
      case NavigationTab.favorites:
        return 1;
      case NavigationTab.youtube:
        return 2;
    }
  }

  /// Library tab index (for Songs, Playlists, Artists, Favorites)
  int? get libraryTabIndex {
    switch (this) {
      case NavigationTab.home:
      case NavigationTab.youtube:
        return null;
      case NavigationTab.songs:
        return 0;
      case NavigationTab.playlists:
        return 1;
      case NavigationTab.artists:
        return 2;
      case NavigationTab.favorites:
        return 3;
    }
  }
}

class NavigationSettings {
  final List<NavigationTab> order;
  final Set<NavigationTab> hidden;
  final NavigationTab defaultTab;
  final bool isLoaded; // True when settings have been loaded from storage

  const NavigationSettings({
    required this.order,
    this.hidden = const {},
    this.defaultTab = NavigationTab.home,
    this.isLoaded = false,
  });

  factory NavigationSettings.initial() {
    return const NavigationSettings(
      order: NavigationTab.values,
      hidden: {},
      defaultTab: NavigationTab.home,
      isLoaded: false, // Not loaded yet
    );
  }

  NavigationSettings copyWith({
    List<NavigationTab>? order,
    Set<NavigationTab>? hidden,
    NavigationTab? defaultTab,
    bool? isLoaded,
  }) {
    return NavigationSettings(
      order: order ?? this.order,
      hidden: hidden ?? this.hidden,
      defaultTab: defaultTab ?? this.defaultTab,
      isLoaded:
          isLoaded ??
          true, // Default to true since any modification implies loaded
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
        isLoaded: true, // Loaded from storage
      );
    } catch (e) {
      // Return initial with isLoaded true to proceed with defaults
      return NavigationSettings(
        order: NavigationTab.values,
        hidden: {},
        defaultTab: NavigationTab.home,
        isLoaded: true,
      );
    }
  }
}
