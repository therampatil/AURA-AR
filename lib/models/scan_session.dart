import 'package:intl/intl.dart';

enum ScanStatus {
  capturing,
  reconstructing,
  completed,
  failed,
}

class ScanSession {
  final String id;
  final String name;
  final DateTime createdAt;
  final int keyframesCount;
  final int anglesCovered; // 0 to 360 degrees
  final int durationSeconds;
  final String glbUrl;
  final String usdzUrl;
  final String webarUrl;
  final int polyCount;
  final double fileSizeMb;
  final ScanStatus status;
  final String? thumbnailPath;

  ScanSession({
    required this.id,
    required this.name,
    required this.createdAt,
    this.keyframesCount = 0,
    this.anglesCovered = 0,
    this.durationSeconds = 0,
    this.glbUrl = '',
    this.usdzUrl = '',
    this.webarUrl = '',
    this.polyCount = 48200,
    this.fileSizeMb = 2.8,
    this.status = ScanStatus.completed,
    this.thumbnailPath,
  });

  double get coveragePercent => (anglesCovered / 360.0).clamp(0.0, 1.0) * 100.0;

  String get formattedDate => DateFormat('MMM dd, yyyy • HH:mm').format(createdAt);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'keyframesCount': keyframesCount,
        'anglesCovered': anglesCovered,
        'durationSeconds': durationSeconds,
        'glbUrl': glbUrl,
        'usdzUrl': usdzUrl,
        'webarUrl': webarUrl,
        'polyCount': polyCount,
        'fileSizeMb': fileSizeMb,
        'status': status.name,
        'thumbnailPath': thumbnailPath,
      };

  factory ScanSession.fromJson(Map<String, dynamic> json) {
    return ScanSession(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      keyframesCount: json['keyframesCount'] as int? ?? 0,
      anglesCovered: json['anglesCovered'] as int? ?? 0,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      glbUrl: json['glbUrl'] as String? ?? '',
      usdzUrl: json['usdzUrl'] as String? ?? '',
      webarUrl: json['webarUrl'] as String? ?? '',
      polyCount: json['polyCount'] as int? ?? 48200,
      fileSizeMb: (json['fileSizeMb'] as num?)?.toDouble() ?? 2.8,
      status: ScanStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ScanStatus.completed,
      ),
      thumbnailPath: json['thumbnailPath'] as String?,
    );
  }

  ScanSession copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    int? keyframesCount,
    int? anglesCovered,
    int? durationSeconds,
    String? glbUrl,
    String? usdzUrl,
    String? webarUrl,
    int? polyCount,
    double? fileSizeMb,
    ScanStatus? status,
    String? thumbnailPath,
  }) {
    return ScanSession(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      keyframesCount: keyframesCount ?? this.keyframesCount,
      anglesCovered: anglesCovered ?? this.anglesCovered,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      glbUrl: glbUrl ?? this.glbUrl,
      usdzUrl: usdzUrl ?? this.usdzUrl,
      webarUrl: webarUrl ?? this.webarUrl,
      polyCount: polyCount ?? this.polyCount,
      fileSizeMb: fileSizeMb ?? this.fileSizeMb,
      status: status ?? this.status,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
}
