import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../track.dart';
import '../providers/playlist_provider.dart';


class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(trackLibraryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: tracks.isEmpty
          ? const Center(child: Text('No songs found — pull down to refresh'))
          : RefreshIndicator(
        onRefresh: () => ref.read(trackLibraryProvider.notifier).refresh(),
        child: ListView.builder(
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.music_note)),
              title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.playlist_add),
                onPressed: () => _showAddToPlaylist(context, track),
              ),
              onTap: () => ref
                  .read(playerProvider.notifier)
                  .playQueue(tracks, startIndex: index),
            );
          },
        ),
      ),
    );
  }

  void _showAddToPlaylist(BuildContext context, Track track) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final playlists = ref.watch(playlistProvider);
          if (playlists.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No playlists yet — create one from the Playlists tab'),
            );
          }
          return ListView(
            shrinkWrap: true,
            children: [
              for (final playlist in playlists)
                ListTile(
                  title: Text(playlist.name),
                  onTap: () {
                    ref.read(playlistProvider.notifier).addTrack(playlist.id, track.id);
                    Navigator.pop(context);
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}