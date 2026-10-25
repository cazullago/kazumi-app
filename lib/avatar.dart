import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'models.dart';

/// Layered, smoothly animated avatar — the animation upgrade.
///
/// Every moving part has its own smooth driver, never a snap:
/// * Breathing: slow sine scale + lift (~3.2s cycle, ±1.2% scale).
/// * Hair sway: slower sine rotation + drift (~4.6s cycle, tiny amplitude).
/// * Blinking: one quick close every ~3.8s, 170ms, eased in and out with a
///   sine curve — natural intervals, never constant flicker.
/// * Head tilt: TweenAnimationBuilder lerps toward the target tilt over
///   450ms with easeInOutCubic — poses glide, they never jump.
/// * Mouth: driven by the caller's level (LIVE Studio: real mic amplitude
///   smoothed by an exponential moving average in MicLevel). When the level
///   is 0 the mouth rests closed; it never loops open/close on its own.
class AnimatedAvatar extends StatefulWidget {
  final AvatarStyle style;
  final double size;
  final double tilt; // -1 (left) .. 1 (right); lerped smoothly
  final double mouthOpen; // 0..1 static fallback
  final ValueListenable<double>? mouthLevel; // live mic level, if any
  final bool pendant; // MikaChan's purple gem pendant
  final bool animate; // false freezes motion (tiny list avatars stay calm)
  const AnimatedAvatar({
    super.key,
    required this.style,
    this.size = 120,
    this.tilt = 0,
    this.mouthOpen = 0,
    this.mouthLevel,
    this.pendant = false,
    this.animate = true,
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
    return AnimatedBuilder(
      animation: Listenable.merge(listenables),
      builder: (context, _) {
        final s = widget.style;
        final size = widget.size;
        final animate = widget.animate;
        // Breathing: gentle sine.
        final breathPhase = animate ? math.sin(2 * math.pi * _breath.value) : 0.0;
        final breathScale = 1 + 0.012 * breathPhase;
        final breathDy = -1.4 * breathPhase;
        // Hair sway: slow sine, small amplitude.
        final hairPhase = animate ? math.sin(2 * math.pi * _hair.value) : 0.0;
        final hairRotate = hairPhase * 0.03;
        final hairDx = hairPhase * 2.0;
        // Blink: quick eased close once per ~3.8s cycle (~170ms window).
        double eyeScaleY = 1.0;
        if (animate) {
          final phase = _blink.value;
          if (phase < 0.045) {
            final t = phase / 0.045;
            eyeScaleY = 1 - math.sin(math.pi * t) * 0.95;
          }
        }
        final mouthValue = (mouth?.value ?? widget.mouthOpen).clamp(0.0, 1.0);
        final hairDark = Color.lerp(s.hairColor, Colors.black, 0.18) ?? s.hairColor;
        final eyeDark = Color.lerp(s.eyeColor, Colors.black, 0.25) ?? s.eyeColor;
        final outfitColor = _outfitColor(s.outfit);

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (s.accessory == 'Angel Wings') ...[
                Positioned(left: size * 0.02, top: size * 0.42, child: _Wing(size: size * 0.28, flip: false)),
                Positioned(right: size * 0.02, top: size * 0.42, child: _Wing(size: size * 0.28, flip: true)),
              ],
              if (s.accessory == 'Star Halo')
                Positioned(
                  top: size * 0.02,
                  child: Container(
                    width: size * 0.34,
                    height: size * 0.09,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFFFD166), width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              // Back hair (sways with the front hair).
              Positioned(
                top: size * 0.08,
                child: Transform.translate(
                  offset: Offset(hairDx, 0),
                  child: Transform.rotate(angle: hairRotate, child: _BackHair(style: s, size: size, hairDark: hairDark)),
                ),
              ),
              // Body / outfit.
              Positioned(
                bottom: 0,
                child: Container(
                  width: size * 0.52,
                  height: size * 0.30,
                  decoration: BoxDecoration(
                    color: outfitColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
                  ),
                ),
              ),
              // Head group: breathing wraps tilt so both motions compose.
              Positioned(
                top: size * 0.16,
                child: Transform.translate(
                  offset: Offset(0, breathDy),
                  child: Transform.scale(
                    scale: breathScale,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: widget.tilt),
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeInOutCubic,
                      builder: (context, tilt, child) {
                        return Transform.rotate(
                          angle: tilt * 0.07,
                          child: Transform.translate(offset: Offset(tilt * 3, 0), child: child),
                        );
                      },
                      child: SizedBox(
                        width: size * 0.56,
                        height: size * 0.56,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Face.
                            Container(
                              width: size * 0.52,
                              height: size * 0.52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFFFFEDE0), Color(0xFFFFD9C2)],
                                ),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                              ),
                            ),
                            // Cat ears.
                            if (s.accessory == 'Cat Ears') ...[
                              Positioned(top: size * 0.005, left: size * 0.06, child: _CatEar(size: size * 0.16)),
                              Positioned(top: size * 0.005, right: size * 0.06, child: _CatEar(size: size * 0.16)),
                              Positioned(
                                top: size * 0.13,
                                right: size * 0.10,
                                child: const Text('🎀', style: TextStyle(fontSize: 16)),
                              ),
                            ],
                            // Front hair with sway + shine bands.
                            Positioned(
                              top: 0,
                              child: Transform.translate(
                                offset: Offset(hairDx, 0),
                                child: Transform.rotate(
                                  angle: hairRotate,
                                  child: _FrontHair(style: s, size: size, hairDark: hairDark),
                                ),
                              ),
                            ),
                            // Gem eyes (blink scales Y smoothly).
                            Positioned(
                              top: size * 0.26,
                              left: size * 0.11,
                              child: _GemEye(size: size * 0.105, color: s.eyeColor, dark: eyeDark, scaleY: eyeScaleY, tilt: widget.tilt),
                            ),
                            Positioned(
                              top: size * 0.26,
                              right: size * 0.11,
                              child: _GemEye(size: size * 0.105, color: s.eyeColor, dark: eyeDark, scaleY: eyeScaleY, tilt: widget.tilt),
                            ),
                            // Eyebrows.
                            Positioned(top: size * 0.225, left: size * 0.115, child: _Brow(size: size * 0.07)),
                            Positioned(top: size * 0.225, right: size * 0.115, child: _Brow(size: size * 0.07)),
                            // Blush.
                            Positioned(top: size * 0.345, left: size * 0.06, child: _Blush(size: size * 0.07)),
                            Positioned(top: size * 0.345, right: size * 0.06, child: _Blush(size: size * 0.07)),
                            // Mouth: AnimatedContainer retargets smoothly as the
                            // EMA level moves — no snapping, no random loop.
                            Positioned(
                              top: size * 0.395,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeOutCubic,
                                width: size * 0.075 + mouthValue * size * 0.05,
                                height: 3 + mouthValue * size * 0.075,
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
                  ),
                ),
              ),
              // MikaChan extras.
              if (widget.pendant)
                Positioned(
                  bottom: size * 0.20,
                  child: const Text('🔮', style: TextStyle(fontSize: 18)),
                ),
              if (s.accessory == 'Cat Ears' && widget.pendant)
                const Positioned(top: 8, left: 14, child: Text('⭐', style: TextStyle(fontSize: 14))),
            ],
          ),
        );
      },
    );
  }

  Color _outfitColor(String outfit) {
    switch (outfit) {
      case 'Star Dress':
        return const Color(0xFFC9B8F0);
      case 'Cozy Sweater':
        return const Color(0xFFBFDCC0);
      case 'Gaming Tee':
        return const Color(0xFFBFE3F2);
      default:
        return const Color(0xFFFFB7D5);
    }
  }
}

class _Wing extends StatelessWidget {
  final double size;
  final bool flip;
  const _Wing({required this.size, required this.flip});
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: flip ? -0.5 : 0.5,
      child: Container(
        width: size,
        height: size * 0.7,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(size * 0.5),
          border: Border.all(color: const Color(0xFFFFD166), width: 1.5),
        ),
      ),
    );
  }
}

class _CatEar extends StatelessWidget {
  final double size;
  const _CatEar({required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF3D3356),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Center(
        child: Container(
          width: size * 0.45,
          height: size * 0.45,
          decoration: BoxDecoration(color: const Color(0xFFFFB7D5), borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

class _BackHair extends StatelessWidget {
  final AvatarStyle style;
  final double size;
  final Color hairDark;
  const _BackHair({required this.style, required this.size, required this.hairDark});
  @override
  Widget build(BuildContext context) {
    final s = style;
    final grad = LinearGradient(colors: [s.hairColor, hairDark], begin: Alignment.topCenter, end: Alignment.bottomCenter);
    switch (s.hairStyle) {
      case 'Twin Tails':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: size * 0.13, height: size * 0.62, decoration: BoxDecoration(gradient: grad, borderRadius: BorderRadius.circular(20))),
            SizedBox(width: size * 0.34),
            Container(width: size * 0.13, height: size * 0.62, decoration: BoxDecoration(gradient: grad, borderRadius: BorderRadius.circular(20))),
          ],
        );
      case 'Short Bob':
        return Container(width: size * 0.60, height: size * 0.52, decoration: BoxDecoration(gradient: grad, borderRadius: BorderRadius.circular(26)));
      case 'Ponytail':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: size * 0.40, height: size * 0.34, decoration: BoxDecoration(gradient: grad, borderRadius: BorderRadius.circular(22))),
            Container(width: size * 0.13, height: size * 0.60, decoration: BoxDecoration(gradient: grad, borderRadius: BorderRadius.circular(20))),
          ],
        );
      default: // Long Wavy
        return Container(width: size * 0.62, height: size * 0.66, decoration: BoxDecoration(gradient: grad, borderRadius: BorderRadius.circular(30)));
    }
  }
}

class _FrontHair extends StatelessWidget {
  final AvatarStyle style;
  final double size;
  final Color hairDark;
  const _FrontHair({required this.style, required this.size, required this.hairDark});
  @override
  Widget build(BuildContext context) {
    final s = style;
    return SizedBox(
      width: size * 0.56,
      height: size * 0.30,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [s.hairColor, hairDark], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(60), bottom: Radius.circular(24)),
            ),
          ),
          // Shine bands — Genshin-style hair shine.
          Positioned(
            left: size * 0.10,
            top: size * 0.03,
            child: Transform.rotate(
              angle: -0.35,
              child: Container(width: size * 0.05, height: size * 0.18, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(8))),
            ),
          ),
          Positioned(
            left: size * 0.20,
            top: size * 0.05,
            child: Transform.rotate(
              angle: -0.35,
              child: Container(width: size * 0.03, height: size * 0.12, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.30), borderRadius: BorderRadius.circular(8))),
            ),
          ),
          // Side fringe wisps.
          Positioned(left: 0, top: size * 0.14, child: Container(width: size * 0.06, height: size * 0.14, decoration: BoxDecoration(color: s.hairColor, borderRadius: BorderRadius.circular(10)))),
          Positioned(right: 0, top: size * 0.14, child: Container(width: size * 0.06, height: size * 0.14, decoration: BoxDecoration(color: s.hairColor, borderRadius: BorderRadius.circular(10)))),
        ],
      ),
    );
  }
}

class _GemEye extends StatelessWidget {
  final double size;
  final Color color;
  final Color dark;
  final double scaleY;
  final double tilt;
  const _GemEye({required this.size, required this.color, required this.dark, required this.scaleY, required this.tilt});
  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleY: scaleY.clamp(0.05, 1.0),
      child: Container(
        width: size,
        height: size * 1.25,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, dark], center: const Alignment(0, -0.3), radius: 1.1),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1),
        ),
        child: Stack(
          children: [
            Positioned(left: size * 0.18 + tilt * 1.2, top: size * 0.12, child: Container(width: size * 0.28, height: size * 0.28, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
            Positioned(right: size * 0.14, bottom: size * 0.16, child: Container(width: size * 0.14, height: size * 0.14, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
          ],
        ),
      ),
    );
  }
}

class _Brow extends StatelessWidget {
  final double size;
  const _Brow({required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: 3, decoration: BoxDecoration(color: const Color(0xFF6E6584), borderRadius: BorderRadius.circular(2)));
  }
}

class _Blush extends StatelessWidget {
  final double size;
  const _Blush({required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size * 0.6, decoration: BoxDecoration(color: const Color(0xFFFFB7D5).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(10)));
  }
}
