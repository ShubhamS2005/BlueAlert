import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// --- NEW: Notification for the Foreground Service ---
  /// This is a silent, persistent notification shown while syncing.
  NotificationDetails get foregroundNotificationDetails {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'report_sync_foreground_channel', // A different channel ID
      'Syncing Reports',
      channelDescription: 'Notification shown while syncing offline reports.',
      importance: Importance.low, // Low importance so it's not intrusive
      priority: Priority.low,
      ongoing: true, // Makes it persistent (non-dismissible)
      autoCancel: false,
    );
    return const NotificationDetails(android: androidPlatformChannelSpecifics);
  }

  /// --- Notification for a successful sync ---
  Future<void> showReportSuccessNotification(String reportText) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'report_sync_success_channel', // A different channel ID for success
      'Report Sync Success',
      channelDescription: 'Notifications for successfully synced offline reports',
      importance: Importance.defaultImportance, // Default importance is fine
      priority: Priority.defaultPriority,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    String notificationBody = reportText.length > 50
        ? '${reportText.substring(0, 50)}...'
        : reportText;

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond, // Unique ID
      'Report Submitted Successfully',
      '"$notificationBody" was submitted.',
      platformChannelSpecifics,
    );
  }
}