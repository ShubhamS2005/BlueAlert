import 'package:bluealert/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize services needed for the background task
  await Firebase.initializeApp();
  await NotificationService().initialize();

  print("Handling a message: ${message.messageId}");

  if (message.data['type'] == 'HAZARD_ALERT') {
    final lat = message.data['lat'];
    final lon = message.data['lon'];
    final title = message.notification?.title ?? 'Hazard Alert!';
    final body = message.notification?.body ?? 'A new hazard has been verified.';

    if (lat != null && lon != null) {
      // This is the only responsibility of the handler.
      // It triggers the notification that the OS will use to launch the full-screen intent.
      await NotificationService().showFullScreenHazardAlert(
        title: title,
        body: body,
        lat: lat,
        lon: lon,
      );
    }
  }
}