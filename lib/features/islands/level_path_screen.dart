import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/audio/audio_service.dart';
import '../../core/progress/level_path.dart';
import '../../core/tracing/tracing_queue.dart';
import '../../shared/widgets/home_button.dart';
import '../../shared/widgets/mascot.dart';
import '../../shared/widgets/pagne_pattern.dart';

enum IslandType { alphabet, tracing }

/// One island's path of levels (CLAUDE.md section 10): 1 level = 1 pack,
/// shown as a circle — locked, open (pulsing, the mascot perched on it)
/// or done (with its best stars) — along a winding, dotted path. No text
/// for the child: the glyphs shown inside a level ARE the content being
/// taught (same as the alphabet game's own choice cards), not an
/// instruction to read.
class LevelPathScreen extends ConsumerStatefulWidget {
  const LevelPathScreen({super.key, required this.islandType});

  final IslandType islandType;

  @override
  ConsumerState<LevelPathScreen> createState() => _LevelPathScreenState();
}

class _LevelPathScreenState extends ConsumerState<LevelPathScreen> {
  AudioService? _audio;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _playPrompt());
  }

  @override
  void dispose() {
    unawaited(_audio?.stop());
    super.dispose();
  }

  Future<AudioService> _audioFor(String world) async {
    final audio = await ref.read(audioServiceProvider(world).future);
    _audio = audio;
    return audio;
  }

  Future<void> _playPrompt() async {
    try {
      final world = ref.read(worldProvider);
      final audio = await _audioFor(world);
      await audio.playPrompt('choose_level');
    } catch (_) {}
  }

  Future<void> _onLockedTap() async {
    try {
      final world = ref.read(worldProvider);
      final audio = await _audioFor(world);
      await audio.playPrompt('island_locked');
    } catch (_) {}
  }

  void _openAlphabetLevel(int packNumber) {
    context.go('/game', extra: packNumber);
  }

  Future<void> _openTracingLevel(TracingLevelView level) async {
    final world = ref.read(worldProvider);
    final alphabet = await ref.read(alphabetContentProvider(world).future);
    final tracingContent = await ref.read(tracingContentProvider.future);
    bool hasTracingData(String glyph) => tracingContent[glyph] != null;

    final List<TracingQueueItem> items;
    final String levelId;
    if (level.isNameLevel) {
      final firstName = ref.read(childFirstNameProvider);
      items = buildTracingQueueForName(
        alphabetItems: alphabet.items,
        firstName: firstName,
        hasTracingData: hasTracingData,
      );
      levelId = '$world.tracing.name';
    } else {
      final packItems = alphabet.items
          .where((item) => level.glyphs.contains(item.glyph))
          .toList();
      items = buildTracingQueueForGlyphs(packItems: packItems, hasTracingData: hasTracingData);
      levelId = '$world.tracing.pack${level.packNumber}';
    }

    if (!mounted) return;
    context.go('/tracing', extra: TracingRouteArgs(explicitItems: items, levelId: levelId));
  }

  @override
  Widget build(BuildContext context) {
    final world = ref.watch(worldProvider);
    final accent = widget.islandType == IslandType.alphabet
        ? MboaKidsTheme.pink
        : MboaKidsTheme.purple;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: PagnePattern(color: accent)),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Mascot(onTap: _playPrompt),
                Expanded(
                  child: widget.islandType == IslandType.alphabet
                      ? _buildAlphabetPath(world)
                      : _buildTracingPath(world),
                ),
                const Align(alignment: Alignment.bottomLeft, child: HomeButton()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlphabetPath(String world) {
    final levelsAsync = ref.watch(alphabetLevelsProvider(world));
    return levelsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const Center(child: Icon(Icons.error, size: 48)),
      data: (levels) => _PathList(
        itemCount: levels.length,
        itemBuilder: (index) {
          final level = levels[index];
          return _LevelCircle(
            state: level.state,
            bestStars: level.bestStars,
            icon: null,
            glyphs: level.glyphs,
            onTap: level.state == LevelState.locked
                ? _onLockedTap
                : () => _openAlphabetLevel(level.packNumber),
          );
        },
      ),
    );
  }

  Widget _buildTracingPath(String world) {
    final levelsAsync = ref.watch(tracingLevelsProvider(world));
    return levelsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const Center(child: Icon(Icons.error, size: 48)),
      data: (levels) => _PathList(
        itemCount: levels.length,
        itemBuilder: (index) {
          final level = levels[index];
          return _LevelCircle(
            state: level.state,
            bestStars: level.bestStars,
            icon: level.isNameLevel ? Icons.face : null,
            glyphs: level.isNameLevel ? const [] : level.glyphs,
            onTap: level.state == LevelState.locked
                ? _onLockedTap
                : () => _openTracingLevel(level),
          );
        },
      ),
    );
  }
}

const _circleSize = 96.0;
const _itemWidth = 150.0;
const _altOffset = 36.0;
const _topPadding = 56.0;
const _sidePadding = 32.0;

/// A horizontally-scrolling, winding dotted path (CLAUDE.md section 10,
/// Refonte visuelle: "un vrai chemin sinueux en pointillés") connecting
/// each level in order, alternating a little up and down.
class _PathList extends StatelessWidget {
  const _PathList({required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final Widget Function(int index) itemBuilder;

  Offset _circleCenter(int index) {
    final x = _sidePadding + index * _itemWidth + _circleSize / 2;
    final y = _topPadding + (index.isEven ? 0.0 : _altOffset) + _circleSize / 2;
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) {
      return const Center(child: Icon(Icons.hourglass_empty, size: 48));
    }

    final centers = [for (var i = 0; i < itemCount; i++) _circleCenter(i)];
    final width = _sidePadding * 2 + itemCount * _itemWidth;
    const height = _topPadding + _altOffset + _circleSize + 56;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _DottedPathPainter(points: centers)),
            ),
            for (var i = 0; i < itemCount; i++)
              Positioned(
                left: centers[i].dx - _circleSize / 2,
                top: centers[i].dy - _circleSize / 2,
                width: _circleSize,
                child: itemBuilder(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _DottedPathPainter extends CustomPainter {
  _DottedPathPainter({required this.points});

  final List<Offset> points;

  static const _dashLength = 10.0;
  static const _gapLength = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MboaKidsTheme.purple.withValues(alpha: 0.45)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final total = (b - a).distance;
      if (total == 0) continue;
      final direction = (b - a) / total;
      var covered = 0.0;
      while (covered < total) {
        final segmentEnd = math.min(covered + _dashLength, total);
        canvas.drawLine(a + direction * covered, a + direction * segmentEnd, paint);
        covered += _dashLength + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedPathPainter oldDelegate) =>
      oldDelegate.points != points;
}

class _LevelCircle extends StatefulWidget {
  const _LevelCircle({
    required this.state,
    required this.bestStars,
    required this.glyphs,
    required this.icon,
    required this.onTap,
  });

  final LevelState state;
  final int bestStars;
  final List<String> glyphs;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  State<_LevelCircle> createState() => _LevelCircleState();
}

class _LevelCircleState extends State<_LevelCircle> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.state == LevelState.open) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_LevelCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == LevelState.open && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.state != LevelState.open) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.state == LevelState.locked;
    final color = locked
        ? Colors.grey.shade400
        : (widget.state == LevelState.done ? Colors.green.shade400 : MboaKidsTheme.pink);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _circleSize,
          height: _circleSize + 40,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              if (widget.state == LevelState.open)
                const Positioned(
                  top: 0,
                  child: Mascot(mood: MascotMood.idle, size: 48),
                ),
              Positioned(
                bottom: 0,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = widget.state == LevelState.open
                        ? 1 + _pulseController.value * 0.08
                        : 1.0;
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Material(
                    color: color,
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: InkWell(
                      onTap: widget.onTap,
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: _circleSize,
                        height: _circleSize,
                        child: Center(
                          child: locked
                              ? const Icon(Icons.lock, size: 36, color: Colors.white)
                              : widget.icon != null
                              ? Icon(widget.icon, size: 40, color: Colors.white)
                              : Text(
                                  widget.glyphs.join(' '),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (widget.state == LevelState.done)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return Icon(
                i < widget.bestStars ? Icons.star : Icons.star_border,
                size: 20,
                color: MboaKidsTheme.pink,
              );
            }),
          ),
      ],
    );
  }
}
