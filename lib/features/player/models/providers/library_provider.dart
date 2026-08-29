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
    Future<void> toggleFavorite(String trackId) async {
      final index = state.indexWhere((t) => t.id == trackId);
      if (index == -1) return;

      final track = state[index];
      final newFavorite = !track.isFavorite;


      final existing = HiveBoxes.tracksBox.get(trackId);
      final playCount = existing?['playCount'] as int? ?? 0;
      await HiveBoxes.tracksBox.put(trackId, {'playCount': playCount, 'isFavorite': newFavorite});

      final updated = track.copyWith(isFavorite: newFavorite);
      state = [
        for (final t in state) if (t.id == trackId) updated else t,
      ];
    }
    _scan();
  }

  Future<void> _scan() async {
    final granted = await _service.requestPermission();
    if (!granted) return;

    final songs = (await _service.scanLibrary())
        .where((song) => song.isMusic ?? false)
        .toList();
    state = songs.map((song) {
      final extras = HiveBoxes.tracksBox.get(song.id.toString());
      return Track.fromLibrary(
        song,
        playCount: extras?['playCount'] as int? ?? 0,
        isFavorite: extras?['isFavorite'] as bool? ?? false,
      );
    }).toList();
  }
  Future<void> toggleFavorite(String trackId) async {
    final index = state.indexWhere((t) => t.id == trackId);
    if (index == -1) return;

    final track = state[index];
    final newFavorite = !track.isFavorite;

    final existing = HiveBoxes.tracksBox.get(trackId);
    final playCount = existing?['playCount'] as int? ?? 0;
    await HiveBoxes.tracksBox.put(trackId, {'playCount': playCount, 'isFavorite': newFavorite});

    final updated = track.copyWith(isFavorite: newFavorite);
    state = [
      for (final t in state) if (t.id == trackId) updated else t,
    ];
  }

  Future<void> refresh() => _scan();
}