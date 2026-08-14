import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/themes/theme.dart';
import 'core/themes/theme_provider.dart';
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

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _index = 0;

  static const _screens = [LibraryScreen(), PlaylistScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
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