import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Dibuja una silueta de pokébola semitransparente usada como decoración.
class PokeballPainter extends CustomPainter {
  final Color color;
  PokeballPainter({this.color = const Color(0x22FFFFFF)});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2;
    final stroke = r * 0.14;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    canvas.drawCircle(c, r - stroke / 2, paint);
    canvas.drawLine(
      Offset(c.dx - r, c.dy),
      Offset(c.dx - r * 0.32, c.dy),
      paint,
    );
    canvas.drawLine(
      Offset(c.dx + r * 0.32, c.dy),
      Offset(c.dx + r, c.dy),
      paint,
    );
    canvas.drawCircle(c, r * 0.25, paint);
  }

  @override
  bool shouldRepaint(covariant PokeballPainter oldDelegate) =>
      oldDelegate.color != color;
}

class PokeballDecoration extends StatelessWidget {
  final double size;
  final Color color;
  const PokeballDecoration({
    super.key,
    required this.size,
    this.color = const Color(0x22FFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: PokeballPainter(color: color)),
    );
  }
}
