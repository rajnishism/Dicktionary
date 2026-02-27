/// Notification service — temporarily disabled due to Android SDK compatibility issue.
/// The flutter_local_notifications package has a bigLargeIcon ambiguity with Android API 31+.
/// Re-enable by adding back the dependency in pubspec.yaml and uncommenting this file.
///
/// Required pubspec.yaml entries (when re-enabling):
///   flutter_local_notifications: ^16.x.x (when fixed upstream)
///   workmanager: ^0.5.x
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {
    // Disabled — see comment above
  }

  Future<void> schedulePeriodicNotifications() async {
    // Disabled — see comment above
  }

  Future<void> cancelAllNotifications() async {
    // Disabled — see comment above
  }
}
