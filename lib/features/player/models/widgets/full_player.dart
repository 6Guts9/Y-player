import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../providers/player_provider.dart';
import '../player_status.dart';
import 'bar_player.dart';

class FullPlayer extends ConsumerWidget {
  const FullPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only watch currentTrack for the top section (Artwork, Title, Artist)
    final track = ref.watch(playerProvider.select((s) => s.currentTrack));
    final notifier = ref.read(playerProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            track == null
                ? _artworkPlaceholder(context)
                : QueryArtworkWidget(
                    key: ValueKey(track.id), // Ensure it stays stable
                    id: int.parse(track.id),
                    type: ArtworkType.AUDIO,
                    artworkWidth: 220,
                    artworkHeight: 220,
                    artworkBorder: BorderRadius.circular(12),
                    nullArtworkWidget: _artworkPlaceholder(context),
                  ),
            const SizedBox(height: 30),
            Text(
              track?.title ?? 'Nothing playing',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            Text(
              track?.artist ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const BarPlayer(showLabels: true),
            const _PlayerControls(),
          ],
        ),
      ),
    );
  }

  Widget _artworkPlaceholder(BuildContext context) => Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.music_note, size: 64),
      );
}

class _PlayerControls extends ConsumerWidget {
  const _PlayerControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch only playback state properties, NOT position
    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));
    final isShuffle = ref.watch(playerProvider.select((s) => s.isShuffleEnabled));
    final repeatMode = ref.watch(playerProvider.select((s) => s.repeatMode));
    final notifier = ref.read(playerProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            Icons.shuffle,
            color: isShuffle ? Theme.of(context).colorScheme.primary : null,
          ),
          onPressed: notifier.toggleShuffle,
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous),
          iconSize: 36,
          onPressed: notifier.skipPrevious,
        ),
        IconButton.filled(
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
          iconSize: 36,
          onPressed: notifier.togglePlayPause,
        ),
        IconButton(
          icon: const Icon(Icons.skip_next),
          iconSize: 36,
          onPressed: notifier.skipNext,
        ),
        IconButton(
          icon: Icon(
            repeatMode == RepeatMode.one ? Icons.repeat_one : Icons.repeat,
          ),
          color: repeatMode == RepeatMode.off
              ? null
              : Theme.of(context).colorScheme.primary,
          onPressed: notifier.cycleRepeatMode,
        ),
      ],
    );
  }
}
