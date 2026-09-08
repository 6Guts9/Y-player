import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../providers/player_provider.dart';

import 'bar_player.dart';
import 'full_player.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(playerProvider.select((s) => s.currentTrack));

    if (track == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            elevation: 8,
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.7),
            child: InkWell(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const FullPlayer(),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BarPlayer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 4, 8),
                    child: Row(
                      children: [
                        Hero(
                          tag: 'artwork_${track.id}',
                          child: QueryArtworkWidget(
                            id: int.parse(track.id),
                            type: ArtworkType.AUDIO,
                            artworkWidth: 40,
                            artworkHeight: 40,
                            artworkBorder: BorderRadius.circular(8),
                            nullArtworkWidget: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.music_note, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(track.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
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
