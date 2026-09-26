import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/update_service.dart';
import 'core/themes/theme.dart';
import 'core/themes/theme_provider.dart';
import 'core/themes/wallpaper.dart';

import 'package:ota_update/ota_update.dart';
import 'package:url_launcher/url_launcher.dart';
import 'features/player/models/playlist/widgets/library_screen.dart';
import 'features/player/models/playlist/widgets/playlist_screen.dart';
import 'features/player/models/playlist/widgets/discovery_screen.dart';
import 'features/player/models/widgets/mini_player.dart';
import 'features/player/models/providers/player_provider.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preset = ref.watch(themeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Y Player',
      theme: AppTheme.themeFor(preset),
      home: const _Shell(),
    );
  }
}

void _showUpdateNotification(BuildContext context, GitHubRelease release) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('New version available: ${release.version}'),
      duration: const Duration(seconds: 15),
      action: SnackBarAction(
        label: 'Update',
        onPressed: () {
          if (release.apkUrl != null) {
            _startInAppUpdate(context, release.apkUrl!);
          } else {
            launchUrl(Uri.parse(release.releaseUrl));
          }
        },
      ),
    ),
  );
}

void _startInAppUpdate(BuildContext context, String url) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => _UpdateProgressDialog(url: url),
  );
}

class _UpdateProgressDialog extends StatefulWidget {
  final String url;
  const _UpdateProgressDialog({required this.url});

  @override
  State<_UpdateProgressDialog> createState() => _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends State<_UpdateProgressDialog> {
  double _progress = 0;
  String _status = 'Downloading...';

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  void _startDownload() {
    try {
      OtaUpdate().execute(widget.url, destinationFilename: 'yplayer_update.apk').listen(
        (OtaEvent event) {
          if (!mounted) return;
          
          setState(() {
            switch (event.status) {
              case OtaStatus.DOWNLOADING:
                _progress = double.tryParse(event.value ?? '0') ?? 0;
                _status = 'Downloading: ${_progress.toInt()}%';
              case OtaStatus.INSTALLING:
                _status = 'Preparing installation...';
                Future.delayed(const Duration(seconds: 1), () {
                   if (context.mounted) Navigator.pop(context);
                });
              case OtaStatus.INTERNAL_ERROR:
              case OtaStatus.DOWNLOAD_ERROR:
                _status = 'Error: ${event.value}';
                Future.delayed(const Duration(seconds: 3), () {
                  if (context.mounted) Navigator.pop(context);
                });
              default:
                _status = 'Status: ${event.status}';
            }
          });
        },
        onError: (e) {
          if (mounted) {
            setState(() => _status = 'Error occurred: $e');
            Future.delayed(const Duration(seconds: 3), () => Navigator.pop(context));
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Could not start download: $e');
        Future.delayed(const Duration(seconds: 3), () => Navigator.pop(context));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Updating Y Player'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: _progress / 100),
          const SizedBox(height: 16),
          Text(_status),
        ],
      ),
    );
  }
}

class _Shell extends ConsumerStatefulWidget {
  const _Shell({super.key});

  @override
  ConsumerState<_Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<_Shell> {
  int _index = 0;
  final GlobalKey<LibraryScreenState> libraryKey = GlobalKey<LibraryScreenState>();

  @override
  Widget build(BuildContext context) {
    ref.listen(updateCheckProvider, (previous, next) {
      next.whenData((release) {
        if (release != null && mounted) {
          _showUpdateNotification(context, release);
        }
      });
    });

    final preset = ref.watch(themeProvider);
    final wallpaperOn = ref.watch(wallpaperEnabledProvider);
    final wallpaper = wallpaperOn ? AppWallpaper.wallpaperFor(preset) : null;
    final currentTrack = ref.watch(playerProvider.select((s) => s.currentTrack));

    final screens = [
      LibraryScreen(key: libraryKey),
      const PlaylistScreen(),
      const DiscoveryScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          if (wallpaper != null) Positioned.fill(child: wallpaper),
          screens[_index],
          if (currentTrack != null)
            Positioned(
              right: 16,
              bottom: 15,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    setState(() => _index = 0);
                    libraryKey.currentState?.scrollToCurrentTrack();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.my_location, size: 24, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),

                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.library_music_outlined), label: 'Library'),
              NavigationDestination(icon: Icon(Icons.queue_music_outlined), label: 'Playlists'),
              NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Discovery'),
            ],
          ),
        ],
      ),
    );
  }
}
