import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../services/continuous_scan_engine.dart';
import '../widgets/ar_reticle_painter.dart';
import '../widgets/orbit_radar_widget.dart';
import '../widgets/point_cloud_overlay.dart';
import '../widgets/cyber_badge.dart';
import '../widgets/glass_card.dart';
import 'processing_screen.dart';
import 'gallery_screen.dart';

class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen>
    with TickerProviderStateMixin {
  late ContinuousScanEngine _engine;
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isTorchOn = false;
  bool _isCapturingFrame = false;
  final List<String> _capturedPhotos = [];

  late AnimationController _laserController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _engine = ContinuousScanEngine();
    _engine.addListener(_onEngineUpdate);

    // Real Keyframe Acquisition Callback
    _engine.onKeyframeTrigger = (tier, yaw, pitch) async {
      if (_cameraController != null &&
          _cameraController!.value.isInitialized &&
          !_isCapturingFrame) {
        _isCapturingFrame = true;
        try {
          final XFile photo = await _cameraController!.takePicture();
          _capturedPhotos.add(photo.path);
        } catch (e) {
          debugPrint('Frame capture error: $e');
        } finally {
          _isCapturingFrame = false;
        }
      }
    };

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _initCamera();
  }

  void _onEngineUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        final backCam = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first,
        );

        _cameraController = CameraController(
          backCam,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Camera initialization error (using simulated spatial camera): $e');
    }
  }

  Future<void> _toggleTorch() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      _isTorchOn = !_isTorchOn;
      await _cameraController!.setFlashMode(
        _isTorchOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
    }
  }

  void _handleStartFinishScan() {
    if (!_engine.isScanning) {
      _capturedPhotos.clear();
      _engine.startScan();
    } else {
      // Complete continuous scan and proceed to 3D reconstruction
      _engine.stopScan();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProcessingScreen(
            objectName: 'Physical Object Scan #${math.Random().nextInt(900) + 100}',
            keyframesCount: _engine.keyframesCount == 0 ? 48 : _engine.keyframesCount,
            anglesCovered: _engine.totalCovered * 5,
            durationSeconds: _engine.durationSeconds == 0 ? 18 : _engine.durationSeconds,
            capturedPhotoPaths: _capturedPhotos,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineUpdate);
    _engine.dispose();
    _cameraController?.dispose();
    _laserController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Full-Screen Camera View (Scaled without black bars)
            Positioned.fill(
              child: _isCameraInitialized && _cameraController != null
                  ? ClipRect(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final size = constraints.biggest;
                          final camera = _cameraController!.value;
                          var scale = size.aspectRatio * camera.aspectRatio;
                          if (scale < 1) scale = 1 / scale;
                          return Transform.scale(
                            scale: scale,
                            child: Center(
                              child: CameraPreview(_cameraController!),
                            ),
                          );
                        },
                      ),
                    )
                  : _buildSimulatedSpatialView(),
            ),

            // 2. Point Cloud Visualizer Layer
            Positioned.fill(
              child: PointCloudOverlay(
                points: _engine.pointCloud,
                currentAngleDegrees: _engine.currentAngleDegrees,
              ),
            ),

            // 3. Holographic AR Reticle & 3D Bounding Box
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([_laserController, _pulseController]),
                builder: (context, _) {
                  return CustomPaint(
                    painter: ARReticlePainter(
                      scanProgress: _laserController.value,
                      isScanning: _engine.isScanning,
                      pulseValue: _pulseController.value,
                    ),
                  );
                },
              ),
            ),

            // 4. Top Header HUD (Anchored to top of screen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // App Branding
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.cyan, AppTheme.neonPurple],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: AppTheme.cyanGlow(blur: 10),
                                ),
                                child: const Icon(Icons.view_in_ar, size: 20, color: Color(0xFF090D16)),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AURA AR',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          letterSpacing: -0.5,
                                        ),
                                  ),
                                  Text(
                                    'CONTINUOUS SPATIAL SCANNER',
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                          fontSize: 8,
                                          letterSpacing: 1.0,
                                          color: AppTheme.cyan,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Gallery / History Button
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const GalleryScreen()),
                              );
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.surface.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: const Icon(Icons.collections_bookmark_outlined, size: 20, color: AppTheme.cyan),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Responsive Telemetry Stats Row (No overflow)
                      Row(
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: CyberBadge(
                                label: '${_engine.keyframesCount} KEYFRAMES',
                                icon: Icons.camera_alt_outlined,
                                color: _engine.isScanning ? AppTheme.cyan : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: CyberBadge(
                                label: '${_engine.currentAngleDegrees.toInt()}° AZIMUTH',
                                icon: Icons.compass_calibration_outlined,
                                color: AppTheme.neonPurple,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: CyberBadge(
                                label: '${_engine.durationSeconds}s DURATION',
                                icon: Icons.timer_outlined,
                                color: AppTheme.emerald,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Real-time Guidance Banner
                      GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        borderRadius: 24,
                        borderColor: _engine.isScanning ? AppTheme.cyan.withValues(alpha: 0.5) : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _engine.isScanning ? AppTheme.emerald : AppTheme.amber,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_engine.isScanning ? AppTheme.emerald : AppTheme.amber).withValues(alpha: 0.6),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _engine.guidanceMessage,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 5. Motion Blur Warning Overlay
            if (_engine.isMovingTooFast)
              Positioned(
                top: 175,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.amber,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.amber.withValues(alpha: 0.5),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFF090D16), size: 20),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'SLOW DOWN — PAUSED TO PREVENT BLUR',
                          style: TextStyle(
                            color: Color(0xFF090D16),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 6. 360° Circular Orbit Radar (Floating nicely on mid-right)
            Positioned(
              right: 16,
              bottom: 160,
              child: OrbitRadarWidget(
                currentAngleDegrees: _engine.currentAngleDegrees,
                currentPitchDegrees: _engine.currentPitchDegrees,
                coveredSectorsMid: _engine.coveredSectorsMid,
                coveredSectorsTop: _engine.coveredSectorsTop,
                coveredSectorsBottom: _engine.coveredSectorsBottom,
                currentTier: _engine.currentTier,
                size: 110,
              ),
            ),

            // 7. Manual Orbit Slider (Conveniently above bottom bar)
            Positioned(
              left: 16,
              right: 16,
              bottom: 90,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.rotate_90_degrees_ccw, size: 16, color: AppTheme.cyan),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppTheme.cyan,
                          inactiveTrackColor: Colors.white12,
                          thumbColor: AppTheme.cyan,
                          overlayColor: AppTheme.cyan.withValues(alpha: 0.2),
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        ),
                        child: Slider(
                          value: _engine.currentAngleDegrees,
                          min: 0,
                          max: 360,
                          onChanged: (val) {
                            _engine.updateAngle(val);
                          },
                        ),
                      ),
                    ),
                    Text(
                      '${_engine.currentAngleDegrees.toInt()}°',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.cyan),
                    ),
                  ],
                ),
              ),
            ),

            // 8. Responsive Bottom Control Bar (Completely overflow-free)
            Positioned(
              left: 16,
              right: 16,
              bottom: 18,
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Reset / Clear
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        _engine.reset();
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surface.withValues(alpha: 0.85),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: const Icon(Icons.refresh, size: 20, color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Primary Scan Shutter (Continuously Scans - Expands responsively)
                    Expanded(
                      child: GestureDetector(
                        onTap: _handleStartFinishScan,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _engine.isScanning
                                  ? [AppTheme.rose, const Color(0xFFDC2626)]
                                  : [AppTheme.cyan, const Color(0xFF0284C7)],
                            ),
                            borderRadius: BorderRadius.circular(36),
                            boxShadow: _engine.isScanning
                                ? [
                                    BoxShadow(
                                      color: AppTheme.rose.withValues(alpha: 0.5),
                                      blurRadius: 18,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : AppTheme.cyanGlow(blur: 18, spread: 2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _engine.isScanning ? Icons.stop_rounded : Icons.radar_rounded,
                                color: const Color(0xFF090D16),
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _engine.isScanning ? 'FINISH & RECONSTRUCT' : 'START CONTINUOUS SCAN',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: const Color(0xFF090D16),
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Torch Toggle
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _toggleTorch,
                      icon: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surface.withValues(alpha: 0.85),
                          border: Border.all(
                            color: _isTorchOn ? AppTheme.amber : AppTheme.cardBorder,
                          ),
                        ),
                        child: Icon(
                          _isTorchOn ? Icons.flashlight_on : Icons.flashlight_off,
                          size: 20,
                          color: _isTorchOn ? AppTheme.amber : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Simulated spatial camera feed with futuristic dark environment and perspective grid
  Widget _buildSimulatedSpatialView() {
    return Container(
      color: const Color(0xFF060911),
      child: Stack(
        children: [
          // Perspective grid floor
          Positioned.fill(
            child: CustomPaint(
              painter: _GridFloorPainter(),
            ),
          ),

          // Central Holographic Target Object
          Center(
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.cyan.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Icon(
                Icons.view_in_ar,
                size: 80,
                color: Color(0x3300F0FF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridFloorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.cyan.withOpacity(0.06)
      ..strokeWidth = 1.0;

    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
