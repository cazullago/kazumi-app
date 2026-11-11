import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'models.dart';

/// LIVE v2 — anime rig.
///
/// The old drawn blob/circle renderer is GONE. Every avatar is a real
/// illustrated Genshin-style portrait asset (assets/portraits/*.jpg).
/// Creators use their explicit portrait; the user's look maps to the
/// closest illustrated portrait for its hairstyle / hair colour, so a
/// Store equip visibly changes the portrait shown (Store-only, as before).
///
/// LIVE presentation is [LiveAnimeRig]: a large half-body stage panel at
/// exactly the portrait's 2:3 aspect, full-bleed (BoxFit.cover, no circle
/// crop, head never cropped), with a soft glow / gradient frame.
///
/// Animation is smooth and eased, never snapping:
/// * Breathing: slow sine scale ~±1.5% + gentle vertical bob, ~3.4s cycle.
/// * Hair sway / idle sway: slow sine rotation + drift, tiny amplitude.
/// * Head movement: slow idle sway (derived from the hair phase) + the
///   caller's tilt, which glides via TweenAnimationBuilder, 450ms,
///   easeInOutCubic.
/// * Blinking: a proper eyelid overlay (skin-tone, with a lash line)
///   painted over the eye band, ~170ms once per ~3.8s, eased in/out.
/// * Mouth: a proper anime mouth painted with [AnimeMouthPainter] — dark
///   open oval with a tongue highlight when open, shapes varying smoothly
///   with the mic level. Driven by the caller's level (LIVE Studio: real
///   mic amplitude smoothed by an EMA in MicLevel). At level 0 the mouth
///   stays closed. It never loops open/close on its own.
/// * Life: twinkling star particles / dust motes drifting in the stage,
///   a soft pulsing LIVE glow and a subtle vignette.
///
/// Face anchors below were measured from the real mikachan.jpg portrait
/// (1280x1920): eyes ~39-41% down, mouth ~49.5% down, face centred
/// slightly right of middle. Other creators' portraits are framed the
/// same way, so the same anchors are a good approximation for all of
/// them — not pixel-perfect for every portrait, and the overlays are
/// deliberately small so a few pixels of drift never looks broken.
enum LiveExpression { normal, happy, surprised }

extension LiveExpressionLabel on LiveExpression {
  String get label {
    switch (this) {
      case LiveExpression.normal:
        return 'Normal';
      case LiveExpression.happy:
        return 'Happy';
      case LiveExpression.surprised:
        return 'Surprised';
    }
  }
}

String portraitForStyle(AvatarStyle s) {
  final hair = s.hairStyle;
  final color = s.hairColor.toARGB32();
  if (hair == 'Twin Tails') return 'assets/portraits/sakurapixel.jpg';
  if (hair == 'Short Bob' && color == 0xFF7ED6A5) return 'assets/portraits/kiko.jpg';
  if (hair == 'Short Bob') return 'assets/portraits/rin.jpg';
  if (hair == 'Ponytail') return 'assets/portraits/mochi.jpg';
  if (color == 0xFF8EA8E8) return 'assets/portraits/luna.jpg';
  if (color == 0xFFFFB7D5) return 'assets/portraits/sakurapixel.jpg';
  if (color == 0xFFE8E8E8 || s.accessory == 'Angel Wings') return 'assets/portraits/ren.jpg';
  if (color == 0xFFFFD166) return 'assets/portraits/mochi.jpg';
  return 'assets/portraits/mikachan.jpg';
}

/// Full-image portrait thumb (cards, rows, stage) — artwork fills the box.
Widget portraitThumb(String asset, double width, double height, {double radius = 14}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: Image.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => Container(
        width: width,
        height: height,
        color: const Color(0xFFC9B8F0),
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined, color: Colors.white),
      ),
    ),
  );
}

/// Anime mouth, painted — never a pink rectangle.
///
/// [open] is 0..1 (mic level, already EMA-smoothed by the caller).
/// Closed: a thin curved smile line (wider for Happy, a small "o" for
/// Surprised). Open: a dark oval with a tongue highlight at the bottom,
/// growing smoothly with [open]. Surprised opens wider and rounder.
class AnimeMouthPainter extends CustomPainter {
  final double open;
  final LiveExpression expression;
  final Offset center; // fraction of the painted size
  final double widthFrac; // mouth width as a fraction of painted width
  const AnimeMouthPainter({
    required this.open,
    this.expression = LiveExpression.normal,
    this.center = const Offset(0.56, 0.495),
    this.widthFrac = 0.10,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * center.dx;
    final cy = size.height * center.dy;
    final w = size.width * widthFrac;
    final dark = Paint()
      ..color = const Color(0xFF6E2B3A)
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = const Color(0xFF8A4A3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, size.width * 0.006)
      ..strokeCap = StrokeCap.round;

    if (open <= 0.04) {
      if (expression == LiveExpression.surprised) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, cy), width: w * 0.38, height: size.height * 0.012),
          dark,
        );
        return;
      }
      // Closed smile: a gentle curved line, wider + deeper when happy.
      final depth = expression == LiveExpression.happy ? size.height * 0.010 : size.height * 0.006;
      final halfW = expression == LiveExpression.happy ? w * 0.62 : w * 0.5;
      final path = Path()
        ..moveTo(cx - halfW, cy - depth * 0.4)
        ..quadraticBezierTo(cx, cy + depth, cx + halfW, cy - depth * 0.4);
      canvas.drawPath(path, line);
      return;
    }

    final o = open.clamp(0.0, 1.0);
    final wide = expression == LiveExpression.surprised ? 1.18 : 1.0;
    final tall = expression == LiveExpression.surprised ? 1.35 : 1.0;
    final openW = w * (0.72 + 0.45 * o) * wide;
    final openH = size.height * 0.034 * o * tall + size.height * 0.004;
    // Dark open mouth.
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: openW, height: openH), dark);
    // Tongue highlight at the bottom of the mouth.
    if (o > 0.18) {
      final tongue = Paint()..color = const Color(0xFFE87A8A);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy + openH * 0.24),
          width: openW * 0.62,
          height: openH * 0.52,
        ),
        tongue,
      );
    }
    // Upper lip line, so the open mouth still reads as anime.
    final lipPath = Path()
      ..moveTo(cx - openW * 0.5, cy - openH * 0.18)
      ..quadraticBezierTo(cx, cy - openH * 0.55, cx + openW * 0.5, cy - openH * 0.18);
    canvas.drawPath(lipPath, line);
  }

  @override
  bool shouldRepaint(covariant AnimeMouthPainter old) =>
      (open - old.open).abs() > 0.002 || expression != old.expression || center != old.center || widthFrac != old.widthFrac;
}

/// Anime eyelids, painted — never skin-coloured rectangles.
///
/// [blink] is 0..1 (0 = eyes open, 1 = fully closed). The lid sweeps down
/// from the top of the eye band in the portrait's skin tone, with a dark
/// lash line at its lower edge. Happy draws smiling ^ ^ eye arcs instead
/// of the portrait's open eyes.
class AnimeEyelidPainter extends CustomPainter {
  final double blink;
  final LiveExpression expression;
  final Offset leftEye; // centre, fraction of painted size
  final Offset rightEye;
  final double eyeWidthFrac;
  const AnimeEyelidPainter({
    required this.blink,
    this.expression = LiveExpression.normal,
    this.leftEye = const Offset(0.47, 0.388),
    this.rightEye = const Offset(0.675, 0.405),
    this.eyeWidthFrac = 0.16,
  });

  void _paintEye(Canvas canvas, Size size, Offset centreFrac, double widthFrac, double heightFrac) {
    final cx = size.width * centreFrac.dx;
    final cy = size.height * centreFrac.dy;
    final w = size.width * widthFrac;
    final h = size.height * heightFrac;
    if (expression == LiveExpression.happy && blink <= 0.05) {
      // Smiling closed eyes: upward arcs.
      final arcPaint = Paint()
        ..color = const Color(0xFF3D3356)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, size.width * 0.007)
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCenter(center: Offset(cx, cy), width: w, height: h * 1.5), math.pi, math.pi, false, arcPaint);
      return;
    }
    if (blink <= 0.05) return;
    final lid = Paint()..color = const Color(0xFFFFEDE0);
    final lidHeight = h * blink;
    // Lid sweeps down from the top of the eye.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - h / 2 + lidHeight / 2), width: w, height: lidHeight + 1),
      lid,
    );
    if (blink > 0.45) {
      final lash = Paint()
        ..color = const Color(0xFF3D3356)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, size.width * 0.006)
        ..strokeCap = StrokeCap.round;
      final ly = cy - h / 2 + lidHeight;
      canvas.drawLine(Offset(cx - w * 0.42, ly), Offset(cx + w * 0.42, ly), lash);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintEye(canvas, size, leftEye, eyeWidthFrac, 0.058);
    _paintEye(canvas, size, rightEye, eyeWidthFrac * 0.85, 0.052);
  }

  @override
  bool shouldRepaint(covariant AnimeEyelidPainter old) =>
      (blink - old.blink).abs() > 0.002 || expression != old.expression;
}

/// Twinkling star particles / dust motes drifting slowly upward.
/// Deterministic (seeded) so the stage looks the same every launch.
class StarParticles extends StatefulWidget {
  final int count;
  const StarParticles({super.key, this.count = 26});
  @override
  State<StarParticles> createState() => _StarParticlesState();
}

class _StarParticlesState extends State<StarParticles> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Mote> _motes;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
    final rnd = math.Random(7);
    _motes = List.generate(widget.count, (_) {
      return _Mote(
        x: rnd.nextDouble(),
        y: rnd.nextDouble(),
        size: 2 + rnd.nextDouble() * 5,
        phase: rnd.nextDouble(),
        speed: 0.02 + rnd.nextDouble() * 0.05,
        gold: rnd.nextBool(),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => CustomPaint(
        painter: _StarParticlesPainter(motes: _motes, t: _ctrl.value),
        size: Size.infinite,
      ),
    );
  }
}

class _Mote {
  final double x, y, size, phase, speed;
  final bool gold;
  const _Mote({required this.x, required this.y, required this.size, required this.phase, required this.speed, required this.gold});
}

class _StarParticlesPainter extends CustomPainter {
  final List<_Mote> motes;
  final double t;
  const _StarParticlesPainter({required this.motes, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    for (final m in motes) {
      final y = (m.y - t * m.speed) % 1.0;
      final twinkle = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(2 * math.pi * (t + m.phase)));
      final paint = Paint()..color = (m.gold ? const Color(0xFFFFD166) : Colors.white).withValues(alpha: twinkle);
      final cx = m.x * size.width;
      final cy = y * size.height;
      final s = m.size;
      // Four-point star: two crossing bars + centre dot.
      canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: s * 2.2, height: s * 0.45), paint);
      canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: s * 0.45, height: s * 2.2), paint);
      canvas.drawCircle(Offset(cx, cy), s * 0.45, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarParticlesPainter old) => t != old.t;
}

/// LIVE stage rig — large half-body anime presentation.
///
/// Sized by [height] at exactly 2:3 (the portrait's aspect), full-bleed
/// with a soft glow / gradient frame. No circle crop, head never cropped.
/// All idle motion is slow sine, eased; the mouth is mic-driven only.
class LiveAnimeRig extends StatefulWidget {
  final AvatarStyle style;
  final String? portraitAsset;
  final double height;
  final double tilt;
  final double mouthOpen;
  final ValueListenable<double>? mouthLevel;
  final LiveExpression expression;
  final bool animate;
  final bool showParticles;
  final bool showGlow;
  final double radius;
  const LiveAnimeRig({
    super.key,
    required this.style,
    this.portraitAsset,
    this.height = 320,
    this.tilt = 0,
    this.mouthOpen = 0,
    this.mouthLevel,
    this.expression = LiveExpression.normal,
    this.animate = true,
    this.showParticles = true,
    this.showGlow = true,
    this.radius = 22,
  });
  @override
  State<LiveAnimeRig> createState() => _LiveAnimeRigState();
}

class _LiveAnimeRigState extends State<LiveAnimeRig> with TickerProviderStateMixin {
  late final AnimationController _breath;
  late final AnimationController _hair;
  late final AnimationController _blink;
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400))..repeat();
    _hair = AnimationController(vsync: this, duration: const Duration(milliseconds: 4600))..repeat();
    _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 3800))..repeat();
    _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breath.dispose();
    _hair.dispose();
    _blink.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listenables = <Listenable>[_breath, _hair, _blink, _glow];
    final mouth = widget.mouthLevel;
    if (mouth != null) listenables.add(mouth);
    final asset = widget.portraitAsset ?? portraitForStyle(widget.style);
    final width = widget.height * 2 / 3;
    return AnimatedBuilder(
      animation: Listenable.merge(listenables),
      builder: (context, _) {
        final animate = widget.animate;
        final breathPhase = animate ? math.sin(2 * math.pi * _breath.value) : 0.0;
        final breathScale = 1 + 0.015 * breathPhase;
        final breathDy = -2.0 * breathPhase;
        final hairPhase = animate ? math.sin(2 * math.pi * _hair.value) : 0.0;
        final hairRotate = hairPhase * 0.012;
        final hairDx = hairPhase * 2.0;
        // Slow idle head sway, gliding on the same slow sine — never a snap.
        final swayDx = animate ? math.sin(2 * math.pi * _hair.value * 0.5) * 2.5 : 0.0;
        final swayRotate = animate ? math.sin(2 * math.pi * _hair.value * 0.5) * 0.014 : 0.0;
        double blinkAmount = 0.0;
        if (animate) {
          final phase = _blink.value;
          if (phase < 0.045) blinkAmount = math.sin(math.pi * (phase / 0.045));
        }
        final mouthValue = (mouth?.value ?? widget.mouthOpen).clamp(0.0, 1.0);
        final glowPulse = 0.5 + 0.5 * _glow.value;
        return SizedBox(
          width: width,
          height: widget.height,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: widget.tilt),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOutCubic,
            builder: (context, tilt, child) {
              return Transform.translate(
                offset: Offset(tilt * 3 + hairDx + swayDx, breathDy),
                child: Transform.rotate(
                  angle: tilt * 0.07 + hairRotate + swayRotate,
                  child: Transform.scale(scale: breathScale, child: child),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius),
                border: Border.all(color: const Color(0xFFFFB7D5).withValues(alpha: 0.65 + 0.35 * glowPulse), width: 2),
                boxShadow: widget.showGlow
                    ? [
                        BoxShadow(
                          color: const Color(0xFFE86A9A).withValues(alpha: 0.25 + 0.2 * glowPulse),
                          blurRadius: 26,
                          spreadRadius: 2,
                        ),
                        const BoxShadow(color: Color(0x337C6BD9), blurRadius: 18, offset: Offset(0, 6)),
                      ]
                    : const [BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 6))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.radius - 1),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      asset,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (context, error, stack) => Container(
                        color: const Color(0xFFC9B8F0),
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported_outlined, color: Colors.white, size: 40),
                      ),
                    ),
                    // Soft vignette: keeps the portrait readable, edges glow.
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x14FFFFFF), Color(0x00000000), Color(0x00000000), Color(0x2EE86A9A)],
                          stops: [0.0, 0.25, 0.75, 1.0],
                        ),
                      ),
                    ),
                    if (widget.showParticles) const StarParticles(count: 18),
                    // Eyelids + mouth, painted over the portrait.
                    Positioned.fill(
                      child: CustomPaint(
                        painter: AnimeEyelidPainter(blink: blinkAmount, expression: widget.expression),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: AnimeMouthPainter(open: mouthValue, expression: widget.expression),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AnimatedAvatar extends StatefulWidget {
  final AvatarStyle style;
  final double size;
  final double tilt;
  final double mouthOpen;
  final ValueListenable<double>? mouthLevel;
  final bool pendant;
  final bool animate;
  final String? portraitAsset;
  const AnimatedAvatar({
    super.key,
    required this.style,
    this.size = 120,
    this.tilt = 0,
    this.mouthOpen = 0,
    this.mouthLevel,
    this.pendant = false,
    this.animate = true,
    this.portraitAsset,
  });
  @override
  State<AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends State<AnimatedAvatar> with TickerProviderStateMixin {
  late final AnimationController _breath;
  late final AnimationController _hair;
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();
    _hair = AnimationController(vsync: this, duration: const Duration(milliseconds: 4600))..repeat();
    _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 3800))..repeat();
  }

  @override
  void dispose() {
    _breath.dispose();
    _hair.dispose();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listenables = <Listenable>[_breath, _hair, _blink];
    final mouth = widget.mouthLevel;
    if (mouth != null) listenables.add(mouth);
    final asset = widget.portraitAsset ?? portraitForStyle(widget.style);
    return AnimatedBuilder(
      animation: Listenable.merge(listenables),
      builder: (context, _) {
        final size = widget.size;
        final animate = widget.animate;
        final breathPhase = animate ? math.sin(2 * math.pi * _breath.value) : 0.0;
        final breathScale = 1 + 0.012 * breathPhase;
        final breathDy = -1.4 * breathPhase;
        final hairPhase = animate ? math.sin(2 * math.pi * _hair.value) : 0.0;
        final hairRotate = hairPhase * 0.03;
        final hairDx = hairPhase * 2.0;
        double blinkAmount = 0.0;
        if (animate) {
          final phase = _blink.value;
          if (phase < 0.045) blinkAmount = math.sin(math.pi * (phase / 0.045));
        }
        final mouthValue = (mouth?.value ?? widget.mouthOpen).clamp(0.0, 1.0);
        return SizedBox(
          width: size,
          height: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: widget.tilt),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOutCubic,
            builder: (context, tilt, child) {
              return Transform.translate(
                offset: Offset(tilt * 3 + hairDx, breathDy),
                child: Transform.rotate(
                  angle: tilt * 0.07 + hairRotate,
                  child: Transform.scale(scale: breathScale, child: child),
                ),
              );
            },
            // Small thumbs only (cards, rows, lists) — the LIVE stage uses
            // LiveAnimeRig, never this circle. Mouth/blink are painted
            // here too, so no pink rectangle appears anywhere.
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    asset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      color: const Color(0xFFC9B8F0),
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined, color: Colors.white),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: AnimeEyelidPainter(
                        blink: blinkAmount,
                        leftEye: const Offset(0.36, 0.33),
                        rightEye: const Offset(0.64, 0.33),
                        eyeWidthFrac: 0.20,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: AnimeMouthPainter(
                        open: mouthValue,
                        center: const Offset(0.50, 0.52),
                        widthFrac: 0.18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
