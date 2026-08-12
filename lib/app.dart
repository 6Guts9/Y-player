import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/themes/theme.dart';
import 'core/themes/theme_provider.dart';
import 'features/player/models/playlist/widgets/playlist_screen.dart';
import 'features/player/models/widgets/mini_player.dart';
void main (){
  runApp(const MyApp());
}
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preset = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Player',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeFor(preset),
      home: const _Shell(),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: PlaylistScreen(),
      bottomNavigationBar: MiniPlayer(),
    );
  }
}