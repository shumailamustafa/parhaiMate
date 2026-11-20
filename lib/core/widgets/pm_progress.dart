import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Linear progress bar using navy (#123B52) on #DCDCDC track, clamped 0..1.
class PmProgressBar extends StatelessWidget {
  const PmProgressBar({
    required this.progress,
    super.key,
    this.height = 7,
    this.fillColor = AppColors.primary,
    this.trackColor = AppColors.track,
  });

  final double progress;
  final double height;
  final Color fillColor;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(height),
      ),
      alignment: Alignment.centerLeft,
      child: AnimatedFractionallySizedBox(
        duration: const Duration(milliseconds: 220),
        alignment: Alignment.centerLeft,
        widthFactor: clamped,
        heightFactor: 1,
        child: Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(height),
          ),
        ),
      ),
    );
  }
}

/// Circular progress ring using navy (#123B52) on #DCDCDC track, clamped 0..1.
class PmCircularProgress extends StatelessWidget {
  const PmCircularProgress({
    required this.progress,
    super.key,
    this.size = 128,
    this.strokeWidth = 10,
    this.fillColor = AppColors.primary,
    this.trackColor = AppColors.track,
    this.child,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Color fillColor;
  final Color trackColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CircularRingPainter(
          progress: clamped,
          strokeWidth: strokeWidth,
          fillColor: fillColor,
          trackColor: trackColor,
        ),
        child: child != null ? Center(child: child) : null,
      ),
    );
  }
}

class _CircularRingPainter extends CustomPainter {
  const _CircularRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.fillColor,
    required this.trackColor,
  });

  final double progress;
  final double strokeWidth;
  final Color fillColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    if (radius <= 0) {
      return;
    }

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) {
      return;
    }

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.trackColor != trackColor;
  }
}
