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
import '../../core/rewards/intensity_level.dart';

final _debugWorldProvider = StateProvider<String>((ref) => 'fr');

/// Bumped after [ProgressRepository.resetAll] so [_ItemList] (which has no
/// other reason to rebuild on a reset) reloads its data.
final _resetTickProvider = StateProvider<int>((ref) => 0);

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
    final intensityAsync = ref.watch(intensityProvider);

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
          if (intensityAsync.hasValue)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SegmentedButton<IntensityLevel>(
                segments: const [
                  ButtonSegment(value: IntensityLevel.calme, label: Text('Calme')),
                  ButtonSegment(value: IntensityLevel.normal, label: Text('Normal')),
                  ButtonSegment(value: IntensityLevel.fete, label: Text('Fête')),
                ],
                selected: {intensityAsync.value!},
                onSelectionChanged: (selection) async {
                  await ref
                      .read(progressRepositoryProvider)
                      .setIntensity(selection.first);
                  ref.invalidate(intensityProvider);
                },
              ),
            ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Réinitialiser la base',
            onPressed: () => _confirmAndResetDatabase(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            ref.read(simulatedDayOffsetProvider.notifier).state += 1,
        label: const Text('Simuler +1 jour'),
        icon: const Icon(Icons.fast_forward),
      ),
      body: Column(
        children: [
          const _VoiceAvailabilityBanner(),
          Expanded(
            child: alphabetAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  const Center(child: Text('Erreur de chargement')),
              // Keyed on `world`: without this, switching FR/EN keeps the
              // same `_ItemList` element, and its FutureBuilder keeps
              // showing the previous world's (now stale) snapshot data —
              // built from the old `orderedIds` — while `alphabet.items`
              // has already moved to the new world, until the new future
              // resolves. `data.snapshots[id]!` then finds no entry for an
              // id from the new world and throws. The key forces a fresh
              // `_ItemList` (and FutureBuilder) per world instead, with no
              // stale data to show in between.
              data: (alphabet) =>
                  _ItemList(key: ValueKey(world), world: world, alphabet: alphabet),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wipes every table after an explicit confirmation (CLAUDE.md section
/// 7bis) — the one way to recover a corrupted database (dev or real)
/// without clearing app/browser storage by hand. Already behind the
/// parent gate's calculation, since this whole screen only opens after
/// it (CLAUDE.md section 9).
Future<void> _confirmAndResetDatabase(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Réinitialiser la base ?'),
      content: const Text(
        'Toute la progression, les étoiles, les autocollants, le monde choisi et '
        'les réglages seront effacés. Action irréversible.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Réinitialiser'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  await ref.read(progressRepositoryProvider).resetAll();
  ref.invalidate(intensityProvider);
  ref.invalidate(voiceAvailabilityProvider);
  ref.invalidate(albumHasNewStickerProvider);
  ref.read(_resetTickProvider.notifier).state++;

  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Base réinitialisée.')));
  }
}

/// Shows whether the exact voice each world's TTS fallback needs (en-GB,
/// fr-FR) is installed on this device/browser — see [voiceAvailabilityProvider].
class _VoiceAvailabilityBanner extends ConsumerWidget {
  const _VoiceAvailabilityBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voicesAsync = ref.watch(voiceAvailabilityProvider);

    return voicesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: LinearProgressIndicator(),
      ),
      error: (error, stackTrace) => const Padding(
        padding: EdgeInsets.all(8),
        child: Text('Voix : vérification impossible'),
      ),
      data: (voices) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Wrap(
          spacing: 16,
          children: [
            _VoiceChip(label: 'Voix EN', target: 'en-GB', resolved: voices['en-GB']),
            _VoiceChip(label: 'Voix FR', target: 'fr-FR', resolved: voices['fr-FR']),
          ],
        ),
      ),
    );
  }
}

/// Shows the locale actually resolved for [target] (CLAUDE.md section 6):
/// the exact voice, a same-language fallback accent, or none at all —
/// never just a yes/no, since a silent fallback and an accented one look
/// identical from a plain boolean.
class _VoiceChip extends StatelessWidget {
  const _VoiceChip({required this.label, required this.target, required this.resolved});

  final String label;
  final String target;
  final String? resolved;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    final String detail;
    if (resolved == target) {
      icon = Icons.check_circle;
      color = Colors.green.shade700;
      detail = 'voix exacte ($target)';
    } else if (resolved != null) {
      icon = Icons.warning_amber;
      color = Colors.orange.shade700;
      detail = 'repli sur "$resolved" ($target absente)';
    } else {
      icon = Icons.error;
      color = Colors.red.shade700;
      detail = 'aucune voix ($target absente)';
    }
    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text('$label : $detail'),
    );
  }
}

class _ItemList extends ConsumerWidget {
  const _ItemList({super.key, required this.world, required this.alphabet});

  final String world;
  final AlphabetContent alphabet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(progressRepositoryProvider);
    final offsetDays = ref.watch(simulatedDayOffsetProvider);
    ref.watch(_resetTickProvider);

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
