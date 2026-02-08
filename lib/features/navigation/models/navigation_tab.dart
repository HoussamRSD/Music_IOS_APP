import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
}

class NavigationSettings {
  final List<NavigationTab> order;
  final Set<NavigationTab> hidden;

  const NavigationSettings({required this.order, this.hidden = const {}});

  factory NavigationSettings.initial() {
    return const NavigationSettings(order: NavigationTab.values, hidden: {});
  }

  NavigationSettings copyWith({
    List<NavigationTab>? order,
    Set<NavigationTab>? hidden,
  }) {
    return NavigationSettings(
      order: order ?? this.order,
      hidden: hidden ?? this.hidden,
    );
  }

  // Get visible tabs in order
  List<NavigationTab> get visibleTabs =>
      order.where((tab) => !hidden.contains(tab)).toList();
}
