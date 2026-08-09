import 'package:flutter/material.dart';

import 'features/player/models/playlist/widgets/playlist_screen.dart';
import 'features/player/models/widgets/mini_player.dart';
void main (){
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple), // TEMP — real theming comes later
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