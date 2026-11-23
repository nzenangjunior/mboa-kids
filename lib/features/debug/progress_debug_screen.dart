import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/content/alphabet_game_composer.dart';
import '../../core/content/models/alphabet_item.dart';
import '../../core/progress/item_progress_snapshot.dart';
import '../../core/progress/item_state.dart';
import '../../core/progress/pack_unlocker.dart';
import '../../core/progress/progress_repository.dart';

final _debugWorldProvider = StateProvider<String>((ref) => 'fr');

/// Temporary parent/dev screen (not part of the child-facing app) showing
/// every letter's progression state for either world, used while there
/// is no tablet to test on. Reachable at `/debug/progress`. To remove
/// once the parent space (CLAUDE.md section 9) has its own follow-up
/// screen.
class ProgressDebugScreen extends ConsumerWidget {
  const ProgressDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final world = ref.watch(_debugWorldProvider);
    final alphabetAsync = ref.watch(alphabetContentProvider(world));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug progression'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'fr', label: Text('FR')),
                ButtonSegment(value: 'en', label: Text('EN')),
              ],
              selected: {world},
              onSelectionChanged: (selection) =>
                  ref.read(_debugWorldProvider.notifier).state = selection.first,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            ref.read(simulatedDayOffsetProvider.notifier).state += 1,
        label: const Text('Simuler +1 jour'),
        icon: const Icon(Icons.fast_forward),
      ),
      body: alphabetAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(child: Text('Erreur de chargement')),
        data: (alphabet) => _ItemList(world: world, alphabet: alphabet),
      ),
    );
  }
}

class _ItemList extends ConsumerWidget {
  const _ItemList({required this.world, required this.alphabet});

  final String world;
  final AlphabetContent alphabet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(progressRepositoryProvider);
    final offsetDays = ref.watch(simulatedDayOffsetProvider);

    final orderedIds = alphabet.items.map((i) => i.id).toList();
    final startIds = startUnlockedAlphabetItemIds(world, alphabet.items);

    return FutureBuilder<_DebugData>(
      future: _loadDebugData(repository, orderedIds, startIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;

        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Horloge simulée : +$offsetDays jour(s)'),
            ),
            for (final item in alphabet.items)
              _ItemRow(
                item: item,
                snapshot: data.snapshots[item.id]!,
                unlocked: data.unlockedIds.contains(item.id),
                packNumber: packNumberFor(
                  item.id,
                  orderedItemIds: orderedIds,
                  startUnlockedItemIds: startIds,
                  packSize: alphabet.packSize,
                ),
                isStartItem: startIds.contains(item.id),
              ),
          ],
        );
      },
    );
  }

  Future<_DebugData> _loadDebugData(
    ProgressRepository repository,
    List<String> orderedIds,
    Set<String> startIds,
  ) async {
    final snapshots = <String, ItemProgressSnapshot>{};
    for (final id in orderedIds) {
      snapshots[id] = await repository.snapshotFor(id);
    }
    final states = {for (final id in orderedIds) id: snapshots[id]!.state};
    final unlockedIds = const PackUnlocker().unlockedItemIds(
      orderedItemIds: orderedIds,
      alreadyUnlockedItemIds: startIds,
      states: states,
    );
    return _DebugData(snapshots: snapshots, unlockedIds: unlockedIds);
  }
}

class _DebugData {
  _DebugData({required this.snapshots, required this.unlockedIds});

  final Map<String, ItemProgressSnapshot> snapshots;
  final Set<String> unlockedIds;
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.snapshot,
    required this.unlocked,
    required this.packNumber,
    required this.isStartItem,
  });

  final AlphabetItem item;
  final ItemProgressSnapshot snapshot;
  final bool unlocked;
  final int? packNumber;
  final bool isStartItem;

  @override
  Widget build(BuildContext context) {
    final packLabel = isStartItem ? 'départ' : (packNumber != null ? 'paquet $packNumber' : '-');
    final nextDue = nextDueLabelFor(snapshot);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: unlocked ? Colors.green.shade200 : Colors.grey.shade300,
        child: Text(item.glyph),
      ),
      title: Text('${item.id} • $packLabel • ${unlocked ? "débloquée" : "verrouillée"}'),
      subtitle: Text(
        'État : ${snapshot.state.name}'
        ' • bonnes réponses du 1er coup : ${snapshot.correctFirstTryCount}'
        ' • prochaine révision : $nextDue'
        ' • erreurs de suite : ${snapshot.consecutiveWrong}',
      ),
    );
  }
}

/// `nextDueAt` is only ever set once an item enters the spaced-repetition
/// schedule: when it first reaches `acquis` (J+1), or when a review answer
/// is wrong and it's demoted back to `aRevoir` (rescheduled at J+1 from
/// the demotion day). An `aRevoir` item that was seeded as already-known
/// (CLAUDE.md section 7: the English A-E start set) has never entered
/// that schedule, so it has no date at all — it simply hasn't had its
/// first review yet, which reads better as "now" than as a blank dash.
/// An `acquis` item with no date has instead finished every scheduled
/// review (J+60) and will never be reviewed again.
String nextDueLabelFor(ItemProgressSnapshot snapshot) {
  final dueAt = snapshot.nextDueAt;
  if (dueAt != null) return dueAt.toIso8601String().split('T').first;
  if (snapshot.state == ItemState.aRevoir) return 'maintenant';
  if (snapshot.state == ItemState.acquis) return 'terminé';
  return '-';
}
