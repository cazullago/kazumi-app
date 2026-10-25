import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../avatar.dart';
import '../models.dart';
import '../theme.dart';

/// Cozy pixel-lofi bedroom: real illustrated room art behind the avatar.
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
        border: Border.all(color: KazumiColors.lavender, width: 2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/rooms/room_lofi.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(color: const Color(0xFFE9DCFF)),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: AnimatedAvatar(style: style, size: avatarSize, tilt: tilt, pendant: pendant, mouthLevel: mouthLevel),
              ),
            ),
            const Positioned(right: 12, bottom: 10, child: Text('♪ lofi beats ♪', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, shadows: [Shadow(color: Colors.black54, blurRadius: 4)]))),
          ],
        ),
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
