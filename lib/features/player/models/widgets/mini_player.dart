import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../track.dart';
import '../providers/player_provider.dart';
import '../../../../core/themes/theme.dart';
import '../../../../core/themes/theme_provider.dart';

import 'bar_player.dart';
import 'full_player.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(playerProvider.select((s) => s.currentTrack));
    final preset = ref.watch(themeProvider);
    final playerUiThemed = ref.watch(playerUiThemedProvider);

    if (track == null) return const SizedBox.shrink();

    final isCybersigilismThemed = playerUiThemed && preset == AppThemePreset.cybersigilism;

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
              child: Stack(
                children: [
                  if (isCybersigilismThemed)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _CRTPainter(Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ),
                  Container(
                    decoration: isCybersigilismThemed
                        ? const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/art2.png'),
                              fit: BoxFit.cover,
                              opacity: 0.15,
                            ),
                          )
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const BarPlayer(showLabels: false),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 4, 8),
                          child: Row(
                            children: [
                              Hero(
                                tag: 'artwork_${track.id}',
                                child: track.sourceType == AudioSourceType.remote && track.artworkUri != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          track.artworkUri!,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _artworkPlaceholder(context, 40),
                                        ),
                                      )
                                    : QueryArtworkWidget(
                                        id: int.tryParse(track.id) ?? 0,
                                        type: ArtworkType.AUDIO,
                                        artworkWidth: 40,
                                        artworkHeight: 40,
                                        artworkBorder: BorderRadius.circular(8),
                                        nullArtworkWidget: _artworkPlaceholder(context, 40),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      track.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: isCybersigilismThemed ? 1.5 : 0,
                                      ),
                                    ),
                                    Text(
                                      track.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontStyle: isCybersigilismThemed ? FontStyle.italic : null,
                                          ),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _artworkPlaceholder(BuildContext context, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.music_note, size: size / 2),
      );
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

class _CRTPainter extends CustomPainter {
  final Color color;
  _CRTPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.03)
      ..strokeWidth = 1.0;

    // Subtle scanlines
    for (double i = 0; i < size.height; i += 3) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
    
    // Subtle vertical scanlines
    for (double i = 0; i < size.width; i += 3) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
