import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/local/hiveboxes.dart';
import '../../../../data/local/track_library_service.dart';
import 'dart:io';

import '../track.dart';

final trackLibraryProvider =
StateNotifierProvider<TrackLibraryNotifier, List<Track>>((ref) {
  return TrackLibraryNotifier(TrackLibraryService());
});

class TrackLibraryNotifier extends StateNotifier<List<Track>> {
  final TrackLibraryService _service;
  Future<int> deleteTracks(Set<String> ids) async {
    var failed = 0;
    final survivors = <Track>[];

    for (final track in state) {
      if (!ids.contains(track.id)) {
        survivors.add(track);
        continue;
      }
try {
final file = File(track.uri);
if (await file.exists()) {
await file.delete();
}
// Even if it didn't exist on disk, we tell the OS to clean up the entry
await _service.scanMedia(track.uri);
} catch (e) {
if (e is PathNotFoundException || e.toString().contains('no such file')) {
//  ghost file Clean it up from the database and remove from UI.
await _service.scanMedia(track.uri);
} else {
// Real error (Permission denied, etc.)
failed++;
survivors.add(track);
}
}}

    state = survivors;
    return failed;
  }
  TrackLibraryNotifier(this._service) : super([]) {
    Future<void> toggleFavorite(String trackId) async {

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