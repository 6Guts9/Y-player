import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/local/hiveboxes.dart';
import '../../../../data/local/track_library_service.dart';

import '../track.dart';

final trackLibraryProvider =
StateNotifierProvider<TrackLibraryNotifier, List<Track>>((ref) {
  return TrackLibraryNotifier(TrackLibraryService());
});

class TrackLibraryNotifier extends StateNotifier<List<Track>> {
  final TrackLibraryService _service;

  TrackLibraryNotifier(this._service) : super([]) {
    _scan();
  }

  Future<void> _scan() async {
    final granted = await _service.requestPermission();
    if (!granted) return;

    final songs = await _service.scanLibrary();
    state = songs.map((song) {
      final extras = HiveBoxes.tracksBox.get(song.id.toString());
      return Track.fromLibrary(
        song,
        playCount: extras?['playCount'] as int? ?? 0,
        isFavorite: extras?['isFavorite'] as bool? ?? false,
      );
    }).toList();
  }

  Future<void> refresh() => _scan();
}