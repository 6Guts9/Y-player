import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:y_player/features/player/models/providers/scan_provider.dart';

import '../../../../data/local/hiveboxes.dart';
import '../../../../data/local/track_library_service.dart';
import 'dart:io';

import '../track.dart';

final trackLibraryProvider =
StateNotifierProvider<TrackLibraryNotifier, List<Track>>((ref) {
  return TrackLibraryNotifier(TrackLibraryService(), ref);
});

class TrackLibraryNotifier extends StateNotifier<List<Track>> {
  final TrackLibraryService _service;
  final Ref _ref;

  TrackLibraryNotifier(this._service, this._ref) : super([]) {
    _scan();
  }

  Future<void> _scan() async {
    final granted = await _service.requestPermission();
    if (!granted) return;

    final scope = _ref.read(scanScopeProvider);
    final songs = (await _service.scanLibrary(
      path: scope.mode == ScanMode.folder ? scope.path : null,
    )).where((song) => song.isMusic ?? false).toList();

    // ...rest of _scan unchanged (the ghost-file check, extras merge, etc.)

    final validTracks = <Track>[];
    for (final song in songs) {
      // WORKAROUND: Double check if file actually exists to avoid ghost entries from MediaStore
      if (await File(song.data).exists()) {
        final extras = HiveBoxes.tracksBox.get(song.id.toString());
        validTracks.add(Track.fromLibrary(
          song,
          playCount: extras?['playCount'] as int? ?? 0,
          isFavorite: extras?['isFavorite'] as bool? ?? false,
        ));
      }
    }
    state = validTracks;
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

  Future<void> scanAndRefresh(String path) async {
    await _service.scanMedia(path);
    await _scan();
  }

  Future<int> deleteTracks(Set<String> ids) async {
    try {
      // PhotoManager triggers the native system "Allow delete?" dialog on Android 11+
      // It returns the list of IDs that the user actually allowed to be deleted.
      final resultIds = await PhotoManager.editor.deleteWithIds(ids.toList());
      
      final deletedSet = resultIds.toSet();
      final failedCount = ids.length - deletedSet.length;
      
      for (final id in deletedSet) {
        await HiveBoxes.tracksBox.delete(id);
      }
      
      // Filter out the tracks that were successfully deleted from our state
      state = state.where((t) => !deletedSet.contains(t.id)).toList();
      
      return failedCount;
    } catch (e) {
      print('SYSTEM DELETION FAILED: $e');
      // If system dialog failed or was cancelled, we fallback to manual check for ghost files
      var failed = 0;
      final survivors = <Track>[];

      for (final track in state) {
        if (!ids.contains(track.id)) {
          survivors.add(track);
          continue;
        }
        try {
          if (!(await File(track.uri).exists())) {
            await HiveBoxes.tracksBox.delete(track.id);
            await _service.scanMedia(track.uri);
          } else {
            failed++;
            survivors.add(track);
          }
        } catch (_) {
          failed++;
          survivors.add(track);
        }
      }
      state = survivors;
      return failed;
    }
  }
}
