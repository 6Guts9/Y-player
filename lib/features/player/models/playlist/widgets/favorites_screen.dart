import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../../../core/themes/theme_provider.dart';
import '../../../../../core/themes/wallpaper.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(trackLibraryProvider).where((t) => t.isFavorite).toList();
    final wallpaperOn = ref.watch(wallpaperEnabledProvider);
    final hasWallpaper = wallpaperOn && AppWallpaper.wallpaperFor(ref.watch(themeProvider)) != null;

    return Scaffold(
      backgroundColor: hasWallpaper ? Colors.transparent : null,
      appBar: AppBar(title: const Text('Favorites')),
      body: favorites.isEmpty
          ? const Center(child: Text('No favorites yet'))
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final track = favorites[index];
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
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.music_note),
                        ),
                      ),
                    ),
                    title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => ref.read(playerProvider.notifier).playQueue(favorites, startIndex: index),
                  ),
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
