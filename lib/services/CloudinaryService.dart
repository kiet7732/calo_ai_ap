import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  
  final String _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  final String _uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  late final CloudinaryPublic _cloudinary;

  CloudinaryService() {
    if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
      throw Exception("Chưa cấu hình Cloudinary trong .env hoặc chưa load file .env");
    }
    _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);
  }

  Future<String?> uploadImage(File imageFile) async {
    // Bỏ try-catch để lỗi được ném ra ngoài cho UI xử lý
    if (kDebugMode) print("☁️ Đang tải ảnh lên Cloudinary...");
    
    CloudinaryResponse response = await _cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        imageFile.path, 
        resourceType: CloudinaryResourceType.Image,
        folder: "Home",
      ),
    );

    if (kDebugMode) print("✅ Upload thành công: ${response.secureUrl}");
    return response.secureUrl; 
  }
}