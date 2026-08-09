import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/playlist_provider.dart';

class PlaylistScreen extends ConsumerWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Playlists')),
      body: playlists.isEmpty
          ? const Center(child: Text('No playlists yet — tap + to create one'))
          : ListView.builder(
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.queue_music)),
            title: Text(playlist.name),
            subtitle: Text('${playlist.trackCount} tracks'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  ref.read(playlistProvider.notifier).delete(playlist.id),
            ),
          );
        },
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
}