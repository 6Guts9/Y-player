import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sorting.dart';
import 'playlist_screen_details.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../track.dart';
import '../providers/playlist_provider.dart';


class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});
  List<Track> sortTracks(List<Track> tracks, LibrarySortOption option) {
    final sorted = [...tracks];
    switch (option) {
      case LibrarySortOption.dateAddedDesc:
        sorted.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      case LibrarySortOption.dateAddedAsc:
        sorted.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
      case LibrarySortOption.titleAsc:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case LibrarySortOption.titleDesc:
        sorted.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
      case LibrarySortOption.durationAsc:
        sorted.sort((a, b) => a.duration.compareTo(b.duration));
      case LibrarySortOption.durationDesc:
        sorted.sort((a, b) => b.duration.compareTo(a.duration));
    }
    return sorted;
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(trackLibraryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Library'),
      actions: [
        PopupMenuButton<LibrarySortOption>(
          icon: const Icon(Icons.sort),
          onSelected: (option) => ref.read(librarySortProvider.notifier).setOption(option),
          itemBuilder: (context) => const [
            PopupMenuItem(value: LibrarySortOption.dateAddedDesc, child: Text('Date added (newest)')),
            PopupMenuItem(value: LibrarySortOption.dateAddedAsc, child: Text('Date added (oldest)')),
            PopupMenuItem(value: LibrarySortOption.titleAsc, child: Text('Title (A–Z)')),
            PopupMenuItem(value: LibrarySortOption.titleDesc, child: Text('Title (Z–A)')),
            PopupMenuItem(value: LibrarySortOption.durationAsc, child: Text('Duration (shortest)')),
            PopupMenuItem(value: LibrarySortOption.durationDesc, child: Text('Duration (longest)')),
          ],
        ),
      ],
      ),
      body: tracks.isEmpty
          ? const Center(child: Text('No songs found — pull down to refresh'))
          : RefreshIndicator(
        onRefresh: () => ref.read(trackLibraryProvider.notifier).refresh(),
        child: ListView.builder(
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final rawTracks = ref.watch(trackLibraryProvider);
            final sortOption = ref.watch(librarySortProvider);
            final tracks = sortTracks(rawTracks, sortOption);
            final track = tracks[index];

            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.music_note)),
              title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.playlist_add),
                onPressed: () => _showAddToPlaylist(context, track),
              ),
              onTap: () => ref.read(playerProvider.notifier).playQueue(tracks, startIndex: index),
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