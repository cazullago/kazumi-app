import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../avatar.dart';
import '../models.dart';
import '../theme.dart';

/// Cozy pixel-lofi bedroom — full immersive stage, not a small box.
///
/// The room art (assets/rooms/room_lofi.jpg) is full-bleed, and the
/// creator is a large [LiveAnimeRig] half-body panel centred in it, with
/// a soft glow behind her and drifting star particles. No circle crop.
class PixelBedroom extends StatelessWidget {
  final AvatarStyle style;
  final double avatarSize;
  final double tilt;
  final bool pendant;
  final ValueListenable<double>? mouthLevel;
  final String? portraitAsset;
  final LiveExpression expression;
  const PixelBedroom({
    super.key,
    required this.style,
    this.avatarSize = 170,
    this.tilt = 0.15,
    this.pendant = false,
    this.mouthLevel,
    this.portraitAsset,
    this.expression = LiveExpression.normal,
  });
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Rig is 2:3 — size it to the stage so it never crops or overflows.
          final rigHeight = math.min(constraints.maxHeight * 0.94, constraints.maxWidth * 1.32);
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/rooms/room_lofi.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(color: const Color(0xFFE9DCFF)),
              ),
              // Warm vignette so the avatar reads against the room.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x1A7C6BD9), Color(0x00000000), Color(0x00000000), Color(0x593D3356)],
                    stops: [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),
              const StarParticles(count: 20),
              // Soft glow behind the avatar.
              Center(
                child: Container(
                  width: rigHeight * 0.85,
                  height: rigHeight * 0.85,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x66FFB7D5), Color(0x33C9B8F0), Color(0x00000000)],
                      stops: [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LiveAnimeRig(
                    style: style,
                    portraitAsset: portraitAsset,
                    height: rigHeight,
                    tilt: tilt,
                    mouthLevel: mouthLevel,
                    expression: expression,
                  ),
                ),
              ),
              const Positioned(
                right: 12,
                bottom: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0x993D3356), borderRadius: BorderRadius.all(Radius.circular(10))),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text('♪ lofi beats ♪', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Falling star for the Gaming mini-game.
class _FallingStar {
  final int id;
  final double x; // 0..1 across the stage
  double y; // 0..1 down the stage
  final double speed; // per 40ms tick
  final double size;
  final bool gold;
  _FallingStar({required this.id, required this.x, required this.y, required this.speed, required this.size, required this.gold});
}

/// Neon night-city backdrop with a twinkling sky and lit windows.
class _NightCityPainter extends CustomPainter {
  final double t;
  const _NightCityPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    // Sky gradient: deep indigo to violet to pink horizon.
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1B1440), Color(0xFF3B2366), Color(0xFF7C4A8A), Color(0xFFE86A9A)],
        stops: [0.0, 0.45, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), sky);
    // Twinkling stars.
    final rnd = math.Random(11);
    for (var i = 0; i < 34; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height * 0.45;
      final a = 0.25 + 0.75 * (0.5 + 0.5 * math.sin(2 * math.pi * (t + i * 0.13)));
      final p = Paint()..color = Colors.white.withValues(alpha: a);
      canvas.drawCircle(Offset(x, y), 1 + rnd.nextDouble() * 1.6, p);
    }
    // Moon with glow.
    final moon = Offset(size.width * 0.82, size.height * 0.14);
    canvas.drawCircle(moon, size.width * 0.075, Paint()..color = const Color(0x33FFD166));
    canvas.drawCircle(moon, size.width * 0.05, Paint()..color = const Color(0xFFFFF3C4));
    // Skyline silhouettes with lit windows.
    final rndB = math.Random(23);
    var x = -4.0;
    var b = 0;
    while (x < size.width) {
      final w = size.width * (0.07 + rndB.nextDouble() * 0.06);
      final h = size.height * (0.16 + rndB.nextDouble() * 0.22);
      final top = size.height - h;
      canvas.drawRect(
        Rect.fromLTWH(x, top, w, h),
        Paint()..color = Color.lerp(const Color(0xFF241A4D), const Color(0xFF160F33), b % 2 * 0.5)!,
      );
      // Lit windows.
      for (var row = 0; row < 4; row++) {
        for (var col = 0; col < 3; col++) {
          if ((b + row + col) % 3 == 0) {
            final wa = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(2 * math.pi * (t * 0.7 + b * 0.3 + row * 0.2 + col * 0.11)));
            canvas.drawRect(
              Rect.fromLTWH(x + 5 + col * (w - 10) / 3, top + 8 + row * (h - 16) / 4, 5, 7),
              Paint()..color = const Color(0xFFFFD166).withValues(alpha: wa),
            );
          }
        }
      }
      x += w + 3;
      b++;
    }
    // Neon horizon glow.
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.86, size.width, size.height * 0.14),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00E86A9A), Color(0x66E86A9A)],
        ).createShader(Rect.fromLTWH(0, size.height * 0.86, size.width, size.height * 0.14)),
    );
  }

  @override
  bool shouldRepaint(covariant _NightCityPainter old) => t != old.t;
}

/// Gaming stage: a real animated scene + a playable mini-game.
///
/// "Star Catch" — stars fall from the night-city sky, tap one to collect
/// it (+10). The score is local only and never shared. The anime avatar
/// stays as a large framed overlay in the corner (not a tiny circle).
/// There is no gameplay placeholder text anywhere on this stage.
class GamingStage extends StatefulWidget {
  final AvatarStyle style;
  final double avatarSize;
  final double overlayX; // -1 left .. 1 right for the overlay position
  final ValueListenable<double>? mouthLevel;
  final String? portraitAsset;
  final LiveExpression expression;
  const GamingStage({
    super.key,
    required this.style,
    this.avatarSize = 88,
    this.overlayX = 1,
    this.mouthLevel,
    this.portraitAsset,
    this.expression = LiveExpression.normal,
  });
  @override
  State<GamingStage> createState() => _GamingStageState();
}

class _GamingStageState extends State<GamingStage> with SingleTickerProviderStateMixin {
  late final AnimationController _city;
  Timer? _tick;
  Timer? _spawn;
  final List<_FallingStar> _stars = [];
  final math.Random _rnd = math.Random();
  int _nextId = 0;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _city = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _spawnStar();
    _tick = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!mounted) return;
      setState(() {
        for (final s in _stars) {
          s.y += s.speed;
        }
        _stars.removeWhere((s) => s.y > 1.08);
      });
    });
    _spawn = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted) return;
      if (_stars.length < 6) {
        setState(_spawnStar);
      }
    });
  }

  void _spawnStar() {
    _stars.add(_FallingStar(
      id: _nextId++,
      x: 0.06 + _rnd.nextDouble() * 0.82,
      y: -0.06,
      speed: 0.006 + _rnd.nextDouble() * 0.006,
      size: 26 + _rnd.nextDouble() * 14,
      gold: _rnd.nextBool(),
    ));
  }

  @override
  void dispose() {
    _tick?.cancel();
    _spawn?.cancel();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stageH = constraints.maxHeight;
          // Overlay height follows the Studio slider (avatarSize 56..140).
          final overlayH = (widget.avatarSize * 2.0).clamp(120.0, stageH * 0.62);
          return Stack(
            fit: StackFit.expand,
            children: [
              AnimatedBuilder(
                animation: _city,
                builder: (context, _) => CustomPaint(
                  painter: _NightCityPainter(_city.value),
                  size: Size.infinite,
                ),
              ),
              // Falling stars — tap to collect.
              ..._stars.map((s) {
                return Positioned(
                  left: s.x * constraints.maxWidth - s.size / 2,
                  top: s.y * stageH - s.size / 2,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _score += 10;
                      _stars.remove(s);
                    }),
                    child: Container(
                      width: s.size + 16,
                      height: s.size + 16,
                      alignment: Alignment.center,
                      color: Colors.transparent,
                      child: Text(
                        '⭐',
                        style: TextStyle(
                          fontSize: s.size,
                          shadows: [
                            Shadow(color: (s.gold ? const Color(0xFFFFD166) : const Color(0xFFFFB7D5)).withValues(alpha: 0.9), blurRadius: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              // Score + hint bar.
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: const BoxDecoration(color: Color(0xCC1B1440), borderRadius: BorderRadius.all(Radius.circular(10))),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Text('⭐ Score $_score', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Color(0x991B1440), borderRadius: BorderRadius.all(Radius.circular(10))),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Text(
                            'Tap the falling stars! · Demo mini-game, score is local only',
                            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Avatar overlay — large framed rig, glides with overlayX.
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                right: widget.overlayX >= 0 ? 12.0 : null,
                left: widget.overlayX < 0 ? 12.0 : null,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: KazumiColors.pink, width: 2),
                    boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 4))],
                  ),
                  child: LiveAnimeRig(
                    style: widget.style,
                    portraitAsset: widget.portraitAsset,
                    height: overlayH,
                    tilt: 0.1,
                    mouthLevel: widget.mouthLevel,
                    expression: widget.expression,
                    showParticles: false,
                    radius: 16,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
