import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_service_stub.dart'
    if (dart.library.html) 'notification_service_web.dart';

// Re-export NotificationService so other files can use it directly
export 'notification_service_stub.dart'
    if (dart.library.html) 'notification_service_web.dart';

final notificationPermissionProvider =
    NotifierProvider<NotificationPermissionNotifier, bool>(NotificationPermissionNotifier.new);

class NotificationPermissionNotifier extends Notifier<bool> {
  @override
  bool build() {
    checkPermission();
    return false;
  }

  Future<void> checkPermission() async {
    state = await NotificationService.hasPermission();
  }

  Future<void> togglePermission() async {
    final granted = await NotificationService.requestPermission();
    state = granted;
    if (granted) {
      NotificationService.showNotification(
        'Notifications Enabled!',
        'You will now receive alerts for Focus sessions and Habit reminders.',
      );
    }
  }
}
