import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/player_provider.dart';

class BarPlayer extends ConsumerWidget {
  final bool showLabels;

  const BarPlayer({super.key, this.showLabels = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(playerProvider.select((s) => s.position));
    final duration = ref.watch(playerProvider.select((s) => s.currentTrack?.duration)) ?? Duration.zero;

    final maxMs = duration.inMilliseconds > 0
        ? duration.inMilliseconds.toDouble()
        : 1.0;
    final value = position.inMilliseconds
        .clamp(0, maxMs.toInt())
        .toDouble();

    final slider = Slider(
      value: value,
      max: maxMs,
      onChanged: duration == Duration.zero
          ? null
          : (v) => ref
          .read(playerProvider.notifier)
          .seek(Duration(milliseconds: v.round())),
    );

    if (!showLabels) return slider;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        slider,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_format(position)),
              Text(_format(duration)),
            ],
          ),
        ),
      ],
    );
  }

  String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}