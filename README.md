# y_player

my project for creating a music player service

## tools and packages that were used in this project 
# 1. hive: https://pub.dev/packages/hive_flutter/versions
- hive is essentially a lightweight and a fast, NoSQL key-value database written in pure Dart for Flutter applications. It structures data into "Boxes" (similar to simplified, schema-less SQL tables)
-  storing values locally on the device with near-instantaneous read/write performance. It is widely used for caching API responses, saving user preferences, and managing offline app states
- What we'll use it for specifically: one box (Hive's word for "a named collection" like a Map on disk) for tracks one for playlists. HiveBoxes.tracksBox.put(track.id, track.toMap()) writes a track to disk; HiveBoxes.tracksBox.get(id) reads it back, That's the entire storage layer for this app.

# 2. riverpod: https://pub.dev/packages/riverpod
 - is a reactive caching and compile-safe state management framework for Flutter. It acts as a complete rewrite of the popular provider package to eliminate reliance on Flutter's BuildContext. This allows developers to safely access, share, and test application state from anywhere in the Dart environment.
 - Core ConceptsProviders:
 -  Global declarations that encapsulate a piece of state and allow widgets to reactively listen to changes
 -  ProviderScope: A required root widget that stores the actual state of all providers used throughout the application
 -  WidgetRef: An object provided to modern Riverpod widgets that enables interaction with providers via ref.watch or ref.read
 -  Code Generation: The modern and highly recommended approach to defining providers using automated build scripts rather than manual boilerplate declarations.

# 3. just_audio: https://pub.dev/packages/just_audio

— the thing that actually decodes and plays audio bytes. Given a file path or URL, it does the real work: buffering, playing, pausing, seeking.

# 4. audio_service: https://pub.dev/packages/audio_service

— doesn't play anything itself. It's the bridge to the operating system: the lock-screen controls, the notification with play/pause/skip buttons, and — critically — permission to keep playing audio when the screen is off or the app is backgrounded. Without it, iOS/Android will just kill your audio the moment the app isn't in the foreground.

