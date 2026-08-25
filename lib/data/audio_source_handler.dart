import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../features/player/models/track.dart';

class AudioSourceHandler extends BaseAudioHandler with QueueHandler, SeekHandler {

  final AudioPlayer _player = AudioPlayer();
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
    final item = _toMediaItem(track);
    mediaItem.add(item);
    await _player.setAudioSource(_toAudioSource(track, item));
    await _player.play();
  }
  Future<void> loadQueue(List<Track> tracks, {int initialIndex = 0}) async {
    final items = tracks.map(_toMediaItem).toList();
    queue.add(items);

    final sources = [
      for (var i = 0; i < tracks.length; i++)
        _toAudioSource(tracks[i], items[i]),
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
  AudioSourceHandler() {
    _player.playbackEventStream.listen(_broadcastState);
  }

///just_audio doesn't take a Track it takes an AudioSource, built from a Uri
///and separately,audio_service wants a MediaItem like title/artist..etc to actually display in the notification
///so loading one track means building both from our one Track
}