import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/pronunciation_result.dart';

class PronunciationService {
  final ApiClient _apiClient;

  PronunciationService(this._apiClient);

  Future<PronunciationResult> assessPronunciation({
    required File audioFile,
    required String referenceText,
    String languageCode = 'en-US',
  }) async {
    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          audioFile.path,
          filename: audioFile.path.split('/').last,
        ),
        'referenceText': referenceText,
        'languageCode': languageCode,
      });

      final response = await _apiClient.dio.post(
        '/pronunciations/assess',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 120),
        ),
      );

      return PronunciationResult.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        final status = e.response?.statusCode;
        final data = e.response?.data;
        final msg = data is Map && data['detail'] != null
            ? data['detail'].toString()
            : data?.toString() ?? e.message ?? 'Unknown error';
        throw Exception('HTTP ${status ?? '-'}: $msg');
      }
      rethrow;
    }
  }
}
