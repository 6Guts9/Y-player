import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/player_provider.dart';
import '../player_status.dart';
import 'bar_player.dart';

class FullPlayer extends ConsumerWidget {
  const FullPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);
    final track = state.currentTrack;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.music_note, size: 64),
            ),
            const SizedBox(height: 24),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: state.isShuffleEnabled
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  onPressed: notifier.toggleShuffle,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 36,
                  onPressed: notifier.skipPrevious,
                ),
                IconButton.filled(
                  icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
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
                    state.repeatMode == RepeatMode.one
                        ? Icons.repeat_one
                        : Icons.repeat,
                  ),
                  color: state.repeatMode == RepeatMode.off
                      ? null
                      : Theme.of(context).colorScheme.primary,
                  onPressed: notifier.cycleRepeatMode,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}