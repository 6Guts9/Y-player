import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/themes/theme_provider.dart';
import '../../../../../core/themes/wallpaper.dart';
import '../../../../../core/services/update_service.dart';
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
    final wallpaperOn = ref.watch(wallpaperEnabledProvider);
    final hasWallpaper = wallpaperOn && AppWallpaper.wallpaperFor(ref.watch(themeProvider)) != null;

    return Scaffold(
      backgroundColor: hasWallpaper ? Colors.transparent : null,
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.update),
            tooltip: 'Check for updates',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Checking for updates...'), duration: Duration(seconds: 1)),
              );
              final release = await ref.refresh(updateCheckProvider.future);
              if (context.mounted && release == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Your app is up to date!')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.palette),
            color: Theme.of(context).colorScheme.primary,
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
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
                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 300 + (index % 10 * 50)),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.playlist_play,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(playlist.name, style: const TextStyle(fontWeight: FontWeight.bold)),
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