import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/content/models/alphabet_item.dart';
import '../../core/progress/progress_repository.dart';

/// The child's sticker collection (CLAUDE.md section 8): no text, just
/// the stickers earned so far. Both kinds stay here forever, even if a
/// letter is later demoted back to `aRevoir` (CLAUDE.md section 7:
/// nothing visible to the child is ever taken away).
class StickerAlbumScreen extends ConsumerWidget {
  const StickerAlbumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(child: _AlbumContent()),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                iconSize: 40,
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.arrow_back, color: MboaKidsTheme.purple),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(stickerCatalogListProvider);
    final frAsync = ref.watch(alphabetContentProvider('fr'));
    final enAsync = ref.watch(alphabetContentProvider('en'));

    if (!catalogAsync.hasValue || !frAsync.hasValue || !enAsync.hasValue) {
      return const CircularProgressIndicator();
    }

    final repository = ref.watch(progressRepositoryProvider);
    final allLetters = [...frAsync.value!.items, ...enAsync.value!.items];

    return FutureBuilder<_AlbumData>(
      future: _loadAlbumData(repository, allLetters),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final data = snapshot.data!;
        final catalog = {for (final s in catalogAsync.value!) s.id: s};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              for (final id in data.earnedStickerIds)
                if (catalog[id] != null) _StickerTile(emoji: catalog[id]!.emoji, golden: false),
              for (final glyph in data.acquiredGlyphs)
                _StickerTile(emoji: glyph, golden: true),
            ],
          ),
        );
      },
    );
  }

  Future<_AlbumData> _loadAlbumData(
    ProgressRepository repository,
    List<AlphabetItem> allLetters,
  ) async {
    final earnedStickerIds = await repository.earnedStickerIds();
    final acquiredGlyphs = <String>[];
    for (final item in allLetters) {
      final snapshot = await repository.snapshotFor(item.id);
      if (snapshot.firstAcquiredAt != null) {
        acquiredGlyphs.add(item.glyph);
      }
    }
    return _AlbumData(earnedStickerIds: earnedStickerIds, acquiredGlyphs: acquiredGlyphs);
  }
}

class _AlbumData {
  _AlbumData({required this.earnedStickerIds, required this.acquiredGlyphs});

  final Set<String> earnedStickerIds;
  final List<String> acquiredGlyphs;
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
