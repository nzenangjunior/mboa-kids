import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/content/models/alphabet_item.dart';
import '../../core/progress/progress_repository.dart';
import '../../shared/widgets/home_button.dart';
import '../../shared/widgets/mascot.dart';
import '../../shared/widgets/pagne_pattern.dart';

const _albumQueryTimeout = Duration(seconds: 3);

Future<Map<String, (double, double)>> _stickerPositionsOrEmpty(
  ProgressRepository repository,
) async {
  try {
    return await repository.stickerPositions().timeout(_albumQueryTimeout);
  } catch (error) {
    debugPrint('[album] stickerPositions() timed out or failed: $error');
    return const {};
  }
}

Future<void> _setAlbumLastSeenCountOrIgnore(ProgressRepository repository, int count) async {
  try {
    await repository.setAlbumLastSeenCount(count).timeout(_albumQueryTimeout);
  } catch (error) {
    debugPrint('[album] setAlbumLastSeenCount($count) timed out or failed: $error');
  }
}

/// The child's sticker collection, as the parrot's own nest (CLAUDE.md
/// section 10, Refonte visuelle: "la maison du perroquet que l'enfant
/// décore avec ses autocollants"). Both kinds stay here forever, even if
/// a letter is later demoted back to `aRevoir` (CLAUDE.md section 7:
/// nothing visible to the child is ever taken away).
class StickerAlbumScreen extends ConsumerWidget {
  const StickerAlbumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: PagnePattern(color: MboaKidsTheme.purple)),
            const Positioned.fill(child: _AlbumContent()),
            const Positioned(top: 8, left: 8, child: HomeButton()),
          ],
        ),
      ),
    );
  }
}

class _AlbumContent extends ConsumerWidget {
  const _AlbumContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(stickerCatalogListProvider);
    final frAsync = ref.watch(alphabetContentProvider('fr'));
    final enAsync = ref.watch(alphabetContentProvider('en'));

    if (!catalogAsync.hasValue || !frAsync.hasValue || !enAsync.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }

    final repository = ref.watch(progressRepositoryProvider);
    final allLetters = [...frAsync.value!.items, ...enAsync.value!.items];

    return FutureBuilder<_AlbumData>(
      future: _loadAlbumData(repository, allLetters),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        final catalog = {for (final s in catalogAsync.value!) s.id: s};

        final pieces = <_AlbumPiece>[
          for (final id in data.earnedStickerIds)
            if (catalog[id] != null) _AlbumPiece(id: 'sticker.$id', emoji: catalog[id]!.emoji, golden: false),
          for (final glyph in data.acquiredGlyphs)
            _AlbumPiece(id: 'golden.$glyph', emoji: glyph, golden: true),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final sceneSize = constraints.biggest;
            return Stack(
              children: [
                Center(
                  child: Mascot(mood: MascotMood.happy, size: sceneSize.shortestSide * 0.26),
                ),
                for (var i = 0; i < pieces.length; i++)
                  _PositionedSticker(
                    piece: pieces[i],
                    position: data.positions[pieces[i].id] ??
                        _spiralPosition(i, pieces.length),
                    sceneSize: sceneSize,
                  ),
              ],
            );
          },
        );
      },
    );
  }

  /// Normalized (0..1) position, spiraling outward from the mascot at the
  /// center — the default layout for any sticker with no stored position
  /// (see [ProgressRepository.stickerPositions]: nothing writes one yet).
  (double, double) _spiralPosition(int index, int total) {
    const goldenAngle = 2.39996; // radians; spreads items evenly round the spiral
    final angle = index * goldenAngle;
    final radius = 0.14 + 0.32 * math.sqrt((index + 1) / math.max(total, 1));
    return (0.5 + radius * math.cos(angle), 0.5 + radius * math.sin(angle));
  }

  Future<_AlbumData> _loadAlbumData(
    ProgressRepository repository,
    List<AlphabetItem> allLetters,
  ) async {
    final earnedStickerIds = await repository.earnedStickerIds();
    final acquiredGlyphs = <String>[];
    for (final item in allLetters) {
      final snapshot = await repository.snapshotFor(item.id);
      if (snapshot.firstAcquiredAt != null) acquiredGlyphs.add(item.glyph);
    }
    // New table/column this bloc (CLAUDE.md section 13: a slow or stuck
    // read must never freeze the screen) — the same timeout+fallback
    // already used for the level path's own new queries.
    final positions = await _stickerPositionsOrEmpty(repository);
    unawaited(_setAlbumLastSeenCountOrIgnore(repository, earnedStickerIds.length + acquiredGlyphs.length));
    return _AlbumData(
      earnedStickerIds: earnedStickerIds,
      acquiredGlyphs: acquiredGlyphs,
      positions: positions,
    );
  }
}

class _AlbumData {
  _AlbumData({
    required this.earnedStickerIds,
    required this.acquiredGlyphs,
    required this.positions,
  });

  final Set<String> earnedStickerIds;
  final List<String> acquiredGlyphs;
  final Map<String, (double, double)> positions;
}

class _AlbumPiece {
  const _AlbumPiece({required this.id, required this.emoji, required this.golden});

  /// Stable across reloads — matches what a future drag-and-drop would
  /// save through [ProgressRepository.setStickerPosition].
  final String id;
  final String emoji;
  final bool golden;
}

class _PositionedSticker extends StatelessWidget {
  const _PositionedSticker({
    required this.piece,
    required this.position,
    required this.sceneSize,
  });

  final _AlbumPiece piece;
  final (double, double) position;
  final Size sceneSize;

  @override
  Widget build(BuildContext context) {
    const tileSize = 72.0;
    final (dx, dy) = position;
    return Positioned(
      left: (dx.clamp(0.0, 1.0) * sceneSize.width - tileSize / 2),
      top: (dy.clamp(0.0, 1.0) * sceneSize.height - tileSize / 2),
      child: _StickerTile(emoji: piece.emoji, golden: piece.golden),
    );
  }
}

class _StickerTile extends StatelessWidget {
  const _StickerTile({required this.emoji, required this.golden});

  final String emoji;
  final bool golden;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: golden
            ? const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: golden ? null : Colors.white,
        border: golden ? null : Border.all(color: MboaKidsTheme.lightPurple, width: 2),
      ),
      child: Text(
        emoji,
        style: TextStyle(
          fontSize: golden ? 32 : 30,
          fontWeight: golden ? FontWeight.bold : FontWeight.normal,
          color: golden ? Colors.white : null,
        ),
      ),
    );
  }
}
