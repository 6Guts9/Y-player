import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(trackLibraryProvider).where((t) => t.isFavorite).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favorites.isEmpty
          ? const Center(child: Text('No favorites yet — tap the heart on a song to add it'))
          : ListView.builder(
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final track = favorites[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.music_note)),
            title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => ref.read(playerProvider.notifier).playQueue(favorites, startIndex: index),
          );
        },
      ),
      floatingActionButton: favorites.isEmpty
          ? null
          : FloatingActionButton.extended(
        onPressed: () => ref.read(playerProvider.notifier).playQueue(favorites),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Play all'),
      ),
    );
  }
}