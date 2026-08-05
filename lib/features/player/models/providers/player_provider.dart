
import 'package:audio_service/audio_service.dart' hide PlaybackState;
import 'package:just_audio/just_audio.dart' show LoopMode;
import 'package:riverpod/riverpod.dart';
import '../../../../data/audio_source_handler.dart';
import '../player_status.dart';
import '../track.dart';

final audioHandlerProvider = Provider<AudioSourceHandler>((ref) {
  throw UnimplementedError(
    'audioHandlerProvider must be overridden in main.dart after '
        'AudioService.init() resolves.',
  );
});
class PlayerNotifier extends StateNotifier<PlaybackState> {
  final AudioSourceHandler _handler;
  List<Track> _queue = [];

  PlayerNotifier(this._handler) : super(const PlaybackState()) {
    _handler.playbackState.listen((s) {
      state = state.copyWith(
        status: _mapStatus(s.processingState, s.playing),
        position: s.updatePosition,
        bufferedPosition: s.bufferedPosition,
        currentTrack: _trackAt(s.queueIndex),
      );
    });
  }

  Track? _trackAt(int? index) {
    if (index == null || index < 0 || index >= _queue.length) {
      return state.currentTrack; // nothing new to report, keep what we had
    }
    return _queue[index];
  }
  PlayerStatus _mapStatus(AudioProcessingState processingState, bool playing) {
    switch (processingState) {
      case AudioProcessingState.error:
        return PlayerStatus.error;
      case AudioProcessingState.completed:
        return PlayerStatus.completed;
      case AudioProcessingState.loading:
      case AudioProcessingState.buffering:
        return PlayerStatus.loading;
      case AudioProcessingState.idle:
      case AudioProcessingState.ready:
        return playing ? PlayerStatus.playing : PlayerStatus.paused;
    }
  }

  Future<void> playTrack(Track track) {
    _queue = [track];
    return _handler.playTrack(track);
  }

  Future<void> playQueue(List<Track> tracks, {int startIndex = 0}) {
    _queue = tracks;
    return _handler.loadQueue(tracks, initialIndex: startIndex);
  }

  Future<void> togglePlayPause() {
    return state.isPlaying ? _handler.pause() : _handler.play();
  }

  Future<void> seek(Duration position) => _handler.seek(position);

  Future<void> skipNext() => _handler.skipToNext();

  Future<void> skipPrevious() => _handler.skipToPrevious();

  Future<void> toggleShuffle() async {
    final next = !state.isShuffleEnabled;
    await _handler.setShuffleEnabled(next);
    state = state.copyWith(isShuffleEnabled: next);
  }

  Future<void> cycleRepeatMode() async {
    final next = switch (state.repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    await _handler.setLoopMode(switch (next) {
      RepeatMode.off => LoopMode.off,
      RepeatMode.all => LoopMode.all,
      RepeatMode.one => LoopMode.one,
    });
    state = state.copyWith(repeatMode: next);
  }
}

final playerProvider = StateNotifierProvider<PlayerNotifier, PlaybackState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return PlayerNotifier(handler);
});