import "track.dart";
enum PlayerStatus {idle , loading ,playing ,paused ,completed,error}
enum RepeatMode {off,one,all}

class PlaybackState {
  final Track ? currentTrack ;
  final PlayerStatus status ;
  final Duration position ;
  final Duration bufferedPosition;
  final bool isShuffeledEnabled;
  final RepeatMode repeatMode;

const PlaybackState({
  this.currentTrack,
  this.status = PlayerStatus.idle,
  this.position = Duration.zero,
  this.bufferedPosition = Duration.zero,
  this.isShuffeledEnabled = false,
  this.repeatMode = RepeatMode.off,
});

bool get isPlaying => status == PlayerStatus.playing;
double get progress {
final total = currentTrack?.duration.inMilliseconds ?? 0;
if (total == 0) return 0.0;
return (position.inMilliseconds / total).clamp(0.0,1.0);

///0.0–1.0 value for a progress bar computed from position and currentTrack.duration rather than stored and kept in sync by hand
  ///clamp guards against tiny "floating-point" overshoots (e.g. 1.0000001) that would make a progress bar glitch past full (experienced this with some players)

}
PlaybackState copyWith ({
 Track? currentTrack,
  PlayerStatus? status,
  Duration? position,
  Duration? bufferedPosition,
  bool? isShuffeledEnabled,
  RepeatMode? repeatMode,
}){
  return PlaybackState(
  currentTrack: currentTrack ?? this.currentTrack,
  status: status ?? this.status,
  position: position ?? this.position,
    bufferedPosition: bufferedPosition ?? this.bufferedPosition,
  isShuffeledEnabled: isShuffeledEnabled ?? this.isShuffeledEnabled,
  repeatMode: repeatMode ?? this.repeatMode,
  );
}
}