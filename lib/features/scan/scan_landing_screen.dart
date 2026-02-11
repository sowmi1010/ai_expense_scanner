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
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scan receipt',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Use camera, import gallery bill, or add expense manually when no bill is available.',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: Glass(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.document_scanner_rounded,
                      size: 64,
                      color: cs.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ready when you are',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Take a clear photo for better OCR amount detection.',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: _picking ? null : _pickFromGallery,
                        icon: _picking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.photo_library_rounded),
                        label: Text(_picking ? 'Loading...' : 'Import from gallery'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.receiptPreview);
                        },
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('No bill? Enter manually'),
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
}
