import 'package:flutter/material.dart';

class PointCloudPoint {
  final double x;
  final double y;
  final double z;
  final Color color;
  final double radius;
  final double opacity;

  PointCloudPoint({
    required this.x,
    required this.y,
    required this.z,
    required this.color,
    this.radius = 2.0,
    this.opacity = 0.8,
  });
}
