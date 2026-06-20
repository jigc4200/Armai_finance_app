import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> _compressFile(File file) async {
    try {
      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf(
        RegExp(r'\.png|\.jpg|\.jpeg|\.PNG|\.JPG|\.JPEG'),
      );
      final splitted = filePath.substring(
        0,
        (lastIndex >= 0) ? lastIndex : filePath.length,
      );
      final outPath = "${splitted}_compressed.webp";

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        outPath,
        quality: 75,
        format: CompressFormat.webp,
      );

      if (result == null) return file;

      // Eliminar el archivo original sin comprimir para liberar espacio de inmediato
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}

      return File(result.path);
    } catch (_) {
      return file; // Retorna el archivo original si falla la compresión
    }
  }

  Future<File?> pickFromCamera() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (xFile == null) return null;
    return _compressFile(File(xFile.path));
  }

  Future<File?> pickFromGallery() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (xFile == null) return null;
    return _compressFile(File(xFile.path));
  }
}
