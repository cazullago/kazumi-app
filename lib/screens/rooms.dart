import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../avatar.dart';
import '../models.dart';
import '../theme.dart';

/// Cozy pixel-lofi bedroom drawn with containers (no heavy assets).
class PixelBedroom extends StatelessWidget {
  final AvatarStyle style;
  final double avatarSize;
  final double tilt;
  final bool pendant;
  final ValueListenable<double>? mouthLevel;
  const PixelBedroom({super.key, required this.style, this.avatarSize = 170, this.tilt = 0.15, this.pendant = false, this.mouthLevel});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE9DCFF), Color(0xFFFFE4EE)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        border: Border.all(color: KazumiColors.lavender, width: 2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          // Window with pixel stars.
          Positioned(
            left: 16,
            top: 14,
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(color: const Color(0xFF2B2350), border: Border.all(color: Colors.white, width: 3), borderRadius: BorderRadius.circular(10)),
              child: const Stack(
                children: [
                  Positioned(left: 10, top: 12, child: Text('✦', style: TextStyle(color: Colors.white, fontSize: 14))),
                  Positioned(right: 14, top: 26, child: Text('✧', style: TextStyle(color: Color(0xFFFFD166), fontSize: 16))),
                  Positioned(left: 22, bottom: 14, child: Text('★', style: TextStyle(color: Colors.white, fontSize: 12))),
                  Positioned(right: 10, bottom: 10, child: Text('🌙', style: TextStyle(fontSize: 18))),
                ],
              ),
            ),
          ),
          // Shelf with pixel items.
          Positioned(
            right: 16,
            top: 22,
            child: Column(
              children: [
                const Row(children: [Text('📚', style: TextStyle(fontSize: 20)), SizedBox(width: 4), Text('🪴', style: TextStyle(fontSize: 20)), SizedBox(width: 4), Text('🎧', style: TextStyle(fontSize: 20))]),
                Container(width: 110, height: 6, color: const Color(0xFF8B6F4E)),
              ],
            ),
          ),
          // Rug.
          Positioned(
            left: 24,
            right: 24,
            bottom: 14,
            child: Container(height: 18, decoration: BoxDecoration(color: KazumiColors.pink.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20))),
          ),
          // Bed (left) and avatar (centre).
          Positioned(
            left: 10,
            bottom: 34,
            child: Container(
              width: 78,
              height: 52,
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: KazumiColors.lavender, width: 2), borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('🛏️', style: TextStyle(fontSize: 26))),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: AnimatedAvatar(style: style, size: avatarSize, tilt: tilt, pendant: pendant, mouthLevel: mouthLevel),
            ),
          ),
          const Positioned(right: 12, bottom: 10, child: Text('♪ lofi beats ♪', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: KazumiColors.inkSoft))),
        ],
      ),
    );
  }
}

/// Gaming stage: large gameplay placeholder + avatar as small overlay.
/// The gameplay area is an honest placeholder, not a real game feed.
class GamingStage extends StatelessWidget {
  final AvatarStyle style;
  final double avatarSize;
  final double overlayX; // -1 left .. 1 right for the overlay position
  final ValueListenable<double>? mouthLevel;
  const GamingStage({super.key, required this.style, this.avatarSize = 88, this.overlayX = 1, this.mouthLevel});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F1B3A),
        border: Border.all(color: KazumiColors.lavender, width: 2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🎮', style: TextStyle(fontSize: 44)),
                SizedBox(height: 8),
                Text('GAMEPLAY PLACEHOLDER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                Text('Connect a game capture source to stream gameplay here.', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            right: overlayX >= 0 ? 12.0 : null,
            left: overlayX < 0 ? 12.0 : null,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(16), border: Border.all(color: KazumiColors.pink, width: 2)),
              child: AnimatedAvatar(style: style, size: avatarSize, tilt: 0.1, mouthLevel: mouthLevel),
            ),
          ),
        ],
      ),
    );
  }
}
