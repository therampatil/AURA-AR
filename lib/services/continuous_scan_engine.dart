import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/point_cloud_point.dart';
import '../constants/theme.dart';
import '../widgets/orbit_radar_widget.dart';

typedef KeyframeCaptureCallback = Future<void> Function(ScanTier tier, double yaw, double pitch);

class ContinuousScanEngine extends ChangeNotifier {
  bool _isScanning = false;
  double _currentAngleDegrees = 0.0; // Yaw (0-360)
  double _currentPitchDegrees = 0.0; // Pitch (-90 to +90)

  // Multi-Tier coverage sets for precision photogrammetry
  final Set<int> _coveredSectorsMid = {};    // 36 sectors (10 deg each)
  final Set<int> _coveredSectorsTop = {};    // 18 sectors (20 deg each)
  final Set<int> _coveredSectorsBottom = {}; // 18 sectors (20 deg each)

  int _keyframesCount = 0;
  int _durationSeconds = 0;
  Timer? _timer;
  StreamSubscription? _gyroSub;
  StreamSubscription? _accelSub;

  final List<PointCloudPoint> _pointCloud = [];
  double _lastCapturedAngle = -999.0;
  ScanTier _currentTier = ScanTier.mid;
  String _guidanceMessage = 'Align object within box & begin orbit';
  bool _isMovingTooFast = false;
  double _angularSpeed = 0.0;

  KeyframeCaptureCallback? onKeyframeTrigger;

  // Getters
  bool get isScanning => _isScanning;
  double get currentAngleDegrees => _currentAngleDegrees;
  double get currentPitchDegrees => _currentPitchDegrees;
  Set<int> get coveredSectorsMid => _coveredSectorsMid;
  Set<int> get coveredSectorsTop => _coveredSectorsTop;
  Set<int> get coveredSectorsBottom => _coveredSectorsBottom;
  ScanTier get currentTier => _currentTier;
  int get keyframesCount => _keyframesCount;
  int get durationSeconds => _durationSeconds;
  List<PointCloudPoint> get pointCloud => List.unmodifiable(_pointCloud);
  String get guidanceMessage => _guidanceMessage;
  bool get isMovingTooFast => _isMovingTooFast;
  double get angularSpeed => _angularSpeed;

  int get totalCovered =>
      _coveredSectorsMid.length + _coveredSectorsTop.length + _coveredSectorsBottom.length;

  double get coveragePercent => ((totalCovered / 72.0) * 100.0).clamp(0.0, 100.0);

  void startScan() {
    _isScanning = true;
    _coveredSectorsMid.clear();
    _coveredSectorsTop.clear();
    _coveredSectorsBottom.clear();
    _pointCloud.clear();
    _keyframesCount = 0;
    _durationSeconds = 0;
    _currentAngleDegrees = 0.0;
    _currentPitchDegrees = 0.0;
    _lastCapturedAngle = -999.0;
    _currentTier = ScanTier.mid;
    _guidanceMessage = 'Ring 1: Orbit horizontally around object (Eye Level)';

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _durationSeconds++;
      notifyListeners();
    });

    _initSensors();
    _recordKeyframeAtAngle(0.0, 0.0, ScanTier.mid);
    notifyListeners();
  }

  void _initSensors() {
    try {
      _gyroSub?.cancel();
      _gyroSub = gyroscopeEventStream().listen((GyroscopeEvent event) {
        if (!_isScanning) return;

        _angularSpeed = event.z.abs();
        _isMovingTooFast = _angularSpeed > 1.8;

        if (_isMovingTooFast) {
          _guidanceMessage = 'SLOW DOWN — Reducing motion blur for sharp scan';
          notifyListeners();
          return;
        }

        // Integrate yaw rotation
        final double deltaDeg = (event.z * 180.0 / math.pi) * 0.05;
        if (deltaDeg.abs() > 0.05) {
          updateYawAndPitch(_currentAngleDegrees + deltaDeg, _currentPitchDegrees);
        }
      }, onError: (err) {
        debugPrint('Gyroscope error: $err');
      });

      // Track pitch tilt via accelerometer
      _accelSub?.cancel();
      _accelSub = accelerometerEventStream().listen((AccelerometerEvent event) {
        if (!_isScanning) return;
        // Pitch calculation in degrees
        final double pitch = math.atan2(-event.y, math.sqrt(event.x * event.x + event.z * event.z)) * (180.0 / math.pi);
        _currentPitchDegrees = pitch;
        _updateTierFromPitch(pitch);
      }, onError: (err) {
        debugPrint('Accelerometer error: $err');
      });
    } catch (e) {
      debugPrint('Sensors unavailable: $e');
    }
  }

  void _updateTierFromPitch(double pitch) {
    if (pitch > 22.0) {
      _currentTier = ScanTier.top;
    } else if (pitch < -18.0) {
      _currentTier = ScanTier.bottom;
    } else {
      _currentTier = ScanTier.mid;
    }
  }

  void updateAngle(double newYaw) {
    updateYawAndPitch(newYaw, _currentPitchDegrees);
  }

  void updateYawAndPitch(double newYaw, double newPitch) {
    _currentAngleDegrees = (newYaw % 360.0);
    if (_currentAngleDegrees < 0) _currentAngleDegrees += 360.0;
    _currentPitchDegrees = newPitch;
    _updateTierFromPitch(newPitch);

    if (_isScanning && !_isMovingTooFast) {
      bool isNewSector = false;
      if (_currentTier == ScanTier.mid) {
        final idx = (_currentAngleDegrees / 10.0).floor() % 36;
        isNewSector = _coveredSectorsMid.add(idx);
      } else if (_currentTier == ScanTier.top) {
        final idx = (_currentAngleDegrees / 20.0).floor() % 18;
        isNewSector = _coveredSectorsTop.add(idx);
      } else {
        final idx = (_currentAngleDegrees / 20.0).floor() % 18;
        isNewSector = _coveredSectorsBottom.add(idx);
      }

      final double diff = (_currentAngleDegrees - _lastCapturedAngle).abs();
      final double delta = diff > 180 ? 360 - diff : diff;

      if (delta >= 8.0 || isNewSector) {
        _recordKeyframeAtAngle(_currentAngleDegrees, _currentPitchDegrees, _currentTier);
      }

      _updateMultiTierGuidance();
    }

    notifyListeners();
  }

  void _recordKeyframeAtAngle(double yaw, double pitch, ScanTier tier) {
    _lastCapturedAngle = yaw;
    _keyframesCount++;

    // Fire external callback to trigger real camera shutter
    onKeyframeTrigger?.call(tier, yaw, pitch);

    // Add 3D Point Cloud particles
    final rad = yaw * (math.pi / 180.0);
    final random = math.Random();
    final int pointsToAdd = 6 + random.nextInt(5);

    double baseY = 0.0;
    if (tier == ScanTier.top) baseY = 0.35;
    if (tier == ScanTier.bottom) baseY = -0.35;

    for (int i = 0; i < pointsToAdd; i++) {
      final r = 0.45 + (random.nextDouble() * 0.3);
      final theta = rad + ((random.nextDouble() - 0.5) * 0.25);
      final y = baseY + (-0.2 + random.nextDouble() * 0.4);

      final x = r * math.sin(theta);
      final z = r * math.cos(theta);

      Color color = AppTheme.cyan;
      if (tier == ScanTier.top) color = AppTheme.amber;
      if (tier == ScanTier.bottom) color = AppTheme.neonPurple;

      _pointCloud.add(
        PointCloudPoint(
          x: x,
          y: y,
          z: z,
          color: color,
          radius: 1.8 + random.nextDouble() * 1.5,
          opacity: 0.9,
        ),
      );
    }
  }

  void _updateMultiTierGuidance() {
    final midPercent = (_coveredSectorsMid.length / 36.0) * 100.0;
    final topPercent = (_coveredSectorsTop.length / 18.0) * 100.0;
    final bottomPercent = (_coveredSectorsBottom.length / 18.0) * 100.0;

    if (midPercent < 75.0) {
      _guidanceMessage = 'Ring 1: Orbit horizontally (${midPercent.toInt()}% mid coverage)';
    } else if (topPercent < 60.0) {
      _guidanceMessage = 'Ring 2: Tilt camera down ~35° to scan top surface';
    } else if (bottomPercent < 50.0) {
      _guidanceMessage = 'Ring 3: Tilt camera up ~20° to capture undercuts';
    } else if (coveragePercent >= 90.0) {
      _guidanceMessage = 'Full 3D Hull Captured! Tap Finish to Reconstruct';
    } else {
      _guidanceMessage = 'Orbit complete: Filling remaining spatial gaps';
    }
  }

  void stopScan() {
    _isScanning = false;
    _timer?.cancel();
    _gyroSub?.cancel();
    _accelSub?.cancel();
    notifyListeners();
  }

  void reset() {
    stopScan();
    _coveredSectorsMid.clear();
    _coveredSectorsTop.clear();
    _coveredSectorsBottom.clear();
    _pointCloud.clear();
    _keyframesCount = 0;
    _durationSeconds = 0;
    _currentAngleDegrees = 0.0;
    _currentPitchDegrees = 0.0;
    _lastCapturedAngle = -999.0;
    _currentTier = ScanTier.mid;
    _guidanceMessage = 'Align object within box & begin orbit';
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gyroSub?.cancel();
    _accelSub?.cancel();
    super.dispose();
  }
}
