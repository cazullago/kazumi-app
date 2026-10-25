import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'models.dart';

/// Illustrated avatar — v1.0.1.
///
/// The old drawn blob/circle renderer is GONE. Every avatar is now a real
/// illustrated Genshin-style portrait asset (assets/portraits/*.jpg).
/// Creators use their explicit portrait; the user's look maps to the
/// closest illustrated portrait for its hairstyle / hair colour, so a
/// Store equip visibly changes the portrait shown (Store-only, as before).
///
/// Animation is kept, applied as smooth transforms over the illustration:
/// * Breathing: slow sine scale + lift (~3.2s, ±1.2%).
/// * Hair sway: slow sine rotation + drift (~4.6s, tiny amplitude).
/// * Blinking: a brief eyelid-coloured cover over the eye area once per
///   ~3.8s cycle (~170ms), eased in/out — never constant flicker.
/// * Head tilt: TweenAnimationBuilder, 450ms, easeInOutCubic — glides.
/// * Mouth: driven by the caller's level (LIVE Studio: real mic amplitude
///   smoothed by an EMA in MicLevel). At level 0 the mouth overlay is
///   hidden; it never loops open/close on its own.
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
                  // Blink: eyelid-coloured covers over the eye band, briefly.
                  if (blinkAmount > 0.05) ...[
                    Positioned(
                      left: size * 0.24,
                      top: size * 0.30,
                      width: size * 0.18,
                      height: size * 0.10 * blinkAmount + 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEDE0).withValues(alpha: blinkAmount),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    Positioned(
                      right: size * 0.24,
                      top: size * 0.30,
                      width: size * 0.18,
                      height: size * 0.10 * blinkAmount + 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEDE0).withValues(alpha: blinkAmount),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                  // Mouth overlay, only when actually speaking / level > 0.
                  if (mouthValue > 0.03)
                    Positioned(
                      left: size * 0.42,
                      top: size * 0.60,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOutCubic,
                        width: size * 0.16,
                        height: 2 + mouthValue * size * 0.09,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD94F70),
                          borderRadius: BorderRadius.circular(10),
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
