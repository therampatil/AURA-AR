import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/theme.dart';

class ARReticlePainter extends CustomPainter {
  final double scanProgress; // 0.0 to 1.0 (for laser animation)
  final bool isScanning;
  final double pulseValue;

  ARReticlePainter({
    required this.scanProgress,
    required this.isScanning,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final boxSize = math.min(size.width, size.height) * 0.62;
    final rect = Rect.fromCenter(center: center, width: boxSize, height: boxSize);

    final cyanColor = isScanning ? AppTheme.cyan : AppTheme.textSecondary;
    final bracketColor = isScanning ? AppTheme.cyan : Colors.white70;

    // 1. Draw glowing corner brackets
    final bracketPaint = Paint()
      ..color = bracketColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final bracketLength = boxSize * 0.18;

    // Top-Left
    canvas.drawLine(Offset(rect.left, rect.top + bracketLength), Offset(rect.left, rect.top), bracketPaint);
    canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left + bracketLength, rect.top), bracketPaint);

    // Top-Right
    canvas.drawLine(Offset(rect.right - bracketLength, rect.top), Offset(rect.right, rect.top), bracketPaint);
    canvas.drawLine(Offset(rect.right, rect.top), Offset(rect.right, rect.top + bracketLength), bracketPaint);

    // Bottom-Left
    canvas.drawLine(Offset(rect.left, rect.bottom - bracketLength), Offset(rect.left, rect.bottom), bracketPaint);
    canvas.drawLine(Offset(rect.left, rect.bottom), Offset(rect.left + bracketLength, rect.bottom), bracketPaint);

    // Bottom-Right
    canvas.drawLine(Offset(rect.right - bracketLength, rect.bottom), Offset(rect.right, rect.bottom), bracketPaint);
    canvas.drawLine(Offset(rect.right, rect.bottom), Offset(rect.right, rect.bottom - bracketLength), bracketPaint);

    // 2. Subtle bounding box border
    final boxBorderPaint = Paint()
      ..color = cyanColor.withOpacity(isScanning ? 0.25 : 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(rect, boxBorderPaint);

    // 3. Center Crosshair
    final crossPaint = Paint()
      ..color = cyanColor.withOpacity(0.6)
      ..strokeWidth = 1.5;
    const crossSize = 10.0;
    canvas.drawLine(Offset(center.dx - crossSize, center.dy), Offset(center.dx + crossSize, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy - crossSize), Offset(center.dx, center.dy + crossSize), crossPaint);

    // Center circular reticle
    final centerCirclePaint = Paint()
      ..color = cyanColor.withOpacity(0.4 + 0.3 * pulseValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, 18.0 + 4.0 * pulseValue, centerCirclePaint);

    // 4. Moving Laser Scan Line (when scanning)
    if (isScanning) {
      final laserY = rect.top + (rect.height * scanProgress);

      // Laser Glow gradient
      final laserGlowPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.cyan.withOpacity(0.0),
            AppTheme.cyan.withOpacity(0.25),
            AppTheme.cyan.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(rect.left, laserY - 18, rect.width, 36));

      canvas.drawRect(Rect.fromLTWH(rect.left, laserY - 18, rect.width, 36), laserGlowPaint);

      // Sharp core laser line
      final laserLinePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            AppTheme.cyan.withOpacity(0.0),
            AppTheme.cyan,
            Colors.white,
            AppTheme.cyan,
            AppTheme.cyan.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(rect.left, laserY, rect.width, 2))
        ..strokeWidth = 2.0;

      canvas.drawLine(Offset(rect.left, laserY), Offset(rect.right, laserY), laserLinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant ARReticlePainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress ||
        oldDelegate.isScanning != isScanning ||
        oldDelegate.pulseValue != pulseValue;
  }
}
