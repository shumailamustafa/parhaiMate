import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// ParhaiMate square-rounded navy app badge with open-book + dot emblem.
class ParhaiMateLogo extends StatelessWidget {
  const ParhaiMateLogo({super.key, this.size = 76});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(
          color: AppColors.foreground.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: CustomPaint(
        painter: _LogoGlyphPainter(),
      ),
    );
  }
}

class _LogoGlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = AppColors.onPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.042
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = AppColors.onPrimary
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;

    // Top dot above the open book spine
    canvas.drawCircle(
      Offset(cx, size.height * 0.28),
      size.width * 0.048,
      fill,
    );

    // Open book left page
    final leftPage = Path()
      ..moveTo(cx, size.height * 0.45)
      ..quadraticBezierTo(
        size.width * 0.38,
        size.height * 0.38,
        size.width * 0.26,
        size.height * 0.41,
      )
      ..lineTo(size.width * 0.26, size.height * 0.69)
      ..quadraticBezierTo(
        size.width * 0.38,
        size.height * 0.66,
        cx,
        size.height * 0.74,
      );

    // Open book right page
    final rightPage = Path()
      ..moveTo(cx, size.height * 0.45)
      ..quadraticBezierTo(
        size.width * 0.62,
        size.height * 0.38,
        size.width * 0.74,
        size.height * 0.41,
      )
      ..lineTo(size.width * 0.74, size.height * 0.69)
      ..quadraticBezierTo(
        size.width * 0.62,
        size.height * 0.66,
        cx,
        size.height * 0.74,
      );

    canvas.drawPath(leftPage, stroke);
    canvas.drawPath(rightPage, stroke);

    // Center spine
    canvas.drawLine(
      Offset(cx, size.height * 0.45),
      Offset(cx, size.height * 0.74),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
