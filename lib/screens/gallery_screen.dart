import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../services/scan_repository.dart';
import '../widgets/glass_card.dart';
import '../widgets/cyber_badge.dart';
import 'model_inspector_screen.dart';
import 'qr_studio_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final repo = ScanRepository.instance;

  @override
  void initState() {
    super.initState();
    repo.addListener(_onRepoChanged);
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    repo.removeListener(_onRepoChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scans = repo.scans;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'SPATIAL AR LIBRARY',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                letterSpacing: 0.5,
              ),
        ),
      ),
      body: scans.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.view_in_ar_outlined, size: 64, color: AppTheme.cyan.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No Scans Saved Yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Point your camera at an object and start scanning!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: scans.length,
              itemBuilder: (context, index) {
                final scan = scans[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ModelInspectorScreen(session: scan),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        // 3D Model Thumbnail Badge
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.cyan.withOpacity(0.2),
                                AppTheme.neonPurple.withOpacity(0.2),
                              ],
                            ),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: const Icon(
                            Icons.view_in_ar_rounded,
                            size: 32,
                            color: AppTheme.cyan,
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Scan Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                scan.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                scan.formattedDate,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  CyberBadge(
                                    label: '${scan.keyframesCount} ANGLES',
                                    color: AppTheme.cyan,
                                  ),
                                  const SizedBox(width: 6),
                                  CyberBadge(
                                    label: '${scan.polyCount ~/ 1000}K POLYS',
                                    color: AppTheme.neonPurple,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Instant QR Shortcut
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => QRStudioScreen(session: scan),
                              ),
                            );
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.surfaceLight,
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: const Icon(
                              Icons.qr_code_2_rounded,
                              size: 20,
                              color: AppTheme.cyan,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
