import 'dart:io';
import 'dart:isolate';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final String rawText;
  final double? monto;
  final DateTime? fecha;
  final String? comercio;

  OcrResult({
    required this.rawText,
    this.monto,
    this.fecha,
    this.comercio,
  });
}

class OcrService {
  final TextRecognizer _recognizer;

  OcrService() : _recognizer = TextRecognizer();

  Future<OcrResult> processImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _recognizer.processImage(inputImage);

    final rawText = recognizedText.text;
    final parsed = await Isolate.run(() => _parseReceipt(rawText));

    return OcrResult(
      rawText: rawText,
      monto: parsed['monto'],
      fecha: parsed['fecha'],
      comercio: parsed['comercio'],
    );
  }

  static Map<String, dynamic> _parseReceipt(String text) {
    final lines = text.split('\n');
    double? monto;
    DateTime? fecha;
    String? comercio;

    for (final line in lines) {
      final trimmed = line.trim().toLowerCase();

      if (comercio == null && trimmed.isNotEmpty && trimmed.length > 3) {
        if (!trimmed.contains(RegExp(r'\d')) || trimmed.length > 4) {
          comercio = line.trim();
        }
      }

      final montoMatch = RegExp(r'(?:total|importe|monto|suma|\$)\s*:?\s*(\d+[.,]\d{2})')
          .firstMatch(trimmed);
      if (montoMatch != null) {
        monto = double.tryParse(montoMatch.group(1)!.replaceAll(',', '.'));
      }

      if (monto == null) {
        final amountMatch =
            RegExp(r'(\d+[.,]\d{2})\s*$').firstMatch(trimmed);
        if (amountMatch != null) {
          monto = double.tryParse(amountMatch.group(1)!.replaceAll(',', '.'));
        }
      }

      final dateMatch = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})')
          .firstMatch(trimmed);
      if (dateMatch != null) {
        try {
          final day = int.parse(dateMatch.group(1)!);
          final month = int.parse(dateMatch.group(2)!);
          final year = int.parse(dateMatch.group(3)!);
          fecha = DateTime(
            year < 100 ? 2000 + year : year,
            month,
            day,
          );
        } catch (_) {}
      }
    }

    return {
      'monto': monto,
      'fecha': fecha,
      'comercio': comercio,
    };
  }

  void dispose() {
    _recognizer.close();
  }
}
