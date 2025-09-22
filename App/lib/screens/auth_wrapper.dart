import 'package:bluealert/providers/auth_provider.dart';
import 'package:bluealert/screens/auth/auth_screen.dart';
import 'package:bluealert/screens/home/home_screen.dart';
import 'package:bluealert/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to the AuthProvider for any changes
    final authProvider = Provider.of<AuthProvider>(context);

    // If the user is authenticated, show the main app screen
    if (authProvider.isAuthenticated) {
      return const HomeScreen();
    } else {
      // If not authenticated, we need to figure out if it's the initial app load
      // or if the user has logged out. The FutureBuilder handles the initial check.
      return FutureBuilder(
        // This future only runs once on startup
        future: authProvider.tryAutoLogin(),
        builder: (ctx, authResultSnapshot) {
          // While we are checking for a stored token, show the splash screen
          if (authResultSnapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          // After the check is complete, if the user is still not authenticated,
          // show the login/signup screen. This is also the screen shown after a logout.
          return const AuthScreen();
        },
      );
    }
  }
}