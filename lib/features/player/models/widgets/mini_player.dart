import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/player_provider.dart';

import 'bar_player.dart';
import 'full_player.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only watch currentTrack for the metadata
    final track = ref.watch(playerProvider.select((s) => s.currentTrack));

    if (track == null) return const SizedBox.shrink();

    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => const FullPlayer(),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BarPlayer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 4, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(track.title,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(
                            track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const _MiniControls(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniControls extends ConsumerWidget {
  const _MiniControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));
    final notifier = ref.read(playerProvider.notifier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous),
          onPressed: notifier.skipPrevious,
        ),
        IconButton(
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: notifier.togglePlayPause,
        ),
        IconButton(
          icon: const Icon(Icons.skip_next),
          onPressed: notifier.skipNext,
        ),
      ],
    );
  }
}
