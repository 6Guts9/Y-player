import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/update_service.dart';
import 'core/themes/theme.dart';
import 'core/themes/theme_provider.dart';
import 'core/themes/wallpaper.dart';

import 'package:url_launcher/url_launcher.dart';
import 'features/player/models/playlist/widgets/library_screen.dart';
import 'features/player/models/playlist/widgets/playlist_screen.dart';
import 'features/player/models/widgets/mini_player.dart';
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preset = ref.watch(themeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Y Player',
      theme: AppTheme.themeFor(preset),
      home: const _Shell(),
    );
  }


}
void _showUpdateNotification(BuildContext context, GitHubRelease release) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('New version available: ${release.version}'),
      duration: const Duration(seconds: 10),
      action: SnackBarAction(
        label: 'Update',
        onPressed: () => launchUrl(Uri.parse(release.releaseUrl)),
      ),
    ),
  );
}
class _Shell extends ConsumerStatefulWidget {
  const _Shell({super.key});

  @override
  ConsumerState<_Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<_Shell> {
  int _index = 0;
  static const _screens = [LibraryScreen(), PlaylistScreen()];

  @override
  Widget build(BuildContext context) {
    ref.listen(updateCheckProvider, (previous, next) {
      next.whenData((release) {
        if (release != null && mounted) {
          _showUpdateNotification(context, release);
        }
      });
    });

    final preset = ref.watch(themeProvider);
    final wallpaperOn = ref.watch(wallpaperEnabledProvider);
    final wallpaper = wallpaperOn ? AppWallpaper.wallpaperFor(preset) : null;

    return Scaffold(
      body: Stack(
        children: [
          if (wallpaper != null) Positioned.fill(child: wallpaper),
          _screens[_index],
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [const MiniPlayer(), NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.library_music_outlined), label: 'Library'),
              NavigationDestination(icon: Icon(Icons.queue_music_outlined), label: 'Playlists'),
            ],
          ),
        ],
      ),
    );
  }
}