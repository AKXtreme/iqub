import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeKey = 'isDarkMode';

/// Persisted theme mode notifier.
class ThemeModeNotifier extends StateNotifier<bool> {
  ThemeModeNotifier(this._prefs) : super(_prefs.getBool(_kThemeKey) ?? false);

  final SharedPreferences _prefs;

  bool get isDark => state;

  void toggle() {
    state = !state;
    _prefs.setBool(_kThemeKey, state);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});
