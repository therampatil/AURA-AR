import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/theme.dart';
import '../models/scan_session.dart';
import '../widgets/glass_card.dart';
import '../widgets/cyber_badge.dart';

class QRStudioScreen extends StatelessWidget {
  final ScanSession session;

  const QRStudioScreen({super.key, required this.session});

  Future<void> _launchWebAR(BuildContext context) async {
    final uri = Uri.parse(session.webarUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open: ${session.webarUrl}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching browser: $e')),
        );
      }
    }
  }

  void _copyUrl(BuildContext context) {
    Clipboard.setData(ClipboardData(text: session.webarUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.cyan),
        ),
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: AppTheme.cyan, size: 20),
            SizedBox(width: 10),
            Text('WebAR link copied to clipboard!', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  void _shareLink() {
    Share.share(
      'View "${session.name}" in Augmented Reality (AR)!\nScan or open this link:\n${session.webarUrl}',
      subject: 'AR 3D Model: ${session.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'AR QR CODE STUDIO',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                letterSpacing: 0.5,
              ),
        ),
        actions: [
          IconButton(
            onPressed: () => _copyUrl(context),
            icon: const Icon(Icons.copy, color: AppTheme.cyan),
            tooltip: 'Copy Link',
          ),
          IconButton(
            onPressed: _shareLink,
            icon: const Icon(Icons.share, color: AppTheme.textPrimary),
            tooltip: 'Share',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          children: [
            // 1. The AR QR Code Card
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF10192D),
                    Color(0xFF090D16),
                  ],
                ),
                border: Border.all(
                  color: AppTheme.cyan.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.cyan.withOpacity(0.2),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Header badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.cyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.view_in_ar, size: 16, color: AppTheme.cyan),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AURA AR PASS',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  letterSpacing: 1.2,
                                  color: AppTheme.cyan,
                                ),
                          ),
                        ],
                      ),
                      const CyberBadge(
                        label: 'UNIVERSAL WEBAR',
                        color: AppTheme.emerald,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // High-Contrast QR Code
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: session.webarUrl,
                      version: QrVersions.auto,
                      size: 210.0,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF090D16),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF090D16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Object Metadata
                  Text(
                    session.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scanned via Continuous Orbit (${session.keyframesCount} Keyframes)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Universal AR Instructions (No App Required!)
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.qr_code_scanner, size: 18, color: AppTheme.cyan),
                      const SizedBox(width: 8),
                      Text(
                        'HOW TO VIEW THIS AR OBJECT',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPlatformGuide(
                    platform: 'Apple iPhone / iPad',
                    description: 'Open native Camera app -> Scan QR -> Instant AR Quick Look (USDZ).',
                    icon: Icons.apple,
                  ),
                  const Divider(color: Colors.white10, height: 18),
                  _buildPlatformGuide(
                    platform: 'Android Devices',
                    description: 'Scan with Camera or Google Lens -> Instant Google Scene Viewer (GLB).',
                    icon: Icons.android,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cyan,
                      foregroundColor: const Color(0xFF090D16),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => _launchWebAR(context),
                    icon: const Icon(Icons.open_in_browser_rounded, size: 20),
                    label: const Text(
                      'TEST IN BROWSER',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _shareLink,
                    icon: const Icon(Icons.share_outlined, size: 20),
                    label: const Text(
                      'SHARE LINK',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Back to Scanner Button
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.camera_alt_outlined, size: 18, color: AppTheme.textMuted),
              label: Text(
                'Scan Another Physical Object',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformGuide({
    required String platform,
    required String description,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.cyan),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                platform,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
