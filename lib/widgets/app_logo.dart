// lib/widgets/app_logo.dart
import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showGlow;

  const AppLogo({
    super.key,
    this.size = 120,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: showGlow
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF006A4E).withValues(alpha: 0.4),
                  blurRadius: size * 0.2,
                  spreadRadius: size * 0.02,
                ),
              ],
            )
          : null,
      child: Image.asset(
        'assets/images/minesec_logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _NewLogoEmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    // Glowing Multi-Gradient Sweep Orbit Ring
    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..shader = const SweepGradient(
        colors: [
          Color(0xFF00E676),
          Color(0xFF29B6F6),
          Color(0xFFFFD700),
          Color(0xFFEC407A),
          Color(0xFF00E676),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawCircle(center, radius - 6, ringPaint);

    // 4 VARK Node Glowing Dots
    final List<Color> nodeColors = [
      const Color(0xFF29B6F6), // Visual (Cyan)
      const Color(0xFFEC407A), // Auditory (Pink)
      const Color(0xFF00E676), // Kinesthetic (Green)
      const Color(0xFFFFD700), // Read/Write (Gold)
    ];

    for (int i = 0; i < 4; i++) {
      final double r = radius - 6;
      final Offset nodePos = Offset(
        center.dx + r * (i == 0 ? 1 : i == 2 ? -1 : 0),
        center.dy + r * (i == 1 ? 1 : i == 3 ? -1 : 0),
      );
      final Paint nodePaint = Paint()..color = nodeColors[i];
      final Paint glowPaint = Paint()
        ..color = nodeColors[i].withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(nodePos, 6, glowPaint);
      canvas.drawCircle(nodePos, 4.5, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
