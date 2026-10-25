import 'package:flutter/material.dart';

/// Cute pixel-lofi palette: pastel pink / lavender / cream / soft blue / sage.
class KazumiColors {
  static const cream = Color(0xFFFFF6E8);
  static const creamDark = Color(0xFFFDEBD2);
  static const pink = Color(0xFFFFB7D5);
  static const pinkDeep = Color(0xFFE86A9A);
  static const lavender = Color(0xFFC9B8F0);
  static const lavenderDeep = Color(0xFF7C6BD9);
  static const sky = Color(0xFFBFE3F2);
  static const sage = Color(0xFFBFDCC0);
  static const ink = Color(0xFF3D3356);
  static const inkSoft = Color(0xFF6E6584);
  static const gold = Color(0xFFFFD166);
  static const white = Colors.white;
}

class KazumiTheme {
  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, colorSchemeSeed: KazumiColors.lavenderDeep);
    return base.copyWith(
      scaffoldBackgroundColor: KazumiColors.cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: KazumiColors.cream,
        foregroundColor: KazumiColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: KazumiColors.ink,
        displayColor: KazumiColors.ink,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: KazumiColors.pinkDeep,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KazumiColors.ink,
          side: const BorderSide(color: KazumiColors.lavender, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white,
        selectedColor: KazumiColors.lavender,
        labelStyle: const TextStyle(color: KazumiColors.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SmoothPageTransitionsBuilder(),
          TargetPlatform.iOS: _SmoothPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Smooth eased page transitions everywhere (no abrupt jumps).
class _SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const _SmoothPageTransitionsBuilder();
  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.06, 0.02), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}

/// Dotted-star cream background, drawn cheaply with CustomPaint.
class PixelBackground extends StatelessWidget {
  final Widget child;
  const PixelBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const Positioned.fill(child: CustomPaint(painter: _DotsPainter())),
      child,
    ]);
  }
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFEED9F2);
    for (double y = 18; y < size.height; y += 44) {
      for (double x = 18; x < size.width; x += 44) {
        final odd = ((x + y) ~/ 44) % 2 == 0;
        if (odd) {
          canvas.drawCircle(Offset(x, y), 2.2, paint);
        } else {
          // tiny pixel star: two crossing lines
          canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: 7, height: 1.6), paint);
          canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: 1.6, height: 7), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Pixel frame card used across the app.
class PixelCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  const PixelCard({super.key, required this.child, this.color, this.padding = const EdgeInsets.all(14), this.onTap});
  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KazumiColors.lavender, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 0, offset: Offset(3, 3))],
      ),
      child: child,
    );
    if (onTap != null) {
      return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: card);
    }
    return card;
  }
}

/// Small pixel chip.
class PixelChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const PixelChip({super.key, required this.label, this.selected = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        selected: selected,
        onSelected: onTap == null ? null : (_) => onTap!(),
      ),
    );
  }
}

/// Pixel-font accent text: blocky styling with letter spacing, no font download.
class PixelText extends StatelessWidget {
  final String text;
  final double size;
  final Color? color;
  final FontWeight weight;
  const PixelText(this.text, {super.key, this.size = 16, this.color, this.weight = FontWeight.w800});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: size,
        fontWeight: weight,
        letterSpacing: 1.2,
        color: color ?? KazumiColors.ink,
      ),
    );
  }
}

/// Honest demo-data label — never present demo numbers as real.
class DemoLabel extends StatelessWidget {
  final String text;
  const DemoLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: KazumiColors.gold.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: KazumiColors.ink)),
    );
  }
}
