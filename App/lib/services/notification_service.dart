import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Singleton pattern to ensure only one instance of the service exists
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // --- DEFINE CHANNEL CONSTANTS ---
  // Using constants is a best practice to avoid typos between creating and using channels.
  static const String hazardAlertChannelId = 'hazard_alert_channel';
  static const String foregroundSyncChannelId = 'report_sync_foreground_channel';
  static const String successSyncChannelId = 'report_sync_success_channel';

  /// Initializes the notification plugin and creates the necessary channels on Android.
  Future<void> initialize() async {
    // Setting for Android to specify the app's launcher icon for notifications.
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      // iOS settings can be added here if needed in the future
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // This step is crucial for Android 8.0+
    await _createNotificationChannels();
  }

  /// Creates all the notification channels required by the app.
  /// If a channel with the same ID already exists, it will be updated.
  Future<void> _createNotificationChannels() async {
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // Channel for High-Priority, Full-Screen Hazard Alerts
    const AndroidNotificationChannel hazardChannel = AndroidNotificationChannel(
      hazardAlertChannelId,
      'Hazard Alerts', // User-visible name in the app's notification settings
      description: 'Full-screen notifications for critical hazard alerts.',
      importance: Importance.max, // Highest importance
      playSound: true,
      enableVibration: true,
    );

    // Channel for the silent, persistent "Syncing..." notification
    const AndroidNotificationChannel foregroundChannel = AndroidNotificationChannel(
      foregroundSyncChannelId,
      'Syncing Reports', // User-visible name
      description: 'Notification shown while syncing offline reports.',
      importance: Importance.low, // Low importance so it is not intrusive
      playSound: false,
      enableVibration: false,
    );

    // Channel for the standard "Report Submitted" notification
    const AndroidNotificationChannel successChannel = AndroidNotificationChannel(
      successSyncChannelId,
      'Report Sync Success', // User-visible name
      description: 'Notifications for successfully synced offline reports.',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    // Register all channels with the Android system
    await androidImplementation?.createNotificationChannel(hazardChannel);
    await androidImplementation?.createNotificationChannel(foregroundChannel);
    await androidImplementation?.createNotificationChannel(successChannel);
  }

  /// Returns the NotificationDetails for the persistent foreground service notification.
  NotificationDetails get foregroundNotificationDetails {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        foregroundSyncChannelId, // Use the constant channel ID
        'Syncing Reports',
        channelDescription: 'Notification shown while syncing offline reports.',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true, // Makes it non-dismissible by the user
        autoCancel: false,
      ),
    );
  }

  /// Shows a standard notification when an offline report is successfully synced.
  Future<void> showReportSuccessNotification(String reportText) async {
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        successSyncChannelId, // Use the constant channel ID
        'Report Sync Success',
        channelDescription: 'Notifications for successfully synced offline reports.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );

    // Truncate the report text for the notification body to keep it concise
    String notificationBody = reportText.length > 50
        ? '${reportText.substring(0, 50)}...'
        : reportText;

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond, // Use a unique ID to show multiple success notifications
      'Report Submitted Successfully',
      '"$notificationBody" was submitted.',
      platformChannelSpecifics,
    );
  }

  /// Shows the high-priority, full-screen notification for a critical hazard alert.
  Future<void> showFullScreenHazardAlert({
    required String title,
    required String body,
    required String lat,
    required String lon,
  }) async {
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        hazardAlertChannelId, // Use the constant channel ID for high-priority alerts
        'Hazard Alerts',
        channelDescription: 'Full-screen notifications for critical hazard alerts.',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true, // This is the key property to trigger the full-screen UI
        playSound: true,
        enableVibration: true,
      ),
    );

    final String payload = '{"lat": "$lat", "lon": "$lon"}';

    await flutterLocalNotificationsPlugin.show(
      2, // A fixed, unique ID for this type of notification
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}