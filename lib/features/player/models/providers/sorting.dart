import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/local/hiveboxes.dart';

enum LibrarySortOption { dateAddedDesc, dateAddedAsc, titleAsc, titleDesc, durationAsc, durationDesc }

const _sortOptionKey = 'library_sort_option';

final librarySortProvider =
StateNotifierProvider<LibrarySortNotifier, LibrarySortOption>((ref) {
  return LibrarySortNotifier();
});

class LibrarySortNotifier extends StateNotifier<LibrarySortOption> {
  LibrarySortNotifier() : super(_loadSaved());

  static LibrarySortOption _loadSaved() {
    final saved = HiveBoxes.settingsBox.get(_sortOptionKey) as String?;
    if (saved == null) return LibrarySortOption.dateAddedDesc;
    return LibrarySortOption.values.firstWhere(
          (o) => o.name == saved,
      orElse: () => LibrarySortOption.dateAddedDesc,
    );
  }

  Future<void> setOption(LibrarySortOption option) async {
    state = option;
    await HiveBoxes.settingsBox.put(_sortOptionKey, option.name);
  }
}