import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme.dart';
import 'theme_provider.dart';

class ThemePickerScreen extends ConsumerWidget {
  const ThemePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Theme')),
      body: ListView(
        children: AppThemePreset.values.map((preset) {
          final previewTheme = AppTheme.themeFor(preset);
          final isSelected = preset == current;

          return ListTile(
            leading: CircleAvatar(backgroundColor: previewTheme.colorScheme.primary),
            title: Text(_label(preset)),
            trailing: isSelected ? const Icon(Icons.check) : null,
            onTap: () => ref.read(themeProvider.notifier).setPreset(preset),
          );
        }).toList(),
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