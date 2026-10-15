import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/theme.dart';
import '../models/scan_session.dart';
import '../widgets/glass_card.dart';
import '../widgets/cyber_badge.dart';
import 'qr_studio_screen.dart';

class ModelInspectorScreen extends StatefulWidget {
  final ScanSession session;

  const ModelInspectorScreen({super.key, required this.session});

  @override
  State<ModelInspectorScreen> createState() => _ModelInspectorScreenState();
}

class _ModelInspectorScreenState extends State<ModelInspectorScreen> {
  String _selectedShading = 'PBR Textured';
  final List<String> _shadingModes = ['PBR Textured', 'Wireframe', 'Point Cloud', 'Clay Normal'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          '3D MODEL INSPECTOR',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                letterSpacing: 0.5,
              ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close, color: AppTheme.textSecondary),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. 3D Interactive Viewport
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: const Color(0xFF090D16),
                  child: ModelViewer(
                    backgroundColor: const Color(0xFF090D16),
                    src: widget.session.glbUrl,
                    iosSrc: widget.session.usdzUrl,
                    alt: widget.session.name,
                    ar: true,
                    arModes: const ['scene-viewer', 'webxr', 'quick-look'],
                    autoRotate: true,
                    cameraControls: true,
                    shadowIntensity: 1.2,
                    exposure: 1.0,
                  ),
                ),

                // Controls Overlay Top
                Positioned(
                  top: 12,
                  left: 16,
                  child: CyberBadge(
                    label: '${widget.session.keyframesCount} SCAN ANGLES',
                    icon: Icons.camera_alt_outlined,
                    color: AppTheme.cyan,
                  ),
                ),

                Positioned(
                  top: 12,
                  right: 16,
                  child: CyberBadge(
                    label: '360° CLOSED MESH',
                    icon: Icons.check_circle_outline,
                    color: AppTheme.emerald,
                  ),
                ),

                // Shading Mode Selector Pills Bottom of Viewport
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _shadingModes.map((mode) {
                        final isSelected = _selectedShading == mode;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedShading = mode;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.cyan.withOpacity(0.2)
                                    : AppTheme.surface.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? AppTheme.cyan : Colors.white12,
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                mode,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppTheme.cyan : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Model Specs & Actions Section
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Date
                  Text(
                    widget.session.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                        ),
                  ),
                  Text(
                    widget.session.formattedDate,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 16),

                  // Specs Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildSpecCard('POLYGONS', '${widget.session.polyCount ~/ 1000}k Tris'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSpecCard('TEXTURES', '2K Metallic PBR'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSpecCard('FILE SIZE', '${widget.session.fileSizeMb} MB'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Main CTA: Generate QR Code for Instant WebAR Sharing
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cyan,
                        foregroundColor: const Color(0xFF090D16),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: AppTheme.cyan.withOpacity(0.5),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => QRStudioScreen(session: widget.session),
                          ),
                        );
                      },
                      icon: const Icon(Icons.qr_code_2_rounded, size: 24),
                      label: const Text(
                        'GENERATE AR QR CODE & SHARE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // In-App Direct AR View Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.cyan,
                        side: const BorderSide(color: AppTheme.cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        final uri = Uri.parse(widget.session.webarUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.view_in_ar, size: 20),
                      label: const Text(
                        'PLACE OBJECT IN ROOM (AR)',
                        style: TextStyle(
                          fontSize: 13,
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
        ],
      ),
    );
  }

  Widget _buildSpecCard(String label, String value) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      borderRadius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 9,
                  color: AppTheme.textMuted,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 12,
                  color: AppTheme.cyan,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
