import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../../../../core/themes/theme_provider.dart';
import '../../../../../core/themes/wallpaper.dart';
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
    final wallpaperOn = ref.watch(wallpaperEnabledProvider);
    final hasWallpaper = wallpaperOn && AppWallpaper.wallpaperFor(ref.watch(themeProvider)) != null;
    return Scaffold(
      backgroundColor: hasWallpaper ? Colors.transparent : null,
      appBar: AppBar(title: Text(current.name)),
      body: tracks.isEmpty
          ? const Center(child: Text('No tracks yet — add some from the Library tab'))
          : ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];
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
                    leading: Hero(
                      tag: 'artwork_${track.id}',
                      child: QueryArtworkWidget(
                        id: int.parse(track.id),
                        type: ArtworkType.AUDIO,
                        artworkWidth: 48,
                        artworkHeight: 48,
                        artworkBorder: BorderRadius.circular(8),
                        nullArtworkWidget: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.music_note),
                        ),
                      ),
                    ),
                    title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => ref.read(playlistProvider.notifier).removeTrack(current.id, track.id),
                    ),
                    onTap: () => ref.read(playerProvider.notifier).playQueue(tracks, startIndex: index),
                  ),
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
