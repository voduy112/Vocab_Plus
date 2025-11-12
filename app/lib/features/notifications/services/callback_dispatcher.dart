import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';

// Callback cho workmanager (phải là top-level function)
// Function này sẽ được gọi ngay cả khi app đã đóng hoàn toàn
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == 'checkDueVocabularies') {
        // Tạo instance mới của NotificationService
        // Đảm bảo nó có thể hoạt động độc lập khi app đã đóng
        final service = NotificationService();
        
        // Khởi tạo service (quan trọng khi app đã đóng)
        await service.initialize();
        
        // Kiểm tra và gửi thông báo
        await service.checkAndSendDueNotifications();
        
        // Trả về true để báo hiệu task đã hoàn thành thành công
        return Future.value(true);
      }
      
      // Nếu task không được nhận diện, trả về false
      return Future.value(false);
    } catch (e) {
      // Log lỗi để debug
      print('Error in callbackDispatcher: $e');
      // Trả về false để báo hiệu task đã fail
      return Future.value(false);
    }
  });
}
