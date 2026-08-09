import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../../data/local/hiveboxes.dart';
import '../models/playlist.dart';

final playlistProvider =
StateNotifierProvider<PlaylistNotifier, List<Playlist>>((ref) {
  return PlaylistNotifier();
});

class PlaylistNotifier extends StateNotifier<List<Playlist>> {
  static const _uuid = Uuid();

  PlaylistNotifier() : super(_loadAll());

  static List<Playlist> _loadAll() {
    return HiveBoxes.playlistsBox.values
        .map((m) => Playlist.fromMap(m))
        .toList();
  }

  Future<void> create(String name) async {
    final playlist = Playlist(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await HiveBoxes.playlistsBox.put(playlist.id, playlist.toMap());
    state = [playlist, ...state];
  }

  Future<void> delete(String playlistId) async {
    await HiveBoxes.playlistsBox.delete(playlistId);
    state = state.where((p) => p.id != playlistId).toList();
  }
}