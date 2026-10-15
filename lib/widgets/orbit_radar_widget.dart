import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/theme.dart';

enum ScanTier {
  bottom, // 15-30 deg up
  mid,    // 0 deg horizontal
  top,    // 30-45 deg down
}

class OrbitRadarWidget extends StatelessWidget {
  final double currentAngleDegrees; // 0 to 360 (yaw)
  final double currentPitchDegrees; // tilt up/down
  final Set<int> coveredSectorsMid;
  final Set<int> coveredSectorsTop;
  final Set<int> coveredSectorsBottom;
  final ScanTier currentTier;
  final double size;

  const OrbitRadarWidget({
    super.key,
    required this.currentAngleDegrees,
    this.currentPitchDegrees = 0.0,
    required this.coveredSectorsMid,
    this.coveredSectorsTop = const {},
    this.coveredSectorsBottom = const {},
    this.currentTier = ScanTier.mid,
    this.size = 120.0,
  });

  int get totalCovered =>
      coveredSectorsMid.length + coveredSectorsTop.length + coveredSectorsBottom.length;

  // Max points: 36 (mid) + 18 (top) + 18 (bottom) = 72 target keyframes
  double get totalCoveragePercent =>
      ((totalCovered / 72.0) * 100.0).clamp(0.0, 100.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.surface.withValues(alpha: 0.88),
        border: Border.all(color: AppTheme.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 14,
            spreadRadius: 2,
          ),
          if (totalCoveragePercent >= 90)
            BoxShadow(
              color: AppTheme.emerald.withValues(alpha: 0.35),
              blurRadius: 18,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Multi-Tier Concentric Radar CustomPainter
          CustomPaint(
            size: Size(size, size),
            painter: _MultiTierRadarPainter(
              currentAngleDegrees: currentAngleDegrees,
              coveredSectorsMid: coveredSectorsMid,
              coveredSectorsTop: coveredSectorsTop,
              coveredSectorsBottom: coveredSectorsBottom,
              currentTier: currentTier,
            ),
          ),

          // Center Telemetry HUD
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${totalCoveragePercent.toInt()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: totalCoveragePercent >= 90
                          ? AppTheme.emerald
                          : AppTheme.cyan,
                    ),
              ),
              Text(
                currentTier.name.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: _tierColor(currentTier),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _tierColor(ScanTier tier) {
    switch (tier) {
      case ScanTier.top:
        return AppTheme.amber;
      case ScanTier.mid:
        return AppTheme.cyan;
      case ScanTier.bottom:
        return AppTheme.neonPurple;
    }
  }
}

class _MultiTierRadarPainter extends CustomPainter {
  final double currentAngleDegrees;
  final Set<int> coveredSectorsMid;
  final Set<int> coveredSectorsTop;
  final Set<int> coveredSectorsBottom;
  final ScanTier currentTier;

  _MultiTierRadarPainter({
    required this.currentAngleDegrees,
    required this.coveredSectorsMid,
    required this.coveredSectorsTop,
    required this.coveredSectorsBottom,
    required this.currentTier,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = (size.width / 2) - 6;

    // Three concentric rings:
    // Outer: Top Dome (radius 0.85 to 1.0)
    // Middle: Equator / Mid (radius 0.65 to 0.82)
    // Inner: Bottom Undercut (radius 0.45 to 0.62)

    _drawRing(
      canvas: canvas,
      center: center,
      innerR: maxRadius * 0.78,
      outerR: maxRadius,
      sectorsCount: 18,
      coveredSet: coveredSectorsTop,
      activeColor: AppTheme.amber,
      isActiveTier: currentTier == ScanTier.top,
    );

    _drawRing(
      canvas: canvas,
      center: center,
      innerR: maxRadius * 0.58,
      outerR: maxRadius * 0.74,
      sectorsCount: 36,
      coveredSet: coveredSectorsMid,
      activeColor: AppTheme.cyan,
      isActiveTier: currentTier == ScanTier.mid,
    );

    _drawRing(
      canvas: canvas,
      center: center,
      innerR: maxRadius * 0.38,
      outerR: maxRadius * 0.54,
      sectorsCount: 18,
      coveredSet: coveredSectorsBottom,
      activeColor: AppTheme.neonPurple,
      isActiveTier: currentTier == ScanTier.bottom,
    );

    // Camera heading arrow
    final rad = (currentAngleDegrees - 90) * (math.pi / 180.0);
    final cameraPos = Offset(
      center.dx + (maxRadius + 1) * math.cos(rad),
      center.dy + (maxRadius + 1) * math.sin(rad),
    );

    final cameraPaint = Paint()
      ..color = AppTheme.emerald
      ..style = PaintingStyle.fill;
    canvas.drawCircle(cameraPos, 4.0, cameraPaint);

    final cameraGlowPaint = Paint()
      ..color = AppTheme.emerald.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(cameraPos, 6.5, cameraGlowPaint);
  }

  void _drawRing({
    required Canvas canvas,
    required Offset center,
    required double innerR,
    required double outerR,
    required int sectorsCount,
    required Set<int> coveredSet,
    required Color activeColor,
    required bool isActiveTier,
  }) {
    final sweep = (2 * math.pi) / sectorsCount;
    const padding = 0.04;
    final strokeW = outerR - innerR;
    final arcRadius = innerR + strokeW / 2;

    for (int i = 0; i < sectorsCount; i++) {
      final isCovered = coveredSet.contains(i);
      final start = (i * sweep) - (math.pi / 2);

      final color = isCovered
          ? activeColor
          : (isActiveTier
              ? AppTheme.surfaceLight.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.08));

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..color = color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: arcRadius),
        start + padding,
        sweep - (padding * 2),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MultiTierRadarPainter oldDelegate) {
    return oldDelegate.currentAngleDegrees != currentAngleDegrees ||
        oldDelegate.coveredSectorsMid.length != coveredSectorsMid.length ||
        oldDelegate.coveredSectorsTop.length != coveredSectorsTop.length ||
        oldDelegate.coveredSectorsBottom.length != coveredSectorsBottom.length ||
        oldDelegate.currentTier != currentTier;
  }
}
