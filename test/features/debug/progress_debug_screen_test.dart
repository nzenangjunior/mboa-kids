import 'package:flutter_test/flutter_test.dart';
import 'package:mboa_kids/core/progress/item_progress_snapshot.dart';
import 'package:mboa_kids/core/progress/item_state.dart';
import 'package:mboa_kids/features/debug/progress_debug_screen.dart';

void main() {
  group('nextDueLabelFor', () {
    test('shows the date when one is scheduled', () {
      final snapshot = ItemProgressSnapshot(
        itemId: 'en.letter.A',
        state: ItemState.acquis,
        nextDueAt: DateTime(2026, 2, 1),
      );

      expect(nextDueLabelFor(snapshot), '2026-02-01');
    });

    test('shows "maintenant" for a seeded aRevoir item with no schedule yet', () {
      final snapshot = ItemProgressSnapshot(
        itemId: 'en.letter.A',
        state: ItemState.aRevoir,
      );

      expect(nextDueLabelFor(snapshot), 'maintenant');
    });

    test('shows "terminé" for an acquis item that finished its reviews', () {
      final snapshot = ItemProgressSnapshot(
        itemId: 'en.letter.A',
        state: ItemState.acquis,
        reviewStage: 5,
      );

      expect(nextDueLabelFor(snapshot), 'terminé');
    });

    test('shows a dash for an item still being learned', () {
      final snapshot = ItemProgressSnapshot(
        itemId: 'en.letter.F',
        state: ItemState.aApprendre,
      );

      expect(nextDueLabelFor(snapshot), '-');
    });
  });
}
