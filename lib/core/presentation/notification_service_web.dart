import 'dart:html' as html;

class NotificationService {
  static Future<void> init() async {
    // Web-specific initialization if needed
  }

  static Future<bool> requestPermission() async {
    try {
      final permission = await html.Notification.requestPermission();
      return permission == 'granted';
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasPermission() async {
    try {
      return html.Notification.permission == 'granted';
    } catch (_) {
      return false;
    }
  }

  static void showNotification(String title, String body) {
    try {
      if (html.Notification.permission == 'granted') {
        html.Notification(title, body: body);
      }
    } catch (_) {
      // Gracefully ignore web notification failures
    }
  }
}
