import 'package:on_audio_query/on_audio_query.dart';

class TrackLibraryService {
  final OnAudioQuery _query = OnAudioQuery();

  Future<bool> requestPermission() {
    return _query.checkAndRequest();
  }

  Future<void> scanMedia(String path) => _query.scanMedia(path);

  Future<List<SongModel>> scanLibrary({String? path}) {
    return _query.querySongs(path: path);
  }
}
