import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/navigation_tab.dart';

// TODO: Persist settings using SharedPreferences or similar
class NavigationNotifier extends Notifier<NavigationSettings> {
  @override
  NavigationSettings build() {
    return NavigationSettings.initial();
  }

  void reorder(int oldIndex, int newIndex) {
    final newOrder = List<NavigationTab>.from(state.order);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = newOrder.removeAt(oldIndex);
    newOrder.insert(newIndex, item);
    state = state.copyWith(order: newOrder);
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
    state = state.copyWith(hidden: newHidden);
  }
}

final navigationProvider =
    NotifierProvider<NavigationNotifier, NavigationSettings>(
      NavigationNotifier.new,
    );
