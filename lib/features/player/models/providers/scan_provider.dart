import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/local/hiveboxes.dart';

enum ScanMode { full, folder }

class ScanScope {
  final ScanMode mode;
  final String? path;
  const ScanScope({this.mode = ScanMode.full, this.path});
}

const _scanModeKey = 'scan_mode';
const _scanPathKey = 'scan_path';

final scanScopeProvider = StateNotifierProvider<ScanScopeNotifier, ScanScope>((ref) {
  return ScanScopeNotifier();
});

class ScanScopeNotifier extends StateNotifier<ScanScope> {
  ScanScopeNotifier() : super(_loadSaved());

  static ScanScope _loadSaved() {
    final mode = HiveBoxes.settingsBox.get(_scanModeKey) == 'folder' ? ScanMode.folder : ScanMode.full;
    final path = HiveBoxes.settingsBox.get(_scanPathKey) as String?;
    return ScanScope(mode: mode, path: mode == ScanMode.folder ? path : null);
  }

  Future<void> setFullScan() async {
    state = const ScanScope();
    await HiveBoxes.settingsBox.put(_scanModeKey, 'full');
  }

  Future<void> setFolderScan(String path) async {
    state = ScanScope(mode: ScanMode.folder, path: path);
    await HiveBoxes.settingsBox.put(_scanModeKey, 'folder');
    await HiveBoxes.settingsBox.put(_scanPathKey, path);
  }
}