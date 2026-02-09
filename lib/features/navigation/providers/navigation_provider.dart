import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/navigation_tab.dart';

const _settingsKey = 'navigation_settings';

class NavigationNotifier extends Notifier<NavigationSettings> {
  @override
  NavigationSettings build() {
    // Load settings asynchronously after initial build
    _loadSettings();
    return NavigationSettings.initial();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_settingsKey);
    if (jsonString != null) {
      state = NavigationSettings.fromJson(jsonString);
    } else {
      // No saved settings, mark as loaded with defaults
      state = state.copyWith(isLoaded: true);
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, state.toJson());
  }

  void reorder(int oldIndex, int newIndex) {
    final newOrder = List<NavigationTab>.from(state.order);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = newOrder.removeAt(oldIndex);
    newOrder.insert(newIndex, item);
    state = state.copyWith(order: newOrder);
    _saveSettings();
  }

  void toggleVisibility(NavigationTab tab) {
    final newHidden = Set<NavigationTab>.from(state.hidden);
    if (newHidden.contains(tab)) {
      newHidden.remove(tab);
    } else {
      // Prevent hiding the last visible tab
      if (state.visibleTabs.length <= 1 && !newHidden.contains(tab)) {
        return;
      }
      newHidden.add(tab);
    }

    // If hiding the default tab, reset default to first visible tab
    NavigationTab? newDefault;
    if (newHidden.contains(state.defaultTab)) {
      final visibleAfterHide = state.order
          .where((t) => !newHidden.contains(t))
          .toList();
      if (visibleAfterHide.isNotEmpty) {
        newDefault = visibleAfterHide.first;
      }
    }

    state = state.copyWith(hidden: newHidden, defaultTab: newDefault);
    _saveSettings();
  }

  void setDefaultTab(NavigationTab tab) {
    // Only allow setting visible tabs as default
    if (state.hidden.contains(tab)) {
      return;
    }
    state = state.copyWith(defaultTab: tab);
    _saveSettings();
  }
}

final navigationProvider =
    NotifierProvider<NavigationNotifier, NavigationSettings>(
      NavigationNotifier.new,
    );
