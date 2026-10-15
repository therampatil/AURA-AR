import 'package:flutter/foundation.dart';
import '../models/scan_session.dart';

class ScanRepository extends ChangeNotifier {
  static final ScanRepository instance = ScanRepository._internal();
  ScanRepository._internal() {
    _initDemoScans();
  }

  final List<ScanSession> _scans = [];

  List<ScanSession> get scans => List.unmodifiable(_scans);

  void _initDemoScans() {
    _scans.addAll([
      ScanSession(
        id: 'demo-scan-01',
        name: 'Physical Drone Prototype',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        keyframesCount: 84,
        anglesCovered: 360,
        durationSeconds: 28,
        glbUrl: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
        usdzUrl: 'https://modelviewer.dev/shared-assets/models/Astronaut.usdz',
        webarUrl: 'http://10.146.62.205:8080/?model=https%3A%2F%2Fmodelviewer.dev%2Fshared-assets%2Fmodels%2FAstronaut.glb&name=Physical+Drone+Prototype&frames=84',
        polyCount: 52400,
        fileSizeMb: 3.2,
      ),
      ScanSession(
        id: 'demo-scan-02',
        name: 'Sculpted Ceramic Vase',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
        keyframesCount: 68,
        anglesCovered: 340,
        durationSeconds: 22,
        glbUrl: 'https://modelviewer.dev/shared-assets/models/glTF-Sample-Assets/Models/SheenChair/glTF-Binary/SheenChair.glb',
        usdzUrl: 'https://modelviewer.dev/shared-assets/models/Astronaut.usdz',
        webarUrl: 'http://10.146.62.205:8080/?model=https%3A%2F%2Fmodelviewer.dev%2Fshared-assets%2Fmodels%2FglTF-Sample-Assets%2FModels%2FSheenChair%2FglTF-Binary%2FSheenChair.glb&name=Sculpted+Ceramic+Vase&frames=68',
        polyCount: 38900,
        fileSizeMb: 2.1,
      ),
    ]);
  }

  void addScan(ScanSession scan) {
    _scans.insert(0, scan);
    notifyListeners();
  }

  void deleteScan(String id) {
    _scans.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  ScanSession? getById(String id) {
    try {
      return _scans.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
