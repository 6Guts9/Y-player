import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/audio_source_handler.dart';
import 'data/local/hiveboxes.dart';
import 'features/player/models/providers/player_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveBoxes.init();

  final audioHandler = await AudioService.init(
    builder: () => AudioSourceHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.y_player.audio',
      androidNotificationChannelName: 'Playback',
      androidNotificationOngoing: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const MyApp(),
    ),
  );
}