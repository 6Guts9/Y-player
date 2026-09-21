import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme.dart';
import 'theme_provider.dart';

class ThemePickerScreen extends ConsumerWidget {
  const ThemePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeProvider);
    final wallpaperOn = ref.watch(wallpaperEnabledProvider);
    final playerUiThemed = ref.watch(playerUiThemedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Theme')),
      body: ListView(
        children: [
          SwitchListTile(
            title:  const Text('Themed wallpaper',style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Decorative background matching your theme \n \n (only pixel art and aurora are supported)'),
            secondary: const Icon(Icons.wallpaper),
            value: wallpaperOn,
            onChanged: (_) => ref.read(wallpaperEnabledProvider.notifier).toggle(),
          ),
          SwitchListTile(
            title: const Text('Themed player UI', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Use animated and themed components in player screens'),
            secondary: const Icon(Icons.animation),
            value: playerUiThemed,
            onChanged: (_) => ref.read(playerUiThemedProvider.notifier).toggle(),
          ),
          const Divider(),
          ...AppThemePreset.values.map((preset) {
            final previewTheme = AppTheme.themeFor(preset);
            final isSelected = preset == current;

            return ListTile(
              leading: CircleAvatar(backgroundColor: previewTheme.colorScheme.primary),
              title: Text(_label(preset)),
              trailing: isSelected ? const Icon(Icons.check) : null,
              onTap: () => ref.read(themeProvider.notifier).setPreset(preset),
            );
          }),
        ],
      ),
    );
  }

  String _label(AppThemePreset preset) {
    switch (preset) {
      case AppThemePreset.minimalist: return 'Minimalist';
      case AppThemePreset.pixelArt: return 'Pixel Art';
      case AppThemePreset.artDeco: return 'Art Deco';
      case AppThemePreset.cybersigilism: return 'Cybersigilism';
      case AppThemePreset.aurora: return 'Aurora';
      case AppThemePreset.ascii: return 'ASCII';
    }
  }
}