import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GitHubRelease {
  final String version;
  final String releaseUrl;
  final String? apkUrl;
  final String description;

  GitHubRelease({
    required this.version,
    required this.releaseUrl,
    this.apkUrl,
    required this.description,
  });

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    final assets = json['assets'] as List? ?? [];
    String? apkUrl;
    
    try {
      final apkAsset = assets.firstWhere(
        (asset) => asset['name'].toString().toLowerCase().endsWith('.apk'),
        orElse: () => null,
      );
      if (apkAsset != null) {
        apkUrl = apkAsset['browser_download_url'];
      }
    } catch (_) {}

    return GitHubRelease(
      version: json['tag_name'] ?? '',
      releaseUrl: json['html_url'] ?? '',
      apkUrl: apkUrl,
      description: json['body'] ?? '',
    );
  }
}

class UpdateService {
  static const String _repoOwner = '6Guts9';
  static const String _repoName = 'Y-player';
  static const String _baseUrl = 'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  Future<GitHubRelease?> checkForUpdate() async {
    try {
      print('UPDATE SERVICE: Requesting $_baseUrl');
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'Y-Player-App',
        },
      ).timeout(const Duration(seconds: 10));

      print('UPDATE SERVICE: Status Code ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestRelease = GitHubRelease.fromJson(data);
        
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;
        
        print('UPDATE CHECK: Current=$currentVersion, Latest=${latestRelease.version}');

        if (_isNewerVersion(latestRelease.version, currentVersion)) {
          print('UPDATE FOUND!');
          return latestRelease;
        } else {
          print('NO UPDATE NEEDED');
        }
      } else {
        print('UPDATE SERVICE ERROR: ${response.body}');
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }
    return null;
  }

  bool _isNewerVersion(String latest, String current) {
    // Basic version comparison (removes 'v' prefix if present)
    final latestClean = latest.replaceAll('v', '').split('+')[0];
    final currentClean = current.replaceAll('v', '').split('+')[0];

    final latestParts = latestClean.split('.').map(int.tryParse).toList();
    final currentParts = currentClean.split('.').map(int.tryParse).toList();

    for (var i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length) return true;
      final latestPart = latestParts[i] ?? 0;
      final currentPart = currentParts[i] ?? 0;
      if (latestPart > currentPart) return true;
      if (latestPart < currentPart) return false;
    }
    return false;
  }
}

final updateServiceProvider = Provider((ref) => UpdateService());

final updateCheckProvider = FutureProvider<GitHubRelease?>((ref) async {
  final service = ref.watch(updateServiceProvider);
  return service.checkForUpdate();
});
