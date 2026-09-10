import 'package:flutter/material.dart' hide RepeatMode;
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../providers/equalizer.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../player_status.dart';
import 'bar_player.dart';
import '../track.dart';

class FullPlayer extends ConsumerWidget {
  const FullPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(playerProvider.select((s) => s.currentTrack));
    final library = ref.watch(trackLibraryProvider);
    final isFavorite = track != null && library.any((t) => t.id == track.id && t.isFavorite);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                track == null
                    ? _artworkPlaceholder(context)
                    : _ArtworkWidget(trackId: track.id),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    key: ValueKey(track?.id),
                    children: [
                      Text(
                        track?.title ?? 'Nothing playing',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        track?.artist ?? '',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                      color: isFavorite ? Colors.red : null,
                      iconSize: 32,
                      onPressed: track == null
                          ? null
                          : () => ref.read(trackLibraryProvider.notifier).toggleFavorite(track.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: track == null ? null : () => _showTrackInfo(context, track),
                    ),
                    IconButton(
                      icon: const Icon(Icons.graphic_eq_outlined),
                      onPressed: () => track == null
                          ? null
                          : _showEqualizer(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const BarPlayer(showLabels: true),
                const SizedBox(height: 12),
                const _PlayerControls(),
                const SizedBox(height: 24),
              ],
            ),
          ),
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

  void _showTrackInfo(BuildContext context, Track track) {
    int? sizeBytes;
    if (track.sourceType == AudioSourceType.local) {
      final file = File(track.uri);
      if (file.existsSync()) sizeBytes = file.lengthSync();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Song info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow('Title', track.title),
            _InfoRow('Artist', track.artist),
            if (track.album != null) _InfoRow('Album', track.album!),
            _InfoRow('Duration', _formatDuration(track.duration)),
            _InfoRow('Date added', '${track.dateAdded.day}/${track.dateAdded.month}/${track.dateAdded.year}'),
            _InfoRow('Play count', track.playCount.toString()),
            if (sizeBytes != null)
              _InfoRow('File size', '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB'),

          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showEqualizer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EqualizerSection(),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }


}
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: Theme.of(context).textTheme.labelMedium)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ArtworkWidget extends StatelessWidget {
  final String trackId;
  const _ArtworkWidget({required this.trackId});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'artwork_$trackId',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: QueryArtworkWidget(
          key: ValueKey(trackId),
          id: int.parse(trackId),
          type: ArtworkType.AUDIO,
          artworkWidth: 280,
          artworkHeight: 280,
          artworkBorder: BorderRadius.circular(24),
          size: 1000,
          quality: 100,
          keepOldArtwork: true,
          nullArtworkWidget: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.music_note, size: 80),
          ),
        ),
      ),
    );
  }
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
class EqualizerSection extends ConsumerWidget {
  const EqualizerSection({super.key});

  String _formatFrequency(double hz) {
    if (hz >= 1000) {
      final khz = hz / 1000;
      return '${khz.toStringAsFixed(khz.truncateToDouble() == khz ? 0 : 1)}kHz';
    }
    return '${hz.toStringAsFixed(0)}Hz';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eq = ref.watch(equalizerProvider);
    final notifier = ref.read(equalizerProvider.notifier);
    final paramsAsync = ref.watch(equalizerParamsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Equalizer', style: TextStyle(fontWeight: FontWeight.bold)),
            Switch(
              value: eq.enabled,
              onChanged: notifier.toggleEnabled,
            ),
          ],
        ),
        if (eq.enabled)
          paramsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Couldn\'t load equalizer: $err'),
            ),
            data: (params) {
              final minGain = params.minDecibels;
              final maxGain = params.maxDecibels;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(eq.bandGains.length, (i) {
                  final band = params.bands[i];
                  return Column(
                    children: [
                      RotatedBox(
                        quarterTurns: 3,
                        child: Slider(
                          value: eq.bandGains[i].clamp(minGain, maxGain),
                          min: minGain,
                          max: maxGain,
                          onChanged: (v) => notifier.setBandGain(i, v),
                        ),
                      ),
                      Text(
                        _formatFrequency(band.centerFrequency),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  );
                }),
              );
            },
          ),
      ],
    );
  }
}