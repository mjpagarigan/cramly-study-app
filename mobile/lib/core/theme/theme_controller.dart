import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'theme_mode';

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController(this._prefs)
      : super(_decode(_prefs.getString(_prefsKey)));

  final SharedPreferences _prefs;

  static ThemeMode _decode(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      };

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_prefsKey, mode.name);
  }

  Future<void> toggle() => set(
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      );
}

/// Hydrated in `main.dart` before runApp so we can read the saved mode synchronously.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main.dart'),
);

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  return ThemeController(ref.watch(sharedPrefsProvider));
});
