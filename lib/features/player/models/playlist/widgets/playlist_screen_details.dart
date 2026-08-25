import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/playlist.dart';
import '../providers/playlist_provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../track.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistProvider);
    final current = playlists.firstWhere(
          (p) => p.id == playlist.id,
      orElse: () => playlist,
    );

    final library = ref.watch(trackLibraryProvider);
    final byId = {for (final t in library) t.id: t};
    final tracks = current.trackIds.map((id) => byId[id]).whereType<Track>().toList();

    return Scaffold(
      appBar: AppBar(title: Text(current.name)),
      body: tracks.isEmpty
          ? const Center(child: Text('No tracks yet — add some from the Library tab'))
          : ListView.builder(
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.music_note)),
            title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => ref
                  .read(playlistProvider.notifier)
                  .removeTrack(current.id, track.id),
            ),
            onTap: () => ref
                .read(playerProvider.notifier)
                .playQueue(tracks, startIndex: index),
          );
        },
      ),
      floatingActionButton: tracks.isEmpty
          ? null
          : FloatingActionButton.extended(
        onPressed: () => ref.read(playerProvider.notifier).playQueue(tracks),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Play all'),
      ),
    );
  }
}