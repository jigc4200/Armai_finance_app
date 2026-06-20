import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/image_picker_service.dart';
import '../../services/ocr_service.dart';
import 'ocr_review_screen.dart';

class OcrCaptureScreen extends StatefulWidget {
  const OcrCaptureScreen({super.key});

  @override
  State<OcrCaptureScreen> createState() => _OcrCaptureScreenState();
}

class _OcrCaptureScreenState extends State<OcrCaptureScreen> {
  final _imagePicker = ImagePickerService();
  final _ocrService = OcrService();
  File? _imageFile;
  bool _isProcessing = false;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = source == ImageSource.camera
        ? await _imagePicker.pickFromCamera()
        : await _imagePicker.pickFromGallery();

    if (file == null) return;

    setState(() {
      _imageFile = file;
      _isProcessing = true;
    });

    try {
      final result = await _ocrService.processImage(file);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OcrReviewScreen(imageFile: file, ocrResult: result),
        ),
      ).then((_) {
        setState(() => _isProcessing = false);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);

      // Auto-destrucción del archivo temporal del OCR en caso de error
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al procesar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Escanear recibo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Tomá una foto del recibo o elegí una de tu galería',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'El texto se extraerá automáticamente',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 48),
            if (_isProcessing && _imageFile != null)
              Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 250,
                        width: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        ),
                      ),
                      Container(
                        height: 250,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      SizedBox(
                        height: 250,
                        width: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: const LaserScannerWidget(
                            height: 250,
                            width: 200,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Analizando recibo...',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            else if (_isProcessing)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Procesando imagen...'),
                ],
              )
            else ...[
              FilledButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Tomar foto'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Elegir de galería'),
              ),
            ],
            if (_imageFile != null && !_isProcessing) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_imageFile!, fit: BoxFit.cover),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LaserScannerWidget extends StatefulWidget {
  final double height;
  final double width;
  const LaserScannerWidget({
    super.key,
    required this.height,
    required this.width,
  });

  @override
  State<LaserScannerWidget> createState() => _LaserScannerWidgetState();
}

class _LaserScannerWidgetState extends State<LaserScannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final offset = _controller.value * widget.height;
          return Stack(
            children: [
              Positioned(
                top: offset,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.8),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
