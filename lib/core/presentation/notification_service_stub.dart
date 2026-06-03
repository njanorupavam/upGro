class NotificationService {
  static Future<void> init() async {}
  static Future<bool> requestPermission() async => false;
  static Future<bool> hasPermission() async => false;
  static void showNotification(String title, String body) {}
}
