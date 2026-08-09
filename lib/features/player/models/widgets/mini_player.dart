import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/player_provider.dart';

import 'bar_player.dart';
import 'full_player.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    final track = state.currentTrack;

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
                    IconButton(
                      icon: Icon(
                        state.isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                      onPressed: () =>
                          ref.read(playerProvider.notifier).togglePlayPause(),
                    ),
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