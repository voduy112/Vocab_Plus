import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CloudStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload ảnh lên Firebase Storage và trả về download URL
  ///
  /// [uid] - User ID từ Firebase Auth
  /// [localPath] - Đường dẫn file ảnh local
  /// [fileName] - Tên file (sẽ được lưu trong thư mục users/{uid}/images/{fileName})
  Future<String?> uploadImage({
    required String uid,
    required String localPath,
    required String fileName,
  }) async {
    try {
      if (!await File(localPath).exists()) {
        debugPrint('⚠️ File không tồn tại: $localPath');
        return null;
      }

      final ref = _storage.ref().child('users/$uid/images/$fileName');
      final file = File(localPath);

      debugPrint('📤 Uploading image: $fileName');
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      debugPrint('✅ Upload thành công: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Lỗi khi upload ảnh: $e');
      return null;
    }
  }

  /// Upload nhiều ảnh và trả về map {localPath: downloadUrl}
  Future<Map<String, String>> uploadImages({
    required String uid,
    required List<String> localPaths,
  }) async {
    final Map<String, String> result = {};

    for (final path in localPaths) {
      if (path.isEmpty) continue;

      final fileName = path.split('/').last;
      final url = await uploadImage(
        uid: uid,
        localPath: path,
        fileName: fileName,
      );

      if (url != null) {
        result[path] = url;
      }
    }

    return result;
  }

  /// Xóa 1 file trên Firebase Storage theo download URL
  Future<void> deleteByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      debugPrint('🗑️ Đã xóa ảnh: $url');
    } catch (e) {
      debugPrint('⚠️ Lỗi khi xóa ảnh: $e');
    }
  }
}
