import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/point_cloud_point.dart';

class PointCloudOverlay extends StatelessWidget {
  final List<PointCloudPoint> points;
  final double currentAngleDegrees;

  const PointCloudOverlay({
    super.key,
    required this.points,
    required this.currentAngleDegrees,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _PointCloudPainter(
        points: points,
        currentAngleDegrees: currentAngleDegrees,
      ),
    );
  }
}

class _PointCloudPainter extends CustomPainter {
  final List<PointCloudPoint> points;
  final double currentAngleDegrees;

  _PointCloudPainter({
    required this.points,
    required this.currentAngleDegrees,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final scale = math.min(size.width, size.height) * 0.35;
    final rad = currentAngleDegrees * (math.pi / 180.0);
    final cosA = math.cos(rad);
    final sinA = math.sin(rad);

    for (final point in points) {
      // 3D Rotation around Y axis
      final rotX = point.x * cosA - point.z * sinA;
      final rotZ = point.x * sinA + point.z * cosA;
      final rotY = point.y;

      // Perspective projection
      final distance = 2.5 + rotZ;
      if (distance <= 0.1) continue;

      final projX = center.dx + (rotX / distance) * scale;
      final projY = center.dy + (rotY / distance) * scale;

      // Depth fading
      final depthAlpha = ((1.0 - (rotZ / 2.0)).clamp(0.2, 1.0) * point.opacity).clamp(0.0, 1.0);
      final depthRadius = ((point.radius / distance) * 2.2).clamp(1.0, 5.0);

      final paint = Paint()
        ..color = point.color.withOpacity(depthAlpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(projX, projY), depthRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PointCloudPainter oldDelegate) {
    return oldDelegate.points.length != points.length ||
        oldDelegate.currentAngleDegrees != currentAngleDegrees;
  }
}
