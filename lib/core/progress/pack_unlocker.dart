import 'item_state.dart';

/// Decides which items are unlocked, by packs of [packSize]
/// (CLAUDE.md section 7: "Nouveaux items par paquets de 3. Paquet suivant
/// débloqué quand le paquet courant est acquis.").
///
/// [alreadyUnlockedItemIds] covers items granted outside the pack sequence,
/// such as the English start set (A-E, 1-10) which begins directly in
/// `aRevoir`: those are not grouped into packs at all, only the remaining
/// "new" items are.
class PackUnlocker {
  const PackUnlocker({this.packSize = 3});

  final int packSize;

  Set<String> unlockedItemIds({
    required List<String> orderedItemIds,
    required Set<String> alreadyUnlockedItemIds,
    required Map<String, ItemState> states,
  }) {
    final newItemIds = orderedItemIds
        .where((id) => !alreadyUnlockedItemIds.contains(id))
        .toList();

    final unlocked = {...alreadyUnlockedItemIds};
    List<String>? previousPack;

    for (var i = 0; i < newItemIds.length; i += packSize) {
      final pack = newItemIds.skip(i).take(packSize).toList();
      final isFirstPack = previousPack == null;

      if (!isFirstPack && !_isPackAcquis(previousPack, states)) {
        break;
      }

      unlocked.addAll(pack);
      previousPack = pack;
    }

    return unlocked;
  }

  bool _isPackAcquis(List<String> packItemIds, Map<String, ItemState> states) {
    return packItemIds.isNotEmpty &&
        packItemIds.every((id) => states[id] == ItemState.acquis);
  }
}
