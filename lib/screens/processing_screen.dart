import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../services/reconstruction_pipeline.dart';
import '../services/scan_repository.dart';
import '../widgets/glass_card.dart';
import 'model_inspector_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final String objectName;
  final int keyframesCount;
  final int anglesCovered;
  final int durationSeconds;
  final List<String> capturedPhotoPaths;

  const ProcessingScreen({
    super.key,
    required this.objectName,
    required this.keyframesCount,
    required this.anglesCovered,
    required this.durationSeconds,
    this.capturedPhotoPaths = const [],
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  int _currentStepIndex = 0;
  double _progress = 0.05;
  String _currentStepTitle = 'Initializing Photogrammetry Pipeline...';
  String _currentStepDetail = 'Calibrating multi-view spatial telemetry...';

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _startPipeline();
  }

  Future<void> _startPipeline() async {
    final stream = ReconstructionPipeline.runPipeline(
      objectName: widget.objectName,
      keyframesCount: widget.keyframesCount,
      anglesCovered: widget.anglesCovered,
      durationSeconds: widget.durationSeconds,
      capturedPhotoPaths: widget.capturedPhotoPaths,
    );

    int stepIdx = 0;
    await for (final step in stream) {
      if (mounted) {
        setState(() {
          _currentStepIndex = stepIdx;
          _progress = step.progress;
          _currentStepTitle = step.title;
          _currentStepDetail = step.detail;
        });
        stepIdx++;
      }
    }

    // Finalize session with WebAR server and upload real photos
    final completedSession = await ReconstructionPipeline.finalizeScan(
      objectName: widget.objectName,
      keyframesCount: widget.keyframesCount,
      anglesCovered: widget.anglesCovered,
      durationSeconds: widget.durationSeconds,
      capturedPhotoPaths: widget.capturedPhotoPaths,
    );

    // Save to repository
    ScanRepository.instance.addScan(completedSession);

    if (mounted) {
      // Transition to 3D Model Inspector
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ModelInspectorScreen(session: completedSession),
        ),
      );
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Top Title
              Text(
                'NEURAL 3D RECONSTRUCTION',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      letterSpacing: 1.5,
                      color: AppTheme.cyan,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.objectName,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 20,
                    ),
              ),

              const Spacer(),

              // Animated 3D Holographic Wireframe
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, _) {
                  return CustomPaint(
                    size: const Size(200, 200),
                    painter: _HologramWireframePainter(
                      angle: _rotationController.value * 2 * math.pi,
                      progress: _progress,
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Progress Bar & Percentage
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'BUILDING 3D MESH',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          letterSpacing: 1.0,
                        ),
                  ),
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.cyan,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 6,
                  backgroundColor: AppTheme.surfaceLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.cyan),
                ),
              ),

              const Spacer(),

              // Pipeline Stage Card
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.cyan,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentStepTitle,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.cyan.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.cyan.withOpacity(0.3)),
                          ),
                          child: Text(
                            'STEP ${_currentStepIndex + 1}/5',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.cyan,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _currentStepDetail,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Telemetry Specs footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('KEYFRAMES', '${widget.keyframesCount}'),
                  _buildStatItem('ORBIT COVERAGE', '${widget.anglesCovered}°'),
                  _buildStatItem('CAPTURE DURATION', '${widget.durationSeconds}s'),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.cyan,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontSize: 9,
                color: AppTheme.textMuted,
              ),
        ),
      ],
    );
  }
}

class _HologramWireframePainter extends CustomPainter {
  final double angle;
  final double progress;

  _HologramWireframePainter({required this.angle, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;

    // Glowing outer radar rings
    final ringPaint = Paint()
      ..color = AppTheme.cyan.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius * 1.15, ringPaint);
    canvas.drawCircle(center, radius * 0.85, ringPaint);

    // 3D Rotating Cube Vertices
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    final cosB = math.cos(angle * 0.6);
    final sinB = math.sin(angle * 0.6);

    final rawVertices = [
      [-1.0, -1.0, -1.0],
      [1.0, -1.0, -1.0],
      [1.0, 1.0, -1.0],
      [-1.0, 1.0, -1.0],
      [-1.0, -1.0, 1.0],
      [1.0, -1.0, 1.0],
      [1.0, 1.0, 1.0],
      [-1.0, 1.0, 1.0],
    ];

    final projected = <Offset>[];

    for (final v in rawVertices) {
      // Rotation Y
      final x1 = v[0] * cosA - v[2] * sinA;
      final z1 = v[0] * sinA + v[2] * cosA;

      // Rotation X
      final y2 = v[1] * cosB - z1 * sinB;
      final z2 = v[1] * sinB + z1 * cosB;

      final distance = 2.8 + z2;
      final px = center.dx + (x1 / distance) * radius;
      final py = center.dy + (y2 / distance) * radius;
      projected.add(Offset(px, py));
    }

    // Connect edges
    final edges = [
      [0, 1], [1, 2], [2, 3], [3, 0], // back
      [4, 5], [5, 6], [6, 7], [7, 4], // front
      [0, 4], [1, 5], [2, 6], [3, 7], // connectors
    ];

    final edgePaint = Paint()
      ..color = AppTheme.cyan.withOpacity(0.4 + 0.5 * progress)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    for (final edge in edges) {
      canvas.drawLine(projected[edge[0]], projected[edge[1]], edgePaint);
    }

    // Vertex dots
    final vertexPaint = Paint()
      ..color = AppTheme.neonPurple
      ..style = PaintingStyle.fill;

    for (final p in projected) {
      canvas.drawCircle(p, 3.5, vertexPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HologramWireframePainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.progress != progress;
  }
}
