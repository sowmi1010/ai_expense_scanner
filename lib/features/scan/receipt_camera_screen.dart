import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/ui/app_spacing.dart';
import '../../core/ui/glass.dart';
import '../../routes/app_routes.dart';
import 'receipt_preview_args.dart';

class ReceiptCameraScreen extends StatefulWidget {
  const ReceiptCameraScreen({super.key});

  @override
  State<ReceiptCameraScreen> createState() => _ReceiptCameraScreenState();
}

class _ReceiptCameraScreenState extends State<ReceiptCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _initializing = true;
  bool _capturing = false;
  int _cameraIndex = 0;
  FlashMode _flash = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      c.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    setState(() => _initializing = true);

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No camera found on this device')),
          );
        }
        setState(() => _initializing = false);
        return;
      }

      // Prefer back camera if available
      _cameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (_cameraIndex == -1) _cameraIndex = 0;

      final controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      await controller.setFlashMode(_flash);

      _controller?.dispose();
      _controller = controller;

      if (mounted) setState(() => _initializing = false);
    } catch (e) {
      if (mounted) {
        setState(() => _initializing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Camera init failed: $e')));
      }
    }
  }

  Future<void> _toggleFlash() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;

    FlashMode next;
    switch (_flash) {
      case FlashMode.off:
        next = FlashMode.auto;
        break;
      case FlashMode.auto:
        next = FlashMode.always;
        break;
      case FlashMode.always:
        next = FlashMode.off;
        break;
      default:
        next = FlashMode.off;
    }

    try {
      await c.setFlashMode(next);
      setState(() => _flash = next);
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    _cameraIndex = (_cameraIndex + 1) % _cameras.length;

    final old = _controller;
    setState(() => _initializing = true);

    try {
      final controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      await controller.setFlashMode(_flash);

      await old?.dispose();
      _controller = controller;

      if (mounted) setState(() => _initializing = false);
    } catch (e) {
      if (mounted) {
        setState(() => _initializing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Switch camera failed: $e')));
      }
    }
  }

  IconData _flashIcon() {
    switch (_flash) {
      case FlashMode.off:
        return Icons.flash_off_rounded;
      case FlashMode.auto:
        return Icons.flash_auto_rounded;
      case FlashMode.always:
        return Icons.flash_on_rounded;
      default:
        return Icons.flash_off_rounded;
    }
  }

  Future<void> _capture() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _capturing) return;

    setState(() => _capturing = true);

    try {
      await c.setFocusMode(FocusMode.auto);
      await c.setExposureMode(ExposureMode.auto);

      final XFile file = await c.takePicture();

      if (!mounted) return;

      // Navigate to preview screen with file path
      Navigator.pushNamed(
        context,
        AppRoutes.receiptPreview,
        arguments: ReceiptPreviewArgs(imagePath: file.path),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _initializing
                  ? const Center(child: CircularProgressIndicator())
                  : (_controller == null || !_controller!.value.isInitialized)
                  ? Center(
                      child: Text(
                        'Camera not ready',
                        style: TextStyle(color: cs.onSurface),
                      ),
                    )
                  : CameraPreview(_controller!),
            ),

            // Top controls (glass)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              child: Glass(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Align the receipt inside the frame',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: _toggleFlash,
                      icon: Icon(_flashIcon()),
                      tooltip: 'Flash',
                    ),
                    IconButton(
                      onPressed: _switchCamera,
                      icon: const Icon(Icons.cameraswitch_rounded),
                      tooltip: 'Switch camera',
                    ),
                  ],
                ),
              ),
            ),

            // Receipt frame overlay
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.86,
                    height: MediaQuery.of(context).size.height * 0.60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.75),
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom capture panel
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Glass(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tip: Keep it flat • good light • avoid blur',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _CaptureButton(loading: _capturing, onTap: _capture),
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

class _CaptureButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _CaptureButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.primary.withValues(alpha: 0.95),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.30),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.camera_alt_rounded),
        ),
      ),
    );
  }
}
