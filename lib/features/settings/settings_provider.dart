import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool keepScreenOn;
  const SettingsState({this.keepScreenOn = true});

  SettingsState copyWith({bool? keepScreenOn}) =>
      SettingsState(keepScreenOn: keepScreenOn ?? this.keepScreenOn);
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  static const _keyKeepScreenOn = 'settings_keep_screen_on';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final keep = prefs.getBool(_keyKeepScreenOn) ?? true;
    state = state.copyWith(keepScreenOn: keep);
  }

  Future<void> setKeepScreenOn(bool value) async {
    state = state.copyWith(keepScreenOn: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyKeepScreenOn, value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    return SettingsNotifier();
  },
);
