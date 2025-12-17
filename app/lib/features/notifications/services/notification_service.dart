import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import '../../../core/models/notification.dart';
import '../repositories/notification_repository.dart';
import '../../decks/repositories/vocabulary_repository.dart';
import '../../decks/repositories/deck_repository.dart';
import 'callback_dispatcher.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final NotificationRepository _notificationRepository =
      NotificationRepository();
  final VocabularyRepository _vocabularyRepository = VocabularyRepository();
  final DeckRepository _deckRepository = DeckRepository();

  bool _isInitialized = false;

  // Khởi tạo notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Cấu hình Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Cấu hình iOS
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Cấu hình initialization
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Khởi tạo
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Tạo notification channel cho Android
    await _createNotificationChannel();

    // Yêu cầu quyền trên Android 13+
    await _requestPermissions();

    // Khởi tạo workmanager
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    _isInitialized = true;
  }

  // Tạo notification channel cho Android
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'due_vocabularies_channel', // id
      'Từ vựng đến hạn', // name
      description: 'Thông báo khi có từ vựng đến hạn ôn tập',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    final androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(channel);
    }
  }

  // Yêu cầu quyền thông báo
  Future<void> _requestPermissions() async {
    final androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      // Yêu cầu quyền schedule exact alarm cho Android 12+
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  // Xử lý khi người dùng tap vào thông báo
  void _onNotificationTapped(NotificationResponse response) {
    // TODO: Navigate to appropriate screen based on notification payload
  }

  // Lên lịch kiểm tra và gửi thông báo cho từ vựng đến hạn
  Future<void> scheduleDueVocabularyNotifications() async {
    // Hủy tất cả các task cũ
    await Workmanager().cancelByUniqueName('checkDueVocabularies');

    // Lên lịch task chạy định kỳ (mỗi 15 phút)
    await Workmanager().registerPeriodicTask(
      'checkDueVocabularies',
      'checkDueVocabularies',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );

    // Kiểm tra ngay lập tức
    await checkAndSendDueNotifications();
  }

  // Kiểm tra và gửi thông báo cho từ vựng đến hạn (public để workmanager có thể gọi)
  Future<void> checkAndSendDueNotifications() async {
    try {
      // Lấy tất cả decks
      final decks = await _deckRepository.getAllDecks();

      // Kiểm tra xem đã có thông báo cho deck nào chưa (trong 1 giờ qua)
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      final recentNotifications =
          await _notificationRepository.getAllNotifications(unreadOnly: false);

      for (final deck in decks) {
        if (deck.id == null) continue;

        // Lấy từ vựng đến hạn trong deck này
        final dueVocabularies =
            await _vocabularyRepository.getDueReviewVocabularies(deck.id!);

        if (dueVocabularies.isNotEmpty) {
          // Kiểm tra xem đã có thông báo cho deck này chưa (trong 1 giờ qua)
          final hasRecentNotificationForDeck = recentNotifications.any(
              (notif) =>
                  notif.deckId == deck.id &&
                  notif.type == 'due_vocabulary' &&
                  notif.time.isAfter(oneHourAgo));

          // Chỉ gửi thông báo nếu chưa có thông báo gần đây cho deck này
          if (!hasRecentNotificationForDeck) {
            // Tạo thông báo cho deck này
            final count = dueVocabularies.length;
            final title = count == 1
                ? 'Từ vựng đến hạn ôn tập'
                : 'Bạn có $count từ vựng đến hạn ôn tập';
            final message = count == 1
                ? 'Deck "${deck.name}" có 1 từ vựng cần được ôn tập ngay!'
                : 'Deck "${deck.name}" có $count từ vựng cần ôn tập.';

            // Lưu vào database
            final notification = AppNotification(
              title: title,
              message: message,
              time: DateTime.now(),
              type: 'due_vocabulary',
              deckId: deck.id,
            );
            await _notificationRepository.createNotification(notification);

            // Gửi thông báo local cho deck này
            // Sử dụng hash của deck.id để tạo notification ID duy nhất
            await _showNotification(
              id: deck.id! * 1000, // Tạo ID duy nhất cho mỗi deck
              title: title,
              body: message,
              payload: 'deck_${deck.id}',
            );
          }
        }
      }
    } catch (e) {
      print('Error checking due vocabularies: $e');
    }
  }

  // Hiển thị thông báo local
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'due_vocabularies_channel',
      'Từ vựng đến hạn',
      channelDescription: 'Thông báo khi có từ vựng đến hạn ôn tập',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }
}
