import 'dart:convert';
import 'dart:io';
import 'package:bluealert/services/api_service.dart';
import 'package:bluealert/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

// Define task names as constants to avoid typos
const syncTaskName = "syncReportsTask";
const uniqueSyncTaskName = "syncReportsUniqueTask";

class BackgroundService {
  /// This is the single entry point for the background task logic.
  /// It runs in a separate Isolate.
  static Future<bool> executeTask() async {
    final notificationService = NotificationService();
    await notificationService.initialize();
    final prefs = await SharedPreferences.getInstance();

    // --- Start the Foreground Service ---
    // This displays a persistent notification, making the task much more resilient.
    // This call must happen within the first few seconds of the task starting.
    await notificationService.flutterLocalNotificationsPlugin.show(
      1, // A fixed, unique ID for the foreground notification
      "Syncing Offline Reports",
      "Processing queued reports...",
      notificationService.foregroundNotificationDetails,
    );

    final token = prefs.getString('token');
    final userData = jsonDecode(prefs.getString('userData') ?? '{}');
    final userId = userData['_id'];

    if (token == null || userId == null) {
      // If there's an auth error, cancel the foreground notification and fail.
      await notificationService.flutterLocalNotificationsPlugin.cancel(1);
      return false;
    }

    List<String> queuedReports = prefs.getStringList('offline_reports') ?? [];
    if (queuedReports.isEmpty) {
      // If there's nothing to do, cancel the foreground notification and succeed.
      await notificationService.flutterLocalNotificationsPlugin.cancel(1);
      return true;
    }

    final String firstReportJson = queuedReports.first;
    final reportData = jsonDecode(firstReportJson);

    try {
      // Attempt to submit the first report in the queue
      await ApiService().submitReport(
        text: reportData['text'],
        lat: reportData['lat'],
        lon: reportData['lon'],
        token: token,
        userId: userId,
        mediaFile: reportData['mediaPath'] != null ? File(reportData['mediaPath']) : null,
      );

      // On success, show a success notification
      await notificationService.showReportSuccessNotification(reportData['text']);

      // Remove the successfully synced report from the queue
      queuedReports.removeAt(0);
      await prefs.setStringList('offline_reports', queuedReports);

      // If more reports are left, reschedule the task to continue the chain
      if (queuedReports.isNotEmpty) {
        Workmanager().registerOneOffTask(
          uniqueSyncTaskName,
          syncTaskName,
          existingWorkPolicy: ExistingWorkPolicy.replace,
          constraints: Constraints(networkType: NetworkType.connected),
        );
      } else {
        // If the queue is empty, cancel the persistent foreground notification
        await notificationService.flutterLocalNotificationsPlugin.cancel(1);
      }

      return true; // This single task was a success

    } catch (e) {
      // On failure, cancel the foreground notification and let WorkManager retry later.
      await notificationService.flutterLocalNotificationsPlugin.cancel(1);
      return false;
    }
  }
}