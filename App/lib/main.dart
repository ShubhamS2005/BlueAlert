import 'package:bluealert/constants/app_themes.dart';
import 'package:bluealert/providers/auth_provider.dart';
import 'package:bluealert/providers/theme_provider.dart';
import 'package:bluealert/screens/auth_wrapper.dart';
import 'package:bluealert/services/background_service.dart';
import 'package:bluealert/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

// This top-level function is the entry point for the background task.
// It must be defined outside of any class.
// It delegates all complex logic to our dedicated BackgroundService.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    return await BackgroundService.executeTask();
  });
}

void main() async {
  // Ensure that the Flutter binding is initialized before calling async methods
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the background task runner
  await Workmanager().initialize(
    callbackDispatcher,
    // This flag is useful for debugging background tasks
    isInDebugMode: true,
  );

  // Initialize the notification service for both the main app and background tasks
  await NotificationService().initialize();

  // Run the main Flutter application
  runApp(const MyApp());
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
            title: 'BlueAlert',
            debugShowCheckedModeBanner: false,
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeProvider.themeMode,
            // The AuthWrapper cleanly handles all navigation logic
            // (Splash -> Auth -> Home)
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}