import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'favorites_screen.dart';
import 'playlist_screen_details.dart';
import '../../../../../core/themes/theme_picker_screen.dart';
import '../../providers/player_provider.dart';
import '../models/playlist.dart';
import '../providers/playlist_provider.dart';
import '../../providers/library_provider.dart';
import '../../track.dart';

class PlaylistScreen extends ConsumerWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ThemePickerScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.favorite, color: Colors.white),
            ),
            title: const Text('Favorites'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavoritesScreen()),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: playlists.isEmpty
                ? const Center(child: Text('No playlists yet — tap + to create one'))
                : ListView.builder(
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      return ListTile(
                        leading: const Icon(Icons.playlist_play),
                        title: Text(playlist.name),
                        subtitle: Text('${playlist.trackIds.length} tracks'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlaylistDetailScreen(playlist: playlist),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () => _play(ref, playlist),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createPlaylist(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _createPlaylist(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await ref.read(playlistProvider.notifier).create(name);
    }
  }

  void _play(WidgetRef ref, Playlist playlist) {
    final library = ref.read(trackLibraryProvider);
    final byId = {for (final t in library) t.id: t};
    final tracks = playlist.trackIds.map((id) => byId[id]).whereType<Track>().toList();
    if (tracks.isNotEmpty) {
      ref.read(playerProvider.notifier).playQueue(tracks);
    }
  }
}