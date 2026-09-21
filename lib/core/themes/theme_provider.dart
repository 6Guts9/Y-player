import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/hiveboxes.dart';
import 'theme.dart';

const _themePresetKey = 'theme_preset';
const _wallpaperEnabledKey = 'wallpaper_enabled';
const _playerUiThemedKey = 'player_ui_themed';

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemePreset>((ref) {
  return ThemeNotifier();
});

final wallpaperEnabledProvider = StateNotifierProvider<WallpaperNotifier, bool>((ref) {
  return WallpaperNotifier();
});

final playerUiThemedProvider = StateNotifierProvider<PlayerUiThemedNotifier, bool>((ref) {
  return PlayerUiThemedNotifier();
});

class ThemeNotifier extends StateNotifier<AppThemePreset> {
  ThemeNotifier() : super(_loadSaved());

  static AppThemePreset _loadSaved() {
    final saved = HiveBoxes.settingsBox.get(_themePresetKey) as String?;
    if (saved == null) return AppThemePreset.minimalist;
    return AppThemePreset.values.firstWhere(
          (p) => p.name == saved,
      orElse: () => AppThemePreset.minimalist,
    );
  }

  Future<void> setPreset(AppThemePreset preset) async {
    state = preset;
    await HiveBoxes.settingsBox.put(_themePresetKey, preset.name);
  }
}

class WallpaperNotifier extends StateNotifier<bool> {
  WallpaperNotifier() : super(_loadSaved());

  static bool _loadSaved() {
    return HiveBoxes.settingsBox.get(_wallpaperEnabledKey) as bool? ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    await HiveBoxes.settingsBox.put(_wallpaperEnabledKey, state);
  }
}

class PlayerUiThemedNotifier extends StateNotifier<bool> {
  PlayerUiThemedNotifier() : super(_loadSaved());

  static bool _loadSaved() {
    return HiveBoxes.settingsBox.get(_playerUiThemedKey) as bool? ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    await HiveBoxes.settingsBox.put(_playerUiThemedKey, state);
  }
}
