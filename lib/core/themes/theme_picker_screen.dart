import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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
      appBar: AppBar(title: const Text('Theme & Support')),
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
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Support Development',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.coffee, color: Color(0xFFFF5E5B)),
            title: const Text('Support on Ko-fi'),
            subtitle: const Text('ko-fi.com/dberserker'),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () async {
              final uri = Uri.parse('https://ko-fi.com/dberserker');
              try {
                final launched = await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
                if (!launched) {
                  await launchUrl(uri, mode: LaunchMode.platformDefault);
                }
              } catch (_) {
                try {
                  await launchUrl(uri, mode: LaunchMode.platformDefault);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not launch browser: $e')),
                    );
                  }
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance, color: Colors.teal),
            title: const Text('CCP (Algeria Local)'),
            subtitle: const Text('00799999004148926013'),
            trailing: const Icon(Icons.copy, size: 20),
            onTap: () {
              Clipboard.setData(const ClipboardData(text: '00799999004148926013'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('CCP account number copied to clipboard!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
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