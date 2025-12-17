import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../api/api_client.dart';
import '../database/database_helper.dart';
import 'cloud_storage_service.dart';

class SyncService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final CloudStorageService _storageService = CloudStorageService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Dio _dio = Dio();

  /// Đồng bộ dữ liệu từ cloud xuống local
  ///
  /// [apiBaseUrl] - Base URL của API
  /// [onProgress] - Callback để cập nhật tiến trình (optional)
  Future<SyncResult> syncFromCloud({
    required String apiBaseUrl,
    void Function(String message, double progress)? onProgress,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      onProgress?.call('Đang tải dữ liệu từ cloud...', 0.1);
      final apiClient = ApiClient(apiBaseUrl);
      final response = await apiClient.dio.get('/users/me/data');

      if (response.statusCode != 200) {
        throw Exception('Server trả về lỗi: ${response.statusCode}');
      }

      final data = response.data['data'];
      if (data == null) {
        throw Exception('Không có dữ liệu từ server');
      }

      onProgress?.call('Đang xử lý dữ liệu...', 0.3);
      final db = await _dbHelper.database;

      // Bắt đầu transaction
      await db.transaction((txn) async {
        // 1. Merge decks
        if (data['decks'] != null) {
          for (final cloudDeck in data['decks']) {
            final existing = await txn.query(
              'decks',
              where: 'id = ?',
              whereArgs: [cloudDeck['id']],
              limit: 1,
            );

            if (existing.isEmpty) {
              // Deck mới, thêm vào
              await txn.insert('decks', {
                'id': cloudDeck['id'],
                'name': cloudDeck['name'],
                'color': cloudDeck['color'] ?? '#2196F3',
                'created_at': cloudDeck['created_at'],
                'updated_at': cloudDeck['updated_at'],
                'is_active': cloudDeck['is_active'] ?? 1,
                'is_favorite': cloudDeck['is_favorite'] ?? 0,
              });
            } else {
              // Deck đã tồn tại, cập nhật nếu cloud mới hơn
              final localUpdated =
                  DateTime.parse(existing.first['updated_at'] as String);
              final cloudUpdated =
                  DateTime.parse(cloudDeck['updated_at'] as String);
              if (cloudUpdated.isAfter(localUpdated)) {
                await txn.update(
                  'decks',
                  {
                    'name': cloudDeck['name'],
                    'color': cloudDeck['color'] ?? '#2196F3',
                    'updated_at': cloudDeck['updated_at'],
                    'is_active': cloudDeck['is_active'] ?? 1,
                    'is_favorite': cloudDeck['is_favorite'] ?? 0,
                  },
                  where: 'id = ?',
                  whereArgs: [cloudDeck['id']],
                );
              }
            }
          }
        }

        // 2. Merge vocabularies
        if (data['vocabularies'] != null) {
          for (final cloudVocab in data['vocabularies']) {
            final existing = await txn.query(
              'vocabularies',
              where: 'id = ?',
              whereArgs: [cloudVocab['id']],
              limit: 1,
            );

            if (existing.isEmpty) {
              // Vocabulary mới, thêm vào
              await txn.insert('vocabularies', {
                'id': cloudVocab['id'],
                'deck_id': cloudVocab['deck_id'],
                'front': cloudVocab['front'],
                'back': cloudVocab['back'],
                'front_image_url': cloudVocab['front_image_url'],
                'front_image_path': cloudVocab['front_image_path'],
                'back_image_url': cloudVocab['back_image_url'],
                'back_image_path': cloudVocab['back_image_path'],
                'front_extra_json': cloudVocab['front_extra_json'],
                'back_extra_json': cloudVocab['back_extra_json'],
                'created_at': cloudVocab['created_at'],
                'updated_at': cloudVocab['updated_at'],
                'is_active': cloudVocab['is_active'] ?? 1,
                'card_type': cloudVocab['card_type'] ?? 'basis',
              });
            } else {
              // Vocabulary đã tồn tại, cập nhật nếu cloud mới hơn
              final localUpdated =
                  DateTime.parse(existing.first['updated_at'] as String);
              final cloudUpdated =
                  DateTime.parse(cloudVocab['updated_at'] as String);
              if (cloudUpdated.isAfter(localUpdated)) {
                await txn.update(
                  'vocabularies',
                  {
                    'deck_id': cloudVocab['deck_id'],
                    'front': cloudVocab['front'],
                    'back': cloudVocab['back'],
                    'front_image_url': cloudVocab['front_image_url'],
                    'front_image_path': cloudVocab['front_image_path'],
                    'back_image_url': cloudVocab['back_image_url'],
                    'back_image_path': cloudVocab['back_image_path'],
                    'front_extra_json': cloudVocab['front_extra_json'],
                    'back_extra_json': cloudVocab['back_extra_json'],
                    'updated_at': cloudVocab['updated_at'],
                    'is_active': cloudVocab['is_active'] ?? 1,
                    'card_type': cloudVocab['card_type'] ?? 'basis',
                  },
                  where: 'id = ?',
                  whereArgs: [cloudVocab['id']],
                );
              }
            }
          }
        }

        // 3. Merge vocabulary_srs
        if (data['vocabulary_srs'] != null) {
          for (final cloudSrs in data['vocabulary_srs']) {
            final existing = await txn.query(
              'vocabulary_srs',
              where: 'vocabulary_id = ?',
              whereArgs: [cloudSrs['vocabulary_id']],
              limit: 1,
            );

            if (existing.isEmpty) {
              // SRS mới, thêm vào
              await txn.insert('vocabulary_srs', {
                'vocabulary_id': cloudSrs['vocabulary_id'],
                'mastery_level': cloudSrs['mastery_level'] ?? 0,
                'review_count': cloudSrs['review_count'] ?? 0,
                'last_reviewed': cloudSrs['last_reviewed'],
                'next_review': cloudSrs['next_review'],
                'srs_ease_factor': cloudSrs['srs_ease_factor'] ?? 2.5,
                'srs_interval': cloudSrs['srs_interval'] ?? 0,
                'srs_repetitions': cloudSrs['srs_repetitions'] ?? 0,
                'srs_due': cloudSrs['srs_due'],
                'srs_type': cloudSrs['srs_type'] ?? 0,
                'srs_queue': cloudSrs['srs_queue'] ?? 0,
                'srs_lapses': cloudSrs['srs_lapses'] ?? 0,
                'srs_left': cloudSrs['srs_left'] ?? 0,
              });
            } else {
              // SRS đã tồn tại, cập nhật nếu cloud mới hơn (dựa vào last_reviewed)
              final localLastReviewed =
                  existing.first['last_reviewed'] as String?;
              final cloudLastReviewed = cloudSrs['last_reviewed'] as String?;

              bool shouldUpdate = false;
              if (cloudLastReviewed != null && localLastReviewed == null) {
                shouldUpdate = true;
              } else if (cloudLastReviewed != null &&
                  localLastReviewed != null) {
                final cloudDate = DateTime.parse(cloudLastReviewed);
                final localDate = DateTime.parse(localLastReviewed);
                shouldUpdate = cloudDate.isAfter(localDate);
              }

              if (shouldUpdate) {
                await txn.update(
                  'vocabulary_srs',
                  {
                    'mastery_level': cloudSrs['mastery_level'] ?? 0,
                    'review_count': cloudSrs['review_count'] ?? 0,
                    'last_reviewed': cloudSrs['last_reviewed'],
                    'next_review': cloudSrs['next_review'],
                    'srs_ease_factor': cloudSrs['srs_ease_factor'] ?? 2.5,
                    'srs_interval': cloudSrs['srs_interval'] ?? 0,
                    'srs_repetitions': cloudSrs['srs_repetitions'] ?? 0,
                    'srs_due': cloudSrs['srs_due'],
                    'srs_type': cloudSrs['srs_type'] ?? 0,
                    'srs_queue': cloudSrs['srs_queue'] ?? 0,
                    'srs_lapses': cloudSrs['srs_lapses'] ?? 0,
                    'srs_left': cloudSrs['srs_left'] ?? 0,
                  },
                  where: 'vocabulary_id = ?',
                  whereArgs: [cloudSrs['vocabulary_id']],
                );
              }
            }
          }
        }

        // 4. Merge study_sessions (chỉ thêm mới, không update)
        if (data['study_sessions'] != null) {
          for (final cloudSession in data['study_sessions']) {
            final existing = await txn.query(
              'study_sessions',
              where: 'id = ?',
              whereArgs: [cloudSession['id']],
              limit: 1,
            );

            if (existing.isEmpty) {
              await txn.insert('study_sessions', {
                'id': cloudSession['id'],
                'deck_id': cloudSession['deck_id'],
                'vocabulary_id': cloudSession['vocabulary_id'],
                'session_type': cloudSession['session_type'],
                'result': cloudSession['result'],
                'time_spent': cloudSession['time_spent'] ?? 0,
                'created_at': cloudSession['created_at'],
              });
            }
          }
        }
      });

      // 5. Tải ảnh từ URL về local nếu cần
      onProgress?.call('Đang tải ảnh từ cloud...', 0.8);

      // Query tất cả vocabularies có image URL từ Firebase Storage
      final vocabulariesWithImages = await db.query(
        'vocabularies',
        where: '(front_image_url IS NOT NULL AND front_image_url LIKE ?) OR '
            '(back_image_url IS NOT NULL AND back_image_url LIKE ?)',
        whereArgs: [
          '%firebasestorage.googleapis.com%',
          '%firebasestorage.googleapis.com%'
        ],
      );

      int imagesDownloaded = 0;
      final List<Map<String, dynamic>> imageUpdates = [];

      for (var i = 0; i < vocabulariesWithImages.length; i++) {
        final vocab = vocabulariesWithImages[i];
        final vocabId = vocab['id'] as int?;
        if (vocabId == null) continue;

        // Kiểm tra và tải front image
        final frontUrl = _normalizeUrl(vocab['front_image_url']);
        final frontPath = _normalizePath(vocab['front_image_path']);

        if (frontUrl != null && frontUrl.isFirebaseStorageUrl) {
          // Nếu có URL nhưng không có path local, hoặc file không tồn tại
          bool needDownload = false;
          if (frontPath == null) {
            needDownload = true;
          } else {
            final file = File(frontPath);
            if (!await file.exists()) {
              needDownload = true;
            }
          }

          if (needDownload) {
            final downloadedPath =
                await _downloadImageToPermanentStorage(frontUrl);
            if (downloadedPath != null) {
              final existingUpdate = imageUpdates.firstWhere(
                (u) => u['vocab_id'] == vocabId,
                orElse: () => {'vocab_id': vocabId},
              );
              if (!imageUpdates.contains(existingUpdate)) {
                imageUpdates.add(existingUpdate);
              }
              existingUpdate['front_image_path'] = downloadedPath;
              imagesDownloaded++;
            }
          }
        }

        // Kiểm tra và tải back image
        final backUrl = _normalizeUrl(vocab['back_image_url']);
        final backPath = _normalizePath(vocab['back_image_path']);

        if (backUrl != null && backUrl.isFirebaseStorageUrl) {
          bool needDownload = false;
          if (backPath == null) {
            needDownload = true;
          } else {
            final file = File(backPath);
            if (!await file.exists()) {
              needDownload = true;
            }
          }

          if (needDownload) {
            final downloadedPath =
                await _downloadImageToPermanentStorage(backUrl);
            if (downloadedPath != null) {
              final existingUpdate = imageUpdates.firstWhere(
                (u) => u['vocab_id'] == vocabId,
                orElse: () => {'vocab_id': vocabId},
              );
              if (!imageUpdates.contains(existingUpdate)) {
                imageUpdates.add(existingUpdate);
              }
              existingUpdate['back_image_path'] = downloadedPath;
              imagesDownloaded++;
            }
          }
        }

        if (onProgress != null &&
            vocabulariesWithImages.isNotEmpty &&
            i % 10 == 0) {
          final progress = 0.8 + (i / vocabulariesWithImages.length) * 0.15;
          onProgress(
            'Đang tải ảnh ${i + 1}/${vocabulariesWithImages.length}...',
            progress > 0.95 ? 0.95 : progress,
          );
        }
      }

      // Cập nhật paths vào database
      if (imageUpdates.isNotEmpty) {
        final batch = db.batch();
        final Map<int, Map<String, String>> updatesMap = {};

        for (final update in imageUpdates) {
          final vocabId = update['vocab_id'] as int;
          if (!updatesMap.containsKey(vocabId)) {
            updatesMap[vocabId] = {};
          }
          if (update.containsKey('front_image_path')) {
            updatesMap[vocabId]!['front_image_path'] =
                update['front_image_path'] as String;
          }
          if (update.containsKey('back_image_path')) {
            updatesMap[vocabId]!['back_image_path'] =
                update['back_image_path'] as String;
          }
        }

        for (final entry in updatesMap.entries) {
          batch.update(
            'vocabularies',
            entry.value,
            where: 'id = ?',
            whereArgs: [entry.key],
          );
        }
        await batch.commit(noResult: true);
      }

      onProgress?.call('Hoàn thành!', 1.0);

      final stats = response.data['stats'];
      return SyncResult(
        success: true,
        message: 'Đồng bộ từ cloud thành công!',
        stats: SyncStats(
          decks: stats?['decks'] ?? 0,
          vocabularies: stats?['vocabularies'] ?? 0,
          vocabularySrs: stats?['vocabulary_srs'] ?? 0,
          studySessions: stats?['study_sessions'] ?? 0,
          imagesUploaded: imagesDownloaded,
        ),
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Lỗi khi đồng bộ từ cloud: ${e.toString()}',
        stats: null,
      );
    }
  }

  /// Đồng bộ hai chiều như Anki (sync full)
  ///
  /// [apiBaseUrl] - Base URL của API
  /// [onProgress] - Callback để cập nhật tiến trình (optional)
  Future<SyncResult> syncFull({
    required String apiBaseUrl,
    void Function(String message, double progress)? onProgress,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      // Bước 1: Tải dữ liệu từ cloud xuống (0-40%)
      onProgress?.call('Đang tải dữ liệu từ cloud...', 0.1);
      final downloadResult = await syncFromCloud(
        apiBaseUrl: apiBaseUrl,
        onProgress: (message, progress) {
          onProgress?.call(message, progress * 0.4);
        },
      );

      if (!downloadResult.success) {
        return downloadResult;
      }

      // Bước 2: Upload dữ liệu local lên cloud (40-100%)
      onProgress?.call('Đang tải dữ liệu lên cloud...', 0.45);
      final uploadResult = await syncToCloud(
        apiBaseUrl: apiBaseUrl,
        onProgress: (message, progress) {
          onProgress?.call(message, 0.45 + (progress * 0.55));
        },
      );

      if (!uploadResult.success) {
        return uploadResult;
      }

      // Kết hợp stats
      final combinedStats = SyncStats(
        decks: uploadResult.stats?.decks ?? 0,
        vocabularies: uploadResult.stats?.vocabularies ?? 0,
        vocabularySrs: uploadResult.stats?.vocabularySrs ?? 0,
        studySessions: uploadResult.stats?.studySessions ?? 0,
        imagesUploaded: uploadResult.stats?.imagesUploaded ?? 0,
      );

      return SyncResult(
        success: true,
        message: 'Đồng bộ hai chiều hoàn tất!',
        stats: combinedStats,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Lỗi khi đồng bộ: ${e.toString()}',
        stats: null,
      );
    }
  }

  /// Đồng bộ toàn bộ dữ liệu lên cloud
  ///
  /// [apiBaseUrl] - Base URL của API (ví dụ: 'http://10.0.2.2:3000')
  /// [onProgress] - Callback để cập nhật tiến trình (optional)
  Future<SyncResult> syncToCloud({
    required String apiBaseUrl,
    void Function(String message, double progress)? onProgress,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      onProgress?.call('Đang đọc dữ liệu từ database...', 0.1);
      final db = await _dbHelper.database;

      // 1. Đọc dữ liệu từ SQLite
      final decks = await db.query('decks', orderBy: 'id');
      final vocabularies = await db.query('vocabularies', orderBy: 'id');
      final vocabularySrs =
          await db.query('vocabulary_srs', orderBy: 'vocabulary_id');
      final studySessions = await db.query('study_sessions', orderBy: 'id');

      onProgress?.call('Đang xử lý & tải ảnh lên Firebase...', 0.35);
      final imageResult = await _processVocabImages(
        vocabularies: vocabularies,
        uid: user.uid,
        onProgress: onProgress,
      );
      await _persistImageUpdates(imageResult.updates);

      onProgress?.call('Đang gửi dữ liệu lên server...', 0.85);

      // 3. Gửi dữ liệu lên API
      final apiClient = ApiClient(apiBaseUrl);
      print('Sync URL: ${apiClient.dio.options.baseUrl}/users/me/sync');
      final response = await apiClient.dio.post(
        '/users/me/sync',
        data: {
          'decks': decks,
          'vocabularies': imageResult.vocabularies,
          'vocabulary_srs': vocabularySrs,
          'study_sessions': studySessions,
        },
      );

      onProgress?.call('Hoàn thành!', 1.0);

      if (response.statusCode == 200) {
        final data = response.data;
        return SyncResult(
          success: true,
          message: 'Đồng bộ thành công!',
          stats: SyncStats(
            decks: data['stats']?['decks'] ?? decks.length,
            vocabularies: data['stats']?['vocabularies'] ?? vocabularies.length,
            vocabularySrs:
                data['stats']?['vocabulary_srs'] ?? vocabularySrs.length,
            studySessions:
                data['stats']?['study_sessions'] ?? studySessions.length,
            imagesUploaded: imageResult.uploadedCount,
          ),
        );
      } else {
        throw Exception('Server trả về lỗi: ${response.statusCode}');
      }
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Lỗi khi đồng bộ: ${e.toString()}',
        stats: null,
      );
    }
  }

  Future<_ImageProcessResult> _processVocabImages({
    required List<Map<String, Object?>> vocabularies,
    required String uid,
    void Function(String message, double progress)? onProgress,
  }) async {
    final Map<String, String> uploadedCache = {};
    final Map<String, String> remoteCache = {};
    final List<Map<String, dynamic>> updated = [];
    final List<_ImageUpdate> updates = [];
    int uploadedCount = 0;

    for (var i = 0; i < vocabularies.length; i++) {
      final vocab = Map<String, dynamic>.from(vocabularies[i]);

      if (await _handleImageField(
        vocab,
        fieldPrefix: 'front',
        uid: uid,
        uploadedCache: uploadedCache,
        remoteCache: remoteCache,
        updates: updates,
      )) {
        uploadedCount++;
      }

      if (await _handleImageField(
        vocab,
        fieldPrefix: 'back',
        uid: uid,
        uploadedCache: uploadedCache,
        remoteCache: remoteCache,
        updates: updates,
      )) {
        uploadedCount++;
      }

      updated.add(vocab);

      if (onProgress != null && vocabularies.isNotEmpty && i % 10 == 0) {
        final progress = 0.35 + (i / vocabularies.length) * 0.25;
        onProgress(
          'Đang xử lý ảnh ${i + 1}/${vocabularies.length}...',
          progress > 0.85 ? 0.85 : progress,
        );
      }
    }

    return _ImageProcessResult(
      vocabularies: updated,
      uploadedCount: uploadedCount,
      updates: updates,
    );
  }

  Future<bool> _handleImageField(
    Map<String, dynamic> vocab, {
    required String fieldPrefix,
    required String uid,
    required Map<String, String> uploadedCache,
    required Map<String, String> remoteCache,
    required List<_ImageUpdate> updates,
  }) async {
    final pathKey = '${fieldPrefix}_image_path';
    final urlKey = '${fieldPrefix}_image_url';

    String? localPath = _normalizePath(vocab[pathKey]);
    final String? remoteUrl = _normalizeUrl(vocab[urlKey]);
    var shouldDeleteTempFile = false;

    if (remoteUrl != null && remoteUrl.isFirebaseStorageUrl) {
      return false;
    }

    if (localPath != null) {
      final exists = await File(localPath).exists();
      if (!exists) {
        localPath = null;
      }
    }

    if (localPath == null && remoteUrl != null && remoteUrl.isRemoteUrl) {
      final cached = remoteCache[remoteUrl];
      if (cached != null) {
        vocab[urlKey] = cached;
        return false;
      }

      final downloadedPath = await _downloadRemoteImage(remoteUrl);
      if (downloadedPath != null) {
        localPath = downloadedPath;
        shouldDeleteTempFile = true;
      }
    }

    if (localPath == null) return false;

    String? uploadedUrl = uploadedCache[localPath];
    if (uploadedUrl == null) {
      final fileName = p.basename(localPath);
      uploadedUrl = await _storageService.uploadImage(
        uid: uid,
        localPath: localPath,
        fileName: fileName,
      );
      if (uploadedUrl != null) {
        uploadedCache[localPath] = uploadedUrl;
      }
    }

    if (uploadedUrl != null) {
      vocab[urlKey] = uploadedUrl;
      vocab[pathKey] = null;
      if (remoteUrl != null && remoteUrl.isRemoteUrl) {
        remoteCache[remoteUrl] = uploadedUrl;
      }
      _registerImageUpdate(
        updates: updates,
        vocab: vocab,
        urlKey: urlKey,
        pathKey: pathKey,
        uploadedUrl: uploadedUrl,
      );
    }

    if (shouldDeleteTempFile) {
      try {
        await File(localPath).delete();
      } catch (_) {}
    }

    return uploadedUrl != null;
  }

  Future<String?> _downloadRemoteImage(String url) async {
    try {
      final directory = await getTemporaryDirectory();
      final uri = Uri.parse(url);
      final ext =
          p.extension(uri.path).isNotEmpty ? p.extension(uri.path) : '.jpg';
      final fileName =
          'sync_${DateTime.now().millisecondsSinceEpoch}_${uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'image'}$ext';
      final savePath = p.join(directory.path, fileName);
      await _dio.download(url, savePath);
      return savePath;
    } catch (e) {
      debugPrint('❌ Không thể tải ảnh từ $url: $e');
      return null;
    }
  }

  /// Tải ảnh từ URL về thư mục Documents (lưu vĩnh viễn)
  Future<String?> _downloadImageToPermanentStorage(String url) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(directory.path, 'vocab_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final uri = Uri.parse(url);
      final ext =
          p.extension(uri.path).isNotEmpty ? p.extension(uri.path) : '.jpg';

      // Tạo tên file dựa trên URL để tránh trùng lặp
      final urlHash = url.hashCode.abs();
      final fileName =
          'img_${urlHash}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final savePath = p.join(imagesDir.path, fileName);

      await _dio.download(url, savePath);
      debugPrint('✅ Đã tải ảnh: $savePath');
      return savePath;
    } catch (e) {
      debugPrint('❌ Không thể tải ảnh từ $url: $e');
      return null;
    }
  }

  String? _normalizePath(dynamic value) {
    if (value == null) return null;
    final path = value.toString().trim();
    if (path.isEmpty) return null;
    return path;
  }

  String? _normalizeUrl(dynamic value) {
    if (value == null) return null;
    final url = value.toString().trim();
    if (url.isEmpty) return null;
    return url;
  }

  Future<void> _persistImageUpdates(List<_ImageUpdate> updates) async {
    if (updates.isEmpty) return;
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final update in updates) {
      batch.update(
        'vocabularies',
        update.fields,
        where: 'id = ?',
        whereArgs: [update.vocabId],
      );
    }
    await batch.commit(noResult: true);
  }

  void _registerImageUpdate({
    required List<_ImageUpdate> updates,
    required Map<String, dynamic> vocab,
    required String urlKey,
    required String pathKey,
    required String uploadedUrl,
  }) {
    final vocabId = vocab['id'];
    if (vocabId == null) return;

    var entry = updates.firstWhere(
      (e) => e.vocabId == vocabId,
      orElse: () {
        final newEntry = _ImageUpdate(vocabId: vocabId, fields: {});
        updates.add(newEntry);
        return newEntry;
      },
    );

    entry.fields[urlKey] = uploadedUrl;
  }
}

class SyncResult {
  final bool success;
  final String message;
  final SyncStats? stats;

  SyncResult({
    required this.success,
    required this.message,
    this.stats,
  });
}

class SyncStats {
  final int decks;
  final int vocabularies;
  final int vocabularySrs;
  final int studySessions;
  final int imagesUploaded;

  SyncStats({
    required this.decks,
    required this.vocabularies,
    required this.vocabularySrs,
    required this.studySessions,
    required this.imagesUploaded,
  });
}

class _ImageProcessResult {
  final List<Map<String, dynamic>> vocabularies;
  final int uploadedCount;
  final List<_ImageUpdate> updates;

  _ImageProcessResult({
    required this.vocabularies,
    required this.uploadedCount,
    required this.updates,
  });
}

extension on String {
  bool get isRemoteUrl => startsWith('http://') || startsWith('https://');

  bool get isFirebaseStorageUrl => contains('firebasestorage.googleapis.com');
}

class _ImageUpdate {
  final int vocabId;
  final Map<String, Object?> fields;

  _ImageUpdate({
    required this.vocabId,
    required this.fields,
  });
}
