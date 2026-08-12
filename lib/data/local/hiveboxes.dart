
import 'package:hive_flutter/hive_flutter.dart';

class HiveBoxes {
  HiveBoxes._();
  static const String tracks ='track_box';
  static const String playlists = 'playlist_box';
  static late Box<Map> tracksBox;
  static late Box<Map> playlistsBox;
  static const String settings = 'settings_box';
  static late Box settingsBox;
///late is a kind of promise to the compiler that the given value is empty but it will be set
  ///before anything tries to read it
  ///we do this because hiveBox is async and we don't have the box yet so we wait until it finishes
  static bool _initialized= false;
  static Future<void> init () async {


    if(_initialized) return;
    await Hive.initFlutter();

    tracksBox = await Hive.openBox<Map>(tracks);
    playlistsBox = await Hive.openBox<Map>(playlists);
    settingsBox = await Hive.openBox(settings);

    _initialized = true;
  }
}
/// we are using Hive which is a lightweight database for Flutter that doesn’t require any complex setup or SQL queries
/// It’s a NoSQL solution that allows you to store and retrieve data in a simple way
/// more details on README.md