import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import '../features/player/models/track.dart';

class AudioSourceHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final OnAudioQuery _artworkQuery = OnAudioQuery();
  final Map<String, Uri> _artworkCache = {};
  
  final AndroidEqualizer _equalizer = AndroidEqualizer();
  late final AudioPipeline _audioPipeline;
  late final AudioPlayer _player;

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
    _lastIndex = null; // Reset to force metadata update
    _queueItems = [_toMediaItem(track)];
    queue.add(_queueItems);
    
    // Prefetch artwork for the single track
    await _resolveArtworkUri(track.id);
    
    await _player.setAudioSource(_toAudioSource(track, _queueItems.first));
    await _player.play();
  }

  Future<void> loadQueue(List<Track> tracks, {int initialIndex = 0}) async {
    _lastIndex = null; // Reset to force metadata update
    _queueItems = tracks.map(_toMediaItem).toList();
    queue.add(_queueItems);

    // Prioritize current track artwork
    if (tracks.isNotEmpty) {
      await _resolveArtworkUri(tracks[initialIndex].id);
    }

    final sources = [
      for (var i = 0; i < tracks.length; i++)
        _toAudioSource(tracks[i], _queueItems[i]),
    ];

    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: initialIndex,
    );
    await _player.play();

    // Prefetch others
    _prefetchQueueArtworks(tracks, initialIndex);
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
  Future<void> onMethodCall(String method, dynamic arguments) async {
  }

  int _clickCount = 0;
  DateTime? _lastClickTime;

  @override
  Future<void> click([MediaButton button = MediaButton.media]) async {
    final now = DateTime.now();
    if (_lastClickTime != null && now.difference(_lastClickTime!) < const Duration(milliseconds: 500)) {
      _clickCount++;
    } else {
      _clickCount = 1;
    }
    _lastClickTime = now;

    // Delay a bit to wait more clicks
    await Future.delayed(const Duration(milliseconds: 500));


    if (DateTime.now().difference(_lastClickTime!) >= const Duration(milliseconds: 500)) {
      if (_clickCount == 1) {
        // Single click: Play/Pause
        if (_player.playing) {
          await pause();
        } else {
          await play();
        }
      } else if (_clickCount == 2) {
        // Double click: Next
        await skipToNext();
      } else if (_clickCount >= 3) {
        // Triple click: Previous
        await skipToPrevious();
      }
      _clickCount = 0;
    }
  }

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
  String? _lastPushedId;
  Uri? _lastPushedArtUri;

  AudioSourceHandler() {
    _audioPipeline = AudioPipeline(androidAudioEffects: [_equalizer]);
    _player = AudioPlayer(audioPipeline: _audioPipeline);

    _player.playbackEventStream.listen(_broadcastState);
    
    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
    });

    _player.currentIndexStream.listen((index) {
      if (index != null && index != _lastIndex) {
        _lastIndex = index;
        _updateMetadata(index);
      }
    });
  }

  // Final fix for looping animation and flickering artwork
  Future<void> _updateMetadata(int index) async {
    if (index < 0 || index >= _queueItems.length) return;

    final baseItem = _queueItems[index];
    
    // Always use cached artwork if available to avoid multiple updates
    final cachedArtUri = _artworkCache[baseItem.id];
    final targetItem = cachedArtUri != null 
        ? baseItem.copyWith(artUri: cachedArtUri) 
        : baseItem;

    // AVOID REDUNDANT UPDATES: Only push if the track ID or Artwork has actually changed
    if (_lastPushedId == targetItem.id && _lastPushedArtUri == targetItem.artUri) {
      return;
    }

    _lastPushedId = targetItem.id;
    _lastPushedArtUri = targetItem.artUri;
    mediaItem.add(targetItem);

    // If artwork wasn't in cache, fetch it now
    if (targetItem.artUri == null) {
      final newArtUri = await _resolveArtworkUri(targetItem.id);
      
      // Only push the updated item if we are still on the SAME track
      if (_lastIndex == index && newArtUri != null && _lastPushedArtUri != newArtUri) {
        _lastPushedArtUri = newArtUri;
        mediaItem.add(targetItem.copyWith(artUri: newArtUri));
      }
    }
  }

  void _prefetchQueueArtworks(List<Track> tracks, int currentIndex) async {
    // Prefetch nearby tracks first (next 5) to ensure smooth transitions
    for (var i = 1; i <= 5; i++) {
      final target = (currentIndex + i) % tracks.length;
      if (!_artworkCache.containsKey(tracks[target].id)) {
        await _resolveArtworkUri(tracks[target].id);
      }
    }
  }

  Future<AndroidEqualizerParameters> getEqualizerParams() {
    return _equalizer.parameters;
  }

  Future<void> setEqualizerEnabled(bool enabled) {
    return _equalizer.setEnabled(enabled);
  }

  Future<void> setBandGain(int bandIndex, double gain) async {
    final params = await _equalizer.parameters;
    await params.bands[bandIndex].setGain(gain);
  }
///just_audio doesn't take a Track it takes an AudioSource, built from a Uri
///and separately,audio_service wants a MediaItem like title/artist..etc to actually display in the notification
///so loading one track means building both from our one Track
}