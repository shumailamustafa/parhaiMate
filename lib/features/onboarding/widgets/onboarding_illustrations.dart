import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Monochrome + navy (#123B52) custom vector illustrations for the 3 onboarding slides.
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({required this.slideIndex, super.key});

  final int slideIndex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: CustomPaint(
        painter: _OnboardingPainter(slideIndex: slideIndex),
      ),
    );
  }
}

class _OnboardingPainter extends CustomPainter {
  const _OnboardingPainter({required this.slideIndex});

  final int slideIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Soft light-grey circular backdrop (#F0F0F0)
    canvas.drawCircle(
      Offset(cx, cy + 8),
      size.width * 0.39,
      Paint()..color = AppColors.surface,
    );

    switch (slideIndex) {
      case 0:
        _paintFocusSlide(canvas, size);
      case 1:
        _paintPlanSlide(canvas, size);
      default:
        _paintProgressSlide(canvas, size);
    }
  }

  void _paintFocusSlide(Canvas canvas, Size size) {
    final navyFill = Paint()..color = AppColors.primary;
    final whiteFill = Paint()..color = AppColors.background;
    final blackStroke = Paint()
      ..color = AppColors.foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final navyStroke = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    // Student silhouette / study hood behind laptop
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.49),
        width: size.width * 0.28,
        height: size.height * 0.28,
      ),
      math.pi,
      math.pi,
      true,
      navyFill,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.455),
      3.5,
      Paint()..color = AppColors.foreground,
    );

    // Desk horizontal bar and legs
    final deskY = size.height * 0.72;
    canvas.drawLine(
      Offset(size.width * 0.18, deskY),
      Offset(size.width * 0.82, deskY),
      blackStroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.23, deskY + 8),
      Offset(size.width * 0.77, deskY + 8),
      blackStroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.29, deskY),
      Offset(size.width * 0.29, deskY + 8),
      blackStroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.71, deskY),
      Offset(size.width * 0.71, deskY + 8),
      blackStroke,
    );

    // Open notebook/laptop in front
    final screenRect = Rect.fromLTWH(
      size.width * 0.35,
      size.height * 0.51,
      size.width * 0.30,
      size.height * 0.21,
    );
    canvas.drawRect(screenRect, whiteFill);
    canvas.drawRect(screenRect, blackStroke);
    canvas.drawLine(
      Offset(size.width * 0.43, size.height * 0.59),
      Offset(size.width * 0.57, size.height * 0.59),
      navyStroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.43, size.height * 0.635),
      Offset(size.width * 0.57, size.height * 0.635),
      navyStroke,
    );

    // Study mug on right
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.70,
        size.height * 0.64,
        size.width * 0.08,
        size.height * 0.08,
      ),
      navyFill,
    );

    // Top-right clock badge
    final clockCenter = Offset(size.width * 0.77, size.height * 0.28);
    final clockRadius = size.width * 0.125;
    canvas.drawCircle(clockCenter, clockRadius, whiteFill);
    canvas.drawCircle(clockCenter, clockRadius, navyStroke);
    final clockHands = Path()
      ..moveTo(clockCenter.dx, clockCenter.dy - clockRadius * 0.55)
      ..lineTo(clockCenter.dx, clockCenter.dy)
      ..lineTo(clockCenter.dx + clockRadius * 0.45, clockCenter.dy + 4);
    canvas.drawPath(clockHands, blackStroke);
  }

  void _paintPlanSlide(Canvas canvas, Size size) {
    final whiteFill = Paint()..color = AppColors.background;
    final navyFill = Paint()..color = AppColors.primary;
    final borderPaint = Paint()
      ..color = AppColors.foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeJoin = StrokeJoin.round;
    final navyStroke = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Planner card
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.53),
        width: size.width * 0.52,
        height: size.height * 0.54,
      ),
      const Radius.circular(16),
    );
    canvas.drawRRect(cardRect, whiteFill);
    canvas.drawRRect(cardRect, borderPaint);

    // Navy header band
    final headerRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(
        cardRect.left,
        cardRect.top,
        cardRect.width,
        size.height * 0.12,
      ),
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
    );
    canvas.drawRRect(headerRect, navyFill);

    // Three task checklist rows
    for (var i = 0; i < 3; i++) {
      final rowY = cardRect.top + size.height * (0.21 + i * 0.11);
      final circleCenter = Offset(cardRect.left + 26, rowY);
      if (i == 0) {
        canvas.drawCircle(circleCenter, 9, navyFill);
        final check = Path()
          ..moveTo(circleCenter.dx - 4, circleCenter.dy)
          ..lineTo(circleCenter.dx - 1, circleCenter.dy + 3)
          ..lineTo(circleCenter.dx + 4.5, circleCenter.dy - 3);
        canvas.drawPath(
          check,
          Paint()
            ..color = AppColors.onPrimary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      } else {
        canvas.drawCircle(circleCenter, 9, navyStroke);
      }

      canvas.drawLine(
        Offset(cardRect.left + 46, rowY),
        Offset(cardRect.right - 22, rowY),
        Paint()
          ..color = i == 0 ? AppColors.textMuted : AppColors.foreground
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintProgressSlide(Canvas canvas, Size size) {
    final whiteFill = Paint()..color = AppColors.background;
    final navyFill = Paint()..color = AppColors.primary;
    final trackFill = Paint()..color = AppColors.track;
    final borderPaint = Paint()
      ..color = AppColors.foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;

    // Dashboard card
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.48, size.height * 0.54),
        width: size.width * 0.54,
        height: size.height * 0.46,
      ),
      const Radius.circular(16),
    );
    canvas.drawRRect(cardRect, whiteFill);
    canvas.drawRRect(cardRect, borderPaint);

    // Rising bars (strictly grey & navy)
    const barWidths = 16.0;
    final heights = <double>[28, 44, 38, 62];
    final baseY = cardRect.bottom - 20;
    for (var i = 0; i < heights.length; i++) {
      final x = cardRect.left + 20 + i * 24;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, baseY - heights[i], barWidths, heights[i]),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(rect, i == 3 ? navyFill : trackFill);
    }

    // Floating circular progress badge top-right
    final ringCenter = Offset(size.width * 0.74, size.height * 0.30);
    canvas.drawCircle(ringCenter, 24, whiteFill);
    canvas.drawCircle(
      ringCenter,
      20,
      Paint()
        ..color = AppColors.track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    canvas.drawArc(
      Rect.fromCircle(center: ringCenter, radius: 20),
      -math.pi / 2,
      math.pi * 1.4,
      false,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_OnboardingPainter oldDelegate) =>
      oldDelegate.slideIndex != slideIndex;
}
