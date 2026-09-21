import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'themed_bar.dart';
import '../../../../core/themes/theme_provider.dart';

import '../providers/player_provider.dart';

class BarPlayer extends ConsumerWidget {
  final bool showLabels;

  const BarPlayer({super.key, this.showLabels = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(playerProvider.notifier);
    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));
    final playerUiThemed = ref.watch(playerUiThemedProvider);

    return StreamBuilder<Duration>(
      stream: notifier.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;

        return StreamBuilder<Duration>(
          stream: notifier.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;

            final maxMs = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
            final value = position.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (playerUiThemed)
                  ThemedBar(
                    value: value,
                    max: maxMs,
                    isPlaying: isPlaying,
                    onChanged: duration == Duration.zero
                        ? null
                        : (v) => notifier.seek(Duration(milliseconds: v.round())),
                  )
                else
                  Slider(
                    value: value,
                    max: maxMs,
                    onChanged: duration == Duration.zero
                        ? null
                        : (v) => notifier.seek(Duration(milliseconds: v.round())),
                  ),
                if (showLabels)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(_format(position)),
                        const Spacer(),
                        Text(_format(duration)),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  String _format(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}