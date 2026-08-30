import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import '../features/player/models/track.dart';

class AudioSourceHandler extends BaseAudioHandler with QueueHandler, SeekHandler {

  final AudioPlayer _player = AudioPlayer();
  final OnAudioQuery _artworkQuery = OnAudioQuery();
  final Map<String, Uri> _artworkCache = {};
  List<MediaItem> _queueItems = [];
  Future<Uri?> _resolveArtworkUri(String trackId) async {
    if (_artworkCache.containsKey(trackId)) return _artworkCache[trackId];

    final bytes = await _artworkQuery.queryArtwork(
      int.parse(trackId),
      ArtworkType.AUDIO,
      format: ArtworkFormat.JPEG,
      size: 500,
    );
    if (bytes == null || bytes.isEmpty) return null;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/artwork_$trackId.jpg');
    await file.writeAsBytes(bytes);

    final uri = Uri.file(file.path);
    _artworkCache[trackId] = uri;
    return uri;
  }
  void _broadcastState(PlaybackEvent event) {
    playbackState.add(playbackState.value.copyWith(
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      controls: [
        MediaControl.skipToPrevious,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      processingState: switch (_player.processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      },
      queueIndex: event.currentIndex,
    ));
  }
  Future<void> playTrack(Track track) async {
    _queueItems = [_toMediaItem(track)];
    queue.add(_queueItems);
    await _player.setAudioSource(_toAudioSource(track, _queueItems.first));
    await _player.play();
  }

  Future<void> loadQueue(List<Track> tracks, {int initialIndex = 0}) async {
    _queueItems = tracks.map(_toMediaItem).toList();
    queue.add(_queueItems);

    final sources = [
      for (var i = 0; i < tracks.length; i++)
        _toAudioSource(tracks[i], _queueItems[i]),
    ];

    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: initialIndex,
    );
    await _player.play();
  }
  Future<void> setShuffleEnabled(bool enabled) =>
      _player.setShuffleModeEnabled(enabled);

  Future<void> setLoopMode(LoopMode mode) => _player.setLoopMode(mode);

  Future<void> dispose() => _player.dispose();
  
  AudioSource _toAudioSource(Track track, MediaItem tag) {
    return track.sourceType == AudioSourceType.remote
        ? AudioSource.uri(Uri.parse(track.uri), tag: tag)
        : AudioSource.uri(Uri.file(track.uri), tag: tag);
  }


  MediaItem _toMediaItem(Track track) => MediaItem(
        id: track.id,
        title: track.title,
        artist: track.artist,
        duration: track.duration,
        artUri: _artworkCache[track.id],
      );
  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  int? _lastIndex;

  AudioSourceHandler() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.currentIndexStream.listen((index) {
      if (index != null && index != _lastIndex) {
        _lastIndex = index;
        _updateMetadata(index);
      }
    });
  }

  // Optimized metadata update to prevent flicker
  Future<void> _updateMetadata(int index) async {
    if (index < 0 || index >= _queueItems.length) return;

    final base = _queueItems[index];

    if (_artworkCache.containsKey(base.id)) {
      mediaItem.add(base.copyWith(artUri: _artworkCache[base.id]));
      return;
    }


    mediaItem.add(base);
    final artUri = await _resolveArtworkUri(base.id);

    if (_lastIndex == index) {
      mediaItem.add(artUri != null ? base.copyWith(artUri: artUri) : base);
    }
  }

///just_audio doesn't take a Track it takes an AudioSource, built from a Uri
///and separately,audio_service wants a MediaItem like title/artist..etc to actually display in the notification
///so loading one track means building both from our one Track
}