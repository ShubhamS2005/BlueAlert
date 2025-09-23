import 'package:bluealert/constants/app_themes.dart';
import 'package:bluealert/providers/auth_provider.dart';
import 'package:bluealert/providers/theme_provider.dart';
import 'package:bluealert/screens/alert_screen.dart';
import 'package:bluealert/screens/permission_gate_screen.dart'; // <-- Correct starting point
import 'package:bluealert/services/background_service.dart';
import 'package:bluealert/services/fcm_background_handler.dart';
import 'package:bluealert/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// GlobalKey for navigation from background services.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    return await BackgroundService.executeTask();
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  await NotificationService().initialize();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    _handleMessage(message);
  });

  await _setupInteractedMessage();
  runApp(const MyApp());
}

Future<void> _setupInteractedMessage() async {
  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    _handleMessage(initialMessage);
  }
  FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
}

void _handleMessage(RemoteMessage message) {
  if (message.data['type'] == 'HAZARD_ALERT') {
    final lat = message.data['lat'];
    final lon = message.data['lon'];
    if (lat != null && lon != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => AlertScreen(lat: lat, lon: lon)),
      );
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'BlueAlert',
            debugShowCheckedModeBanner: false,
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeProvider.themeMode,
            // The app's journey now starts at the PermissionGateScreen.
            home: const PermissionGateScreen(),
          );
        },
      ),
    );
  }
}