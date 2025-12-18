import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageUtils {
  static Future<XFile> compressImage(XFile imageFile) async {
    print("📸 [ImageUtils] Processing '${p.basename(imageFile.path)}'...");
    
    // 1. Chặn file không phải ảnh (Video, PDF...)
    final String ext = p.extension(imageFile.path).toLowerCase();
    if (!['.jpg', '.jpeg', '.png', '.heic', '.webp'].contains(ext)) {
       print("⛔ [ImageUtils] Rejected non-image file: $ext");
       return imageFile; // Hoặc throw Exception nếu muốn chặn hẳn
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(
        tempDir.path, 
        "compressed_${DateTime.now().millisecondsSinceEpoch}.jpg"
      );

      final int originalSize = await imageFile.length();
      
      // 2. Nén mạnh tay (Quality 60, Resize 1024)
      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        targetPath,
        minWidth: 1024,
        minHeight: 1024,
        quality: 60, 
        autoCorrectionAngle: true, // Tự xoay ảnh đúng chiều
        format: CompressFormat.jpeg,
        keepExif: false, // Bỏ thông tin thừa
      );

      if (result != null) {
        final int compressedSize = await result.length();
        print("✅ [ImageUtils] Compressed: ${(originalSize/1024).round()}KB -> ${(compressedSize/1024).round()}KB");
        return result;
      }
    } catch (e) {
      print("⚠️ [ImageUtils] Error: $e. Using original.");
    }
    return imageFile;
  }
}