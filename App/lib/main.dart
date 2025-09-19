import 'package:bluealert/constants/app_themes.dart';
import 'package:bluealert/providers/auth_provider.dart';
import 'package:bluealert/providers/theme_provider.dart';
import 'package:bluealert/screens/auth/auth_screen.dart';
import 'package:bluealert/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'package:workmanager/workmanager.dart';
// Import your ApiService and offline logic here if needed for background task

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // TODO: Add logic here to sync offline reports.
    // This involves initializing SharedPreferences, getting the queued reports,
    // and sending them via the ApiService.
    print("Native called background task: $task");
    return Future.value(true);
  });
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
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
            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (auth.isAuthenticated) {
                  return const HomeScreen();
                } else {
                  return FutureBuilder(
                    future: auth.tryAutoLogin(),
                    builder: (ctx, authResultSnapshot) {
                      if (authResultSnapshot.connectionState == ConnectionState.waiting) {
                        return const SplashScreen();
                      }
                      return const AuthScreen();
                    },
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}