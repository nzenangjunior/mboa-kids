import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/progress/item_progress_snapshot.dart';

/// Temporary parent/dev screen (not part of the child-facing app) showing
/// every letter's progression state, used while there is no tablet to
/// test on. Reachable at `/debug/progress`. To remove once the parent
/// space (CLAUDE.md section 9) has its own follow-up screen.
class ProgressDebugScreen extends ConsumerWidget {
  const ProgressDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final world = ref.watch(worldProvider);
    final alphabetAsync = ref.watch(alphabetContentProvider(world));

    return Scaffold(
      appBar: AppBar(title: const Text('Debug progression')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            ref.read(simulatedDayOffsetProvider.notifier).state += 1,
        label: const Text('Simuler +1 jour'),
        icon: const Icon(Icons.fast_forward),
      ),
      body: alphabetAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(child: Text('Erreur de chargement')),
        data: (alphabet) => _ItemList(itemIds: alphabet.items.map((i) => i.id).toList()),
      ),
    );
  }
}

class _ItemList extends ConsumerWidget {
  const _ItemList({required this.itemIds});

  final List<String> itemIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(progressRepositoryProvider);
    final offsetDays = ref.watch(simulatedDayOffsetProvider);

    return FutureBuilder<List<ItemProgressSnapshot>>(
      future: Future.wait(itemIds.map(repository.snapshotFor)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final snapshots = snapshot.data!;
        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Horloge simulée : +$offsetDays jour(s)'),
            ),
            for (final item in snapshots)
              ListTile(
                title: Text(item.itemId),
                subtitle: Text(
                  'État : ${item.state.name}'
                  ' • prochaine révision : ${item.nextDueAt?.toIso8601String().split('T').first ?? '-'}'
                  ' • erreurs de suite : ${item.consecutiveWrong}',
                ),
              ),
          ],
        );
      },
    );
  }
}
