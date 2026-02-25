import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/ui/app_spacing.dart';
import '../../core/ui/glass.dart';
import '../../routes/app_routes.dart';
import 'receipt_preview_args.dart';

class ScanLandingScreen extends StatefulWidget {
  const ScanLandingScreen({super.key});

  @override
  State<ScanLandingScreen> createState() => _ScanLandingScreenState();
}

class _ScanLandingScreenState extends State<ScanLandingScreen> {
  final _picker = ImagePicker();
  bool _picking = false;

  Future<void> _pickFromGallery() async {
    if (_picking) return;
    setState(() => _picking = true);

    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );

      if (!mounted) return;
      if (image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected')),
        );
        return;
      }

      Navigator.pushNamed(
        context,
        AppRoutes.receiptPreview,
        arguments: ReceiptPreviewArgs(imagePath: image.path),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gallery import failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);

    // Keep this screen stable when device/browser text scaling is extreme.
    final pageTextScaler = mediaQuery.textScaler.clamp(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.1,
    );

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: pageTextScaler),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Positioned(
                  top: -88,
                  right: -68,
                  child: _DecorOrb(
                    size: 210,
                    color: cs.primary.withValues(alpha: 0.14),
                  ),
                ),
                Positioned(
                  bottom: 150,
                  left: -44,
                  child: _DecorOrb(
                    size: 150,
                    color: cs.tertiary.withValues(alpha: 0.12),
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  cs.primary.withValues(alpha: 0.14),
                                  cs.secondary.withValues(alpha: 0.10),
                                  cs.surfaceContainerHighest.withValues(alpha: 0.66),
                                ],
                              ),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(alpha: 0.42),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Scan receipt',
                                            style: theme.textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              height: 1.1,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Use camera, import from gallery, or add expense manually when no bill is available.',
                                            style: theme.textTheme.bodyLarge?.copyWith(
                                              color: cs.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: cs.surface.withValues(alpha: 0.7),
                                        border: Border.all(
                                          color: cs.outlineVariant.withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.auto_awesome_rounded,
                                        color: cs.primary,
                                        size: 26,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: const [
                                    _FeaturePill(
                                      icon: Icons.speed_rounded,
                                      label: 'Fast OCR',
                                    ),
                                    _FeaturePill(
                                      icon: Icons.payments_rounded,
                                      label: 'Amount detection',
                                    ),
                                    _FeaturePill(
                                      icon: Icons.edit_note_rounded,
                                      label: 'Manual fallback',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Expanded(
                            child: Glass(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(14),
                                          color: cs.primary.withValues(alpha: 0.16),
                                        ),
                                        child: Icon(
                                          Icons.document_scanner_rounded,
                                          color: cs.primary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Ready when you are',
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Take a clear photo for better OCR amount detection.',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.pushNamed(context, AppRoutes.camera);
                                      },
                                      icon: const Icon(Icons.camera_alt_rounded),
                                      label: const Text('Open camera'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                      ),
                                      onPressed: _picking ? null : _pickFromGallery,
                                      icon: _picking
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.photo_library_rounded),
                                      label: Text(
                                        _picking ? 'Loading...' : 'Import from gallery',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: cs.onSurface,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.receiptPreview,
                                        );
                                      },
                                      icon: const Icon(Icons.edit_note_rounded),
                                      label: const Text('No bill? Enter manually'),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: cs.surfaceContainerHighest.withValues(alpha: 0.52),
                                      border: Border.all(
                                        color: cs.outlineVariant.withValues(alpha: 0.24),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.tips_and_updates_rounded,
                                          size: 18,
                                          color: cs.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Tip: Keep the receipt flat and fully visible for best results.',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: cs.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: cs.surface.withValues(alpha: 0.65),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              blurRadius: 70,
              spreadRadius: 18,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
